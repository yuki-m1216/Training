#!/usr/bin/env python3
"""Cognito hosted UI から PKCE(認可コードグラント)でトークンを取る「教育モード」スクリプト(GenU の代替)。

ログインの旅を隠さず、各ステップを逐一表示する:
  [1/6] 設定の読み込み(out/identity-outputs.json の ClientId / HostedUiBaseUrl)
  [2/6] PKCE の準備(code_verifier → code_challenge = BASE64URL(SHA256(verifier)))と state
  [3/6] 認可リクエスト URL の組み立てと表示(→ あなたがブラウザで開く。DevTools の Network を Preserve log で)
  [4/6] http://localhost:8400/callback で認可コードを受け取る(state を照合)
  [5/6] トークンエンドポイントへ code + code_verifier を POST(生リクエスト/生レスポンスを表示)
  [6/6] out/tokens_<user>.json に保存し、ID トークン / アクセストークンのクレームをデコード表示

見えない区間(Cognito ↔ Entra の SAMLRequest / SAMLResponse)はブラウザ DevTools で捕まえて decode_saml.py へ(ランブック §8)。

使い方:
  python3 scripts/get_token.py --user userA --idp EntraID      # Entra 経由(hosted UI を飛ばして直接 Entra へ。SAML)
  python3 scripts/get_token.py --user userA --idp EntraOIDC    # 同、OIDC(V1')
  python3 scripts/get_token.py --user userA                    # hosted UI の選択画面(EntraID ボタン / ローカルのユーザー名+パスワード)
  python3 scripts/get_token.py --user local-a                  # ローカルユーザー(切り分けレイヤ)
  python3 scripts/get_token.py --user userA --idp EntraID --manual   # callback を受けられない環境: リダイレクト先 URL を貼り付け

標準ライブラリのみ。トークンはチャット/ログに貼るとき decode_jwt.py --mask を使うこと(§6)。
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import http.server
import json
import os
import secrets
import sys
import threading
import urllib.error
import urllib.parse
import urllib.request
from typing import Any

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import decode_jwt  # noqa: E402  (同じ scripts/ にある観測用の道具)

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(HERE, ".."))
DEFAULT_OUTPUTS = os.path.join(PROJECT_ROOT, "out", "identity-outputs.json")
OUT_DIR = os.path.join(PROJECT_ROOT, "out")


def banner(step: str, title: str) -> None:
    print()
    print("=" * 78)
    print(f"[{step}] {title}")
    print("=" * 78)


def b64url_nopad(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def load_config(outputs_path: str, stack_name: str) -> dict[str, str]:
    with open(outputs_path, encoding="utf-8") as f:
        outputs = json.load(f)
    stack = outputs.get(stack_name) or next(iter(outputs.values()))
    return {
        "client_id": stack["ClientId"],
        "base_url": stack["HostedUiBaseUrl"].rstrip("/"),
        "user_pool_id": stack["UserPoolId"],
    }


class CallbackHandler(http.server.BaseHTTPRequestHandler):
    """/callback に戻ってきた認可コード(または error)を 1 回だけ受け取る"""

    received: dict[str, list[str]] | None = None

    def do_GET(self) -> None:  # noqa: N802
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path != "/callback":
            self.send_response(404)
            self.end_headers()
            return
        CallbackHandler.received = urllib.parse.parse_qs(parsed.query, keep_blank_values=True)
        body = (
            "<html><body style='font-family:sans-serif'><h2>get_token.py: callback を受け取りました</h2>"
            "<p>ターミナルに戻ってください。このタブは閉じて構いません。</p></body></html>"
        ).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt: str, *args: Any) -> None:  # 標準のアクセスログは抑制(表示は自前で)
        return


def wait_for_callback(port: int) -> dict[str, list[str]]:
    server = http.server.HTTPServer(("127.0.0.1", port), CallbackHandler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    print(f"  http://localhost:{port}/callback で待機中... (ブラウザでログインを完了してください。Ctrl+C で中断)")
    try:
        while CallbackHandler.received is None:
            thread.join(0.2)
    finally:
        server.shutdown()
    return CallbackHandler.received or {}


def parse_pasted_callback(text: str) -> dict[str, list[str]]:
    text = text.strip()
    query = urllib.parse.urlparse(text).query if "://" in text else text.lstrip("?")
    return urllib.parse.parse_qs(query, keep_blank_values=True)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Cognito hosted UI から PKCE でトークンを取得する(教育モード)")
    parser.add_argument("--user", required=True, help="保存ファイル名に使うラベル(例: userA / userB / local-a)")
    parser.add_argument("--idp", help="identity_provider パラメータ(例: EntraID / EntraOIDC)。指定すると hosted UI の選択画面を飛ばして IdP へ直行")
    parser.add_argument("--outputs", default=DEFAULT_OUTPUTS, help="cdk deploy --outputs-file の JSON")
    parser.add_argument("--stack", default="AuthChainIdentityStack")
    parser.add_argument("--port", type=int, default=8400)
    parser.add_argument("--scope", default="openid profile email")
    parser.add_argument("--manual", action="store_true", help="ローカル待受をせず、リダイレクト先 URL を貼り付けて続行する")
    parser.add_argument("--mask", action="store_true", help="表示するクレームをマスク(保存ファイルはマスクしない)")
    args = parser.parse_args(argv)

    # ------------------------------------------------------------ [1/6]
    banner("1/6", "設定の読み込み")
    cfg = load_config(args.outputs, args.stack)
    redirect_uri = f"http://localhost:{args.port}/callback"
    print(f"  UserPoolId   : {cfg['user_pool_id']}")
    print(f"  ClientId     : {cfg['client_id']}   (公開クライアント。シークレット無し → PKCE で守る)")
    print(f"  Hosted UI    : {cfg['base_url']}")
    print(f"  redirect_uri : {redirect_uri}   (アプリクライアントの callbackUrls と完全一致が必要)")
    print(f"  scope        : {args.scope}")

    # ------------------------------------------------------------ [2/6]
    banner("2/6", "PKCE の準備")
    code_verifier = b64url_nopad(secrets.token_bytes(48))  # 64 文字の高エントロピー文字列(RFC 7636: 43〜128 文字)
    code_challenge = b64url_nopad(hashlib.sha256(code_verifier.encode("ascii")).digest())
    state = secrets.token_urlsafe(16)
    print(f"  code_verifier  (秘密。ブラウザには渡さない。あとでトークン交換で提示) : {code_verifier}")
    print(f"  code_challenge = BASE64URL(SHA256(code_verifier))                   : {code_challenge}")
    print(f"  state (CSRF 対策。callback で照合)                                    : {state}")
    print("  → 認可コードを盗まれても code_verifier が無ければトークンに交換できない、が PKCE の要点")

    # ------------------------------------------------------------ [3/6]
    banner("3/6", "認可リクエスト URL(ここからブラウザの旅が始まる)")
    params = {
        "response_type": "code",
        "client_id": cfg["client_id"],
        "redirect_uri": redirect_uri,
        "scope": args.scope,
        "state": state,
        "code_challenge_method": "S256",
        "code_challenge": code_challenge,
    }
    if args.idp:
        params["identity_provider"] = args.idp
    authorize_url = f"{cfg['base_url']}/oauth2/authorize?" + urllib.parse.urlencode(params)
    print("  パラメータ:")
    for k, v in params.items():
        print(f"    {k:22s} = {v}")
    print()
    print("  ▼ このURLをブラウザで開いてください(DevTools > Network > Preserve log を ON にしてから)")
    print(f"  {authorize_url}")
    print()
    print("  観測ポイント(DevTools):")
    if args.idp and "oidc" in args.idp.lower():
        # OIDC(V1'): Cognito は RP。Entra へは認可コードフローで、code 交換は Cognito↔Entra のバックチャネル(ブラウザには見えない)
        print("    - /oauth2/authorize → 302 → login.microsoftonline.com/<tenant>/oauth2/v2.0/authorize?client_id=...&redirect_uri=<hosted-ui>/oauth2/idpresponse&scope=openid profile email  (Cognito→Entra)")
        print("    - Entra ログイン後 → 302 → <hosted-ui>/oauth2/idpresponse?code=...&state=...   (Entra→Cognito。Entra の認可コード)")
        print("    - (見えない) Cognito が Entra の /oauth2/v2.0/token へ code + client_secret を POST → ID トークン → 属性マッピング")
        print("      ※ SAML と違い Entra の ID トークンは DevTools に出ない。切り分けは admin-get-user → ランブック v2.0 §8(jwt.ms)")
    else:
        print("    - /oauth2/authorize → 302 → login.microsoftonline.com/<tenant>/saml2?SAMLRequest=...  (Cognito→Entra, Redirect binding)")
        print("    - Entra ログイン後 → POST <hosted-ui>/saml2/idpresponse (Form Data: SAMLResponse)      (Entra→Cognito, POST binding)")
    print("    - → 302 → http://localhost:8400/callback?code=...&state=...   (Cognito の認可コード)")
    if not args.idp:
        print("    - identity_provider 未指定なので、hosted UI にローカル(ユーザー名+パスワード)と EntraID ボタンの両方が出るはず")

    # ------------------------------------------------------------ [4/6]
    banner("4/6", "認可コードの受け取り(callback)")
    if args.manual:
        pasted = input("  ブラウザのアドレスバーに出た http://localhost:8400/callback?... を丸ごと貼り付けて Enter: ")
        received = parse_pasted_callback(pasted)
    else:
        received = wait_for_callback(args.port)
    print("  callback のクエリ:")
    for k, v in received.items():
        shown = v[0]
        if k == "code":
            shown = shown[:12] + "…" + f"  ({len(v[0])} 文字。ワンタイム・短命)"
        print(f"    {k:18s} = {shown}")
    if "error" in received:
        print("\n  ✗ 認可エラー。error_description を確認してください(Cognito 側の失敗はここに出る。例: Invalid SAML response received)")
        return 1
    if received.get("state", [None])[0] != state:
        print("\n  ✗ state が一致しません(別のログインの callback を受けた可能性)。中断します")
        return 1
    code = received["code"][0]

    # ------------------------------------------------------------ [5/6]
    banner("5/6", "トークン交換(認可コード + code_verifier → トークン)")
    token_url = f"{cfg['base_url']}/oauth2/token"
    form = {
        "grant_type": "authorization_code",
        "client_id": cfg["client_id"],
        "code": code,
        "redirect_uri": redirect_uri,
        "code_verifier": code_verifier,
    }
    body = urllib.parse.urlencode(form).encode("ascii")
    print(f"  POST {token_url}")
    print("  Content-Type: application/x-www-form-urlencoded")
    print("  body:")
    for k, v in form.items():
        print(f"    {k:14s} = {v if k != 'code' else v[:12] + '…'}")
    print("  (公開クライアントなので Authorization: Basic は付けない。code_verifier が「本人が始めた認可要求」の証明)")
    req = urllib.request.Request(token_url, data=body, method="POST", headers={"Content-Type": "application/x-www-form-urlencoded"})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            status = resp.status
            payload = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        print(f"\n  ✗ HTTP {e.code}: {e.read().decode('utf-8', 'replace')}")
        return 1
    print(f"\n  レスポンス: HTTP {status}")
    for k, v in payload.items():
        shown = v if not isinstance(v, str) or len(v) < 60 else v[:24] + f"…({len(v)} 文字)"
        print(f"    {k:14s} = {shown}")
    print("  → id_token / access_token は JWT(3 セグメント)。refresh_token は不透明文字列(JWT ではない)")

    # ------------------------------------------------------------ [6/6]
    banner("6/6", "保存とデコード")
    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.join(OUT_DIR, f"tokens_{args.user}.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
    os.chmod(out_path, 0o600)
    print(f"  保存: {out_path}  (out/ は gitignore。ログに貼るときは decode_jwt.py --mask)")
    for label in ("id_token", "access_token"):
        token = payload.get(label)
        if not token:
            continue
        decoded = decode_jwt.decode_jwt(token)
        claims = decode_jwt.mask_claims(decoded["payload"]) if args.mask else decoded["payload"]
        print(f"\n  ---- {label} のクレーム ----")
        print("  " + json.dumps(claims, ensure_ascii=False, indent=2).replace("\n", "\n  "))
    print("\n  観測ポイント: ID トークンには custom:company_raw が居るか / アクセストークンには居ないか / company_code は(V1c 前なので)どちらにも無いはず")
    return 0


if __name__ == "__main__":
    sys.exit(main())
