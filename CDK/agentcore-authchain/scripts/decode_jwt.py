#!/usr/bin/env python3
"""JWT(ID トークン / アクセストークン)のヘッダとペイロードを「見るため」に整形表示する。

署名は検証しない(検証は Runtime / Gateway の仕事。ここでは中身を観測するだけ)。
標準ライブラリのみ。

使い方:
  python3 scripts/decode_jwt.py <JWT文字列>
  python3 scripts/decode_jwt.py out/tokens_userA.json          # access_token / id_token を全部デコード
  cat token.txt | python3 scripts/decode_jwt.py -               # stdin
  python3 scripts/decode_jwt.py <JWT> --mask                    # sub / email 等をマスク(検証ログ貼付用, §6)
  python3 scripts/decode_jwt.py <JWT> --raw                     # 装飾なしで {header, payload} の JSON だけ
"""
from __future__ import annotations

import argparse
import base64
import binascii
import copy
import json
import sys
import time
from datetime import datetime, timedelta, timezone
from typing import Any

JST = timezone(timedelta(hours=9))

# エポック秒で入っている時刻クレーム(RFC 7519 + OIDC の auth_time)
TIME_CLAIMS = ("iat", "exp", "nbf", "auth_time")

# §6: 検証ログに載せる前にマスクするクレーム(先頭数文字だけ残す)
SENSITIVE_CLAIMS = (
    "sub",
    "email",
    "username",
    "cognito:username",
    "preferred_username",
    "name",
    "given_name",
    "family_name",
    "phone_number",
    "jti",
    "origin_jti",
    "event_id",
)


def b64url_decode(segment: str) -> bytes:
    """パディング無しの base64url をデコードする(JWT の各セグメントはパディングを落とした形)。"""
    segment = segment.strip()
    padding = (-len(segment)) % 4
    if padding == 3:
        # 長さ mod 4 == 1 は base64 として成立しない
        raise ValueError("base64url のセグメント長が不正です")
    try:
        return base64.urlsafe_b64decode(segment + "=" * padding)
    except (binascii.Error, ValueError) as e:
        raise ValueError(f"base64url のデコードに失敗しました: {e}") from e


def _decode_json_segment(segment: str, label: str) -> dict[str, Any]:
    try:
        obj = json.loads(b64url_decode(segment).decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as e:
        raise ValueError(f"{label} が JSON として読めません: {e}") from e
    if not isinstance(obj, dict):
        raise ValueError(f"{label} が JSON オブジェクトではありません")
    return obj


def decode_jwt(token: str) -> dict[str, Any]:
    """JWT をヘッダ / ペイロード / 署名(base64url のまま)に分解する。署名は検証しない。

    戻り値: {"header": dict, "payload": dict, "signature_b64url": str, "signature_bytes": int}
    """
    token = token.strip()
    if token.lower().startswith("bearer "):
        token = token[7:].strip()
    parts = token.split(".")
    if len(parts) != 3:
        raise ValueError(f"JWT は '.' 区切りの 3 セグメントのはずですが {len(parts)} セグメントでした")
    header = _decode_json_segment(parts[0], "ヘッダ")
    payload = _decode_json_segment(parts[1], "ペイロード")
    signature = b64url_decode(parts[2])
    return {
        "header": header,
        "payload": payload,
        "signature_b64url": parts[2],
        "signature_bytes": len(signature),
    }


def describe_times(payload: dict[str, Any], now: int | None = None) -> dict[str, Any]:
    """iat / exp / nbf / auth_time を ISO 8601(UTC・JST)に直し、exp までの残り秒数を付ける。"""
    if now is None:
        now = int(time.time())
    info: dict[str, Any] = {}
    for claim in TIME_CLAIMS:
        value = payload.get(claim)
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            continue
        dt_utc = datetime.fromtimestamp(value, timezone.utc)
        info[claim] = {
            "epoch": value,
            "utc": dt_utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "jst": dt_utc.astimezone(JST).isoformat(),
        }
    if "exp" in info:
        info["expires_in_seconds"] = int(info["exp"]["epoch"] - now)
    return info


def _mask_value(value: str, keep: int = 4) -> str:
    if len(value) <= keep:
        return "*" * len(value)
    return value[:keep] + "…" + "*" * min(len(value) - keep, 8)


def mask_claims(payload: dict[str, Any]) -> dict[str, Any]:
    """§6 用: 個人・テナントを特定し得るクレームを先頭数文字だけ残してマスクした「コピー」を返す。

    観測対象(token_use / scope / client_id / custom:* / 注入クレーム等)は触らない。
    """
    masked = copy.deepcopy(payload)
    for claim in SENSITIVE_CLAIMS:
        value = masked.get(claim)
        if isinstance(value, str) and value:
            masked[claim] = _mask_value(value)
    return masked


def _looks_like_jwt(value: Any) -> bool:
    if not isinstance(value, str) or value.count(".") != 2:
        return False
    try:
        decode_jwt(value)
        return True
    except ValueError:
        return False


def extract_tokens_from_json(obj: Any, prefix: str = "") -> dict[str, str]:
    """JSON(dict)を再帰的に走査し、JWT の形をした文字列値だけを {"パス": トークン} で返す。

    Cognito の refresh_token は JWT ではない(不透明文字列)ので自然に除外される。
    """
    found: dict[str, str] = {}
    if isinstance(obj, dict):
        for key, value in obj.items():
            path = f"{prefix}.{key}" if prefix else str(key)
            if isinstance(value, dict):
                found.update(extract_tokens_from_json(value, path))
            elif _looks_like_jwt(value):
                found[path] = value
    return found


# ---------------------------------------------------------------- CLI

def _read_source(source: str) -> str:
    if source == "-":
        return sys.stdin.read()
    try:
        with open(source, encoding="utf-8") as f:
            return f.read()
    except (FileNotFoundError, OSError):
        return source  # ファイルでなければトークン文字列そのものとみなす


def _print_token(label: str, token: str, mask: bool, raw: bool) -> None:
    decoded = decode_jwt(token)
    payload = mask_claims(decoded["payload"]) if mask else decoded["payload"]
    if raw:
        print(json.dumps({"header": decoded["header"], "payload": payload}, ensure_ascii=False, indent=2))
        return
    print(f"===== {label} =====")
    print("[header]")
    print(json.dumps(decoded["header"], ensure_ascii=False, indent=2))
    print("[payload]" + ("  (masked)" if mask else ""))
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    times = describe_times(decoded["payload"])
    if times:
        print("[times]")
        for claim in TIME_CLAIMS:
            if claim in times:
                t = times[claim]
                print(f"  {claim:9s} {t['epoch']}  UTC {t['utc']}  JST {t['jst']}")
        if "expires_in_seconds" in times:
            remain = times["expires_in_seconds"]
            state = "有効" if remain > 0 else "期限切れ"
            print(f"  exp まで   {remain} 秒 ({state})")
    print(f"[signature] base64url {len(decoded['signature_b64url'])} 文字 / {decoded['signature_bytes']} bytes  ※署名は検証していません")
    print()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="JWT のヘッダ・ペイロードを整形表示する(署名は検証しない)")
    parser.add_argument("source", help="JWT 文字列 / トークンを含む JSON ファイル / '-'(stdin)")
    parser.add_argument("--mask", action="store_true", help="sub・email 等をマスクして表示(検証ログ貼付用)")
    parser.add_argument("--raw", action="store_true", help="装飾なしで {header, payload} の JSON のみ出力")
    args = parser.parse_args(argv)

    text = _read_source(args.source).strip()
    if not text:
        print("入力が空です", file=sys.stderr)
        return 2

    tokens: dict[str, str]
    try:
        obj = json.loads(text)
        tokens = extract_tokens_from_json(obj) if isinstance(obj, dict) else {}
        if not tokens:
            print("JSON 内に JWT の形をした値が見つかりません", file=sys.stderr)
            return 2
    except json.JSONDecodeError:
        tokens = {"token": text}

    for label, token in tokens.items():
        try:
            _print_token(label, token, mask=args.mask, raw=args.raw)
        except ValueError as e:
            print(f"{label}: デコード失敗: {e}", file=sys.stderr)
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
