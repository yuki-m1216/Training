#!/usr/bin/env python3
"""AgentCore Runtime を JWT(Cognito のアクセストークン)で直接呼び出す(教育モード)。

  [1/4] 設定の読み込み(Runtime ARN / トークンファイル)
  [2/4] 送るトークンの中身(署名検証なしでデコード。Runtime が何を見て通す/落とすかを予習する)
  [3/4] HTTPS リクエストの組み立て(URL エンコードした ARN、Authorization: Bearer、Session-Id は 33 文字以上)
  [4/4] 応答(ステータス、WWW-Authenticate、本文)

JWT 設定の Runtime は AWS SDK の invoke_agent_runtime では呼べない(SigV4 と JWT は排他)ため HTTPS を直接叩く。
参照(公式): https://docs.aws.amazon.com/bedrock-agentcore/latest/APIReference/API_InvokeAgentRuntime.html
            https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-oauth.html

例:
  python3 scripts/invoke_runtime.py --token-file out/tokens_userA_v2.json                 # inspect(既定)
  python3 scripts/invoke_runtime.py --token-file out/tokens_userA_v2.json --use id        # ID トークンを送ってみる(client_id/aud の違い)
  python3 scripts/invoke_runtime.py --token-file out/tokens_userA_v2.json --tamper        # 署名を 1 文字壊す(改ざん実験)
  python3 scripts/invoke_runtime.py --token-file out/tokens_userA_v2.json --action gateway --tool VerifyTarget___echo_profile --args '{"note":"hi"}'
"""
from __future__ import annotations

import argparse
import base64
import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from typing import Any

REGION = "ap-northeast-1"


def banner(step: str, title: str) -> None:
    print()
    print(f"[{step}] {title}")
    print("-" * 72)


def b64url_decode(part: str) -> bytes:
    return base64.urlsafe_b64decode(part + "=" * (-len(part) % 4))


def decode_jwt_noverify(token: str) -> tuple[dict[str, Any], dict[str, Any]]:
    h, p, _s = token.split(".")
    return json.loads(b64url_decode(h)), json.loads(b64url_decode(p))


def tamper(token: str) -> str:
    """署名部の末尾 1 文字を別の文字に置き換える(ヘッダ・ペイロードはそのまま = 中身は正しく見えるが署名不一致)。"""
    h, p, s = token.split(".")
    last = "A" if s[-1] != "A" else "B"
    return f"{h}.{p}.{s[:-1]}{last}"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="AgentCore Runtime を JWT で呼び出す(教育モード)")
    parser.add_argument("--token-file", required=True, help="get_token.py が保存したトークン JSON(out/ 配下)")
    parser.add_argument("--use", choices=["access", "id"], default="access", help="送るトークン種別(既定 access)")
    parser.add_argument("--outputs", default="out/runtime-outputs.json", help="cdk deploy --outputs-file の出力")
    parser.add_argument("--stack", default="AuthChainRuntimeStack")
    parser.add_argument("--runtime-arn", help="outputs を使わず ARN を直接指定")
    parser.add_argument("--action", choices=["inspect", "gateway"], default="inspect")
    parser.add_argument("--tool", help="action=gateway のとき tools/call するツール名(例 VerifyTarget___echo_profile)")
    parser.add_argument("--args", default="{}", help="tools/call の arguments(JSON)")
    parser.add_argument("--tamper", action="store_true", help="署名を壊して送る(改ざん実験)")
    parser.add_argument("--session-id", help="X-Amzn-Bedrock-AgentCore-Runtime-Session-Id(既定: 自動生成 64 文字)")
    parser.add_argument("--save", help="応答 JSON の保存先(例 out/runtime_v2b_userA.json)")
    args = parser.parse_args(argv)

    # ------------------------------------------------------------ [1/4]
    banner("1/4", "設定の読み込み")
    if args.runtime_arn:
        runtime_arn = args.runtime_arn
    else:
        with open(args.outputs, encoding="utf-8") as f:
            outputs = json.load(f)
        runtime_arn = outputs[args.stack]["RuntimeArn"]
    with open(args.token_file, encoding="utf-8") as f:
        tokens = json.load(f)
    token = tokens["access_token"] if args.use == "access" else tokens["id_token"]
    print(f"  Runtime ARN : {runtime_arn}")
    print(f"  トークン     : {args.use}_token from {args.token_file}")

    # ------------------------------------------------------------ [2/4]
    banner("2/4", "送るトークンの中身(署名検証なし。Runtime のオーソライザが見る項目を予習)")
    header, claims = decode_jwt_noverify(token)
    now = int(time.time())
    print(f"  alg/kid      : {header.get('alg')} / {header.get('kid')}")
    print(f"  iss          : {claims.get('iss')}   ← discoveryUrl(Cognito のプール)と一致すること")
    print(f"  token_use    : {claims.get('token_use')}")
    print(f"  client_id    : {claims.get('client_id')}   ← allowedClients と照合(アクセストークン)")
    print(f"  aud          : {claims.get('aud')}   ← allowedAudience と照合(ID トークンにのみ存在)")
    print(f"  scope        : {claims.get('scope')}")
    print(f"  company_code : {claims.get('company_code')} / department_code: {claims.get('department_code')}")
    print(f"  agents       : {claims.get('agents')}   ← customClaims(agents CONTAINS <AGENT_KEY>)と照合")
    print(f"  exp          : {claims.get('exp')} (あと {claims.get('exp', 0) - now} 秒)")
    if args.tamper:
        token = tamper(token)
        print("  ※ --tamper: 署名部の末尾 1 文字を書き換えた(中身は上のまま、署名だけ不一致)")

    # ------------------------------------------------------------ [3/4]
    banner("3/4", "HTTPS リクエストの組み立て")
    session_id = args.session_id or (uuid.uuid4().hex + uuid.uuid4().hex)  # 64 文字(下限 33)
    url = (
        f"https://bedrock-agentcore.{REGION}.amazonaws.com/runtimes/"
        f"{urllib.parse.quote(runtime_arn, safe='')}/invocations?qualifier=DEFAULT"
    )
    payload: dict[str, Any] = {"action": args.action}
    if args.action == "gateway":
        payload["tool"] = args.tool
        payload["arguments"] = json.loads(args.args)
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "X-Amzn-Bedrock-AgentCore-Runtime-Session-Id": session_id,
    }
    print(f"  POST {url}")
    for k, v in headers.items():
        shown = v if k != "Authorization" else f"Bearer {token[:12]}…{token[-6:]}"
        print(f"  {k}: {shown}")
    print(f"  body: {body.decode('utf-8')}")

    # ------------------------------------------------------------ [4/4]
    banner("4/4", "応答")
    req = urllib.request.Request(url, data=body, method="POST", headers=headers)
    started = time.time()
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            status = resp.status
            resp_headers = dict(resp.headers.items())
            raw = resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as exc:
        status = exc.code
        resp_headers = dict(exc.headers.items())
        raw = exc.read().decode("utf-8", errors="replace")
    elapsed = time.time() - started
    print(f"  HTTP {status}  ({elapsed:.1f}s)")
    for k in ("WWW-Authenticate", "x-amzn-ErrorType", "x-amzn-RequestId", "Content-Type"):
        for hk, hv in resp_headers.items():
            if hk.lower() == k.lower():
                print(f"  {hk}: {hv}")
    try:
        parsed = json.loads(raw)
        print(json.dumps(parsed, ensure_ascii=False, indent=2))
    except json.JSONDecodeError:
        parsed = {"raw": raw}
        print(f"  {raw[:2000]}")
    if args.save:
        with open(args.save, "w", encoding="utf-8") as f:
            json.dump({"status": status, "headers": resp_headers, "body": parsed, "request": payload}, f, ensure_ascii=False, indent=2)
        print(f"  → 保存: {args.save}")
    return 0 if 200 <= status < 300 else 1


if __name__ == "__main__":
    sys.exit(main())
