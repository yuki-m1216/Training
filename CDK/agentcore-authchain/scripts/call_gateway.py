#!/usr/bin/env python3
"""AgentCore Gateway(MCP)を JWT で直接呼び出す(教育モード。V3-3 の使い捨てスクリプトを V4 で昇格)。

  [1/4] 設定の読み込み(Gateway URL / トークンファイル)
  [2/4] 送るトークンの中身(Cedar の principal = OAuthUser::<sub>、tag になるクレーム)
  [3/4] JSON-RPC リクエストの組み立て(W3C traceparent を sampled で付与)
  [4/4] 応答(ステータス、WWW-Authenticate、JSON-RPC 本文、tools/call の isError)

Runtime を経由しない理由: OTHERCO のように agents クレームを持たないトークンは Runtime 入口で 401 になり Gateway に届かない。
Gateway の JWT 検証と Policy(Cedar)の判定だけを観測するには直接呼ぶ必要がある(検証ログ V3-3、V4)。
Gateway は MCP セッションを要求しない(V3 実測: initialize 無しの tools/list 単発でも 200)ので、1 回の POST で完結させる。
traceparent を付けるのは、Gateway のスパン(aws/spans。Policy の判定属性を含む)が sampled の W3C 文脈付きの呼び出しにだけ出るため(V3-4)。
参照(公式): https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/use-gateway-with-policy.html
            https://www.w3.org/TR/trace-context/

例:
  python3 scripts/call_gateway.py --token-file out/tokens_userA-oidc_v4.json --method tools/list
  python3 scripts/call_gateway.py --token-file out/tokens_userA-oidc_v4.json --tool VerifyTarget___echo_profile --args '{"note":"hi"}'
  python3 scripts/call_gateway.py --token-file out/tokens_local-c.json --args '{"note":"please delete"}'   # P2(forbid)
  python3 scripts/call_gateway.py --token-file out/tokens_userA-oidc_v4.json --tamper --method initialize  # 署名不正 → 403
  python3 scripts/call_gateway.py --no-auth --method initialize                                            # Bearer 無し → 401
"""
from __future__ import annotations

import argparse
import base64
import json
import secrets
import sys
import time
import urllib.error
import urllib.request
from typing import Any

# Gateway の supportedVersions のうち新しい方(gateway-stack.ts)。initialize 以外ではヘッダでも示す(MCP 2025-06-18 の作法)
MCP_PROTOCOL_VERSION = "2025-06-18"
DEFAULT_TOOL = "VerifyTarget___echo_profile"


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
    """署名バイト列の先頭 1 ビットを反転する(末尾 1 文字の書き換えは base64 の可鍛性で改ざんにならない。invoke_runtime.py と同じ)。"""
    h, p, s = token.split(".")
    sig = bytearray(b64url_decode(s))
    sig[0] ^= 0x80
    return f"{h}.{p}.{base64.urlsafe_b64encode(bytes(sig)).rstrip(b'=').decode('ascii')}"


def parse_body(raw: str, content_type: str) -> Any:
    """application/json はそのまま、text/event-stream は data: 行の JSON を取り出す(応答は 1 件の想定)。"""
    if "text/event-stream" in content_type:
        events = [json.loads(line[5:].strip()) for line in raw.splitlines() if line.startswith("data:") and line[5:].strip()]
        return events[0] if len(events) == 1 else events
    return json.loads(raw)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="AgentCore Gateway を JWT で直接呼び出す(教育モード)")
    auth = parser.add_mutually_exclusive_group(required=True)
    auth.add_argument("--token-file", help="get_token.py が保存したトークン JSON(out/ 配下)")
    auth.add_argument("--raw-token", help="Bearer にそのまま入れる文字列(例 not-a-jwt。壊す実験用)")
    auth.add_argument("--no-auth", action="store_true", help="Authorization ヘッダを付けない(壊す実験用)")
    parser.add_argument("--use", choices=["access", "id"], default="access", help="--token-file から送るトークン種別(既定 access)")
    parser.add_argument("--tamper", action="store_true", help="署名バイトを 1 ビット反転して送る(改ざん実験)")
    parser.add_argument("--outputs", default="out/gateway-outputs.json", help="cdk deploy --outputs-file の出力")
    parser.add_argument("--stack", default="AuthChainGatewayStack")
    parser.add_argument("--gateway-url", help="outputs を使わず URL を直接指定")
    parser.add_argument("--method", choices=["initialize", "tools/list", "tools/call"], default="tools/call")
    parser.add_argument("--tool", default=DEFAULT_TOOL, help=f"tools/call のツール名(既定 {DEFAULT_TOOL})")
    parser.add_argument("--args", default="{}", help="tools/call の arguments(JSON)")
    parser.add_argument("--no-traceparent", action="store_true", help="traceparent を付けない(スパンが出ないことの対照)")
    parser.add_argument("--save", help="応答 JSON の保存先(例 out/gateway_v4a_userA.json)")
    args = parser.parse_args(argv)

    # ------------------------------------------------------------ [1/4]
    banner("1/4", "設定の読み込み")
    if args.gateway_url:
        gateway_url = args.gateway_url
    else:
        with open(args.outputs, encoding="utf-8") as f:
            gateway_url = json.load(f)[args.stack]["GatewayUrl"]
    token: str | None = None
    if args.token_file:
        with open(args.token_file, encoding="utf-8") as f:
            tokens = json.load(f)
        token = tokens["access_token"] if args.use == "access" else tokens["id_token"]
        source = f"{args.use}_token from {args.token_file}"
    elif args.raw_token:
        token = args.raw_token
        source = "--raw-token(JWT として読めない文字列の想定)"
    else:
        source = "なし(--no-auth)"
    print(f"  Gateway URL : {gateway_url}")
    print(f"  トークン     : {source}")

    # ------------------------------------------------------------ [2/4]
    banner("2/4", "送るトークンの中身(署名検証なし。Cedar から見える principal と tag を予習)")
    if args.token_file and token:
        header, claims = decode_jwt_noverify(token)
        now = int(time.time())
        print(f"  alg/kid         : {header.get('alg')} / {header.get('kid')}")
        print(f"  token_use       : {claims.get('token_use')}   client_id: {claims.get('client_id')}   ← allowedClients と照合")
        print(f"  sub             : {claims.get('sub')}   ← Cedar の principal = AgentCore::OAuthUser::\"<sub>\"")
        print(f"  company_code    : {claims.get('company_code')}   ← P1 の tag")
        print(f"  department_code : {claims.get('department_code')}   ← P2 の tag")
        print(f"  agents          : {claims.get('agents')}   ← P3 の tag(配列の tag 表現は未確認)")
        print(f"  exp             : {claims.get('exp')} (あと {claims.get('exp', 0) - now} 秒)")
        if args.tamper:
            token = tamper(token)
            print("  ※ --tamper: 署名バイト列の先頭 1 ビットを反転した(中身は上のまま、署名だけ不一致)")
    else:
        print("  (JWT ではないので省略)")

    # ------------------------------------------------------------ [3/4]
    banner("3/4", "JSON-RPC リクエストの組み立て")
    params: dict[str, Any]
    if args.method == "initialize":
        params = {
            "protocolVersion": MCP_PROTOCOL_VERSION,
            "capabilities": {},
            "clientInfo": {"name": "authchain-call-gateway", "version": "1.0"},
        }
    elif args.method == "tools/list":
        params = {}
    else:
        params = {"name": args.tool, "arguments": json.loads(args.args)}
    payload = {"jsonrpc": "2.0", "id": 1, "method": args.method, "params": params}
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json, text/event-stream",
    }
    if args.method != "initialize":
        headers["MCP-Protocol-Version"] = MCP_PROTOCOL_VERSION
    if token is not None:
        headers["Authorization"] = f"Bearer {token}"
    trace_id = ""
    if not args.no_traceparent:
        # version 00 / trace-id 32 桁 / parent-id 16 桁 / flags 01(sampled)。trace-id で aws/spans を引く
        trace_id = secrets.token_hex(16)
        headers["traceparent"] = f"00-{trace_id}-{secrets.token_hex(8)}-01"
    print(f"  POST {gateway_url}")
    for k, v in headers.items():
        shown = f"Bearer {v[7:19]}…{v[-6:]}" if k == "Authorization" and len(v) > 30 else v
        print(f"  {k}: {shown}")
    print(f"  body: {body.decode('utf-8')}")

    # ------------------------------------------------------------ [4/4]
    banner("4/4", "応答")
    req = urllib.request.Request(gateway_url, data=body, method="POST", headers=headers)
    started = time.time()
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
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
    content_type = next((v for k, v in resp_headers.items() if k.lower() == "content-type"), "")
    try:
        parsed = parse_body(raw, content_type)
        print(json.dumps(parsed, ensure_ascii=False, indent=2))
    except json.JSONDecodeError:
        parsed = {"raw": raw}
        print(f"  {raw[:2000]}")

    # 判定の要約。公式 use-gateway-with-policy は拒否を result.isError=true と書くが、
    # V4b 実測では HTTP 200 + JSON-RPC error(-32002 "Tool Execution Denied: ... [理由]")で返った
    result = parsed.get("result") if isinstance(parsed, dict) else None
    error = parsed.get("error") if isinstance(parsed, dict) else None
    if isinstance(error, dict):
        print(f"  → JSON-RPC error: {error.get('code')}  {str(error.get('message'))[:200]}")
    elif args.method == "tools/call" and isinstance(result, dict):
        texts = [c.get("text", "") for c in result.get("content", []) if isinstance(c, dict)]
        print(f"  → isError: {result.get('isError')}  先頭: {(texts[0] if texts else '')[:200]}")
    elif args.method == "tools/list" and isinstance(result, dict):
        print(f"  → tools: {[t.get('name') for t in result.get('tools', [])]}")
    if trace_id:
        print(f"  → traceId: {trace_id}(aws/spans で traceId = '{trace_id}' を検索。反映まで数分)")
    if args.save:
        with open(args.save, "w", encoding="utf-8") as f:
            json.dump(
                {"status": status, "headers": resp_headers, "body": parsed, "request": payload, "traceId": trace_id},
                f, ensure_ascii=False, indent=2,
            )
        print(f"  → 保存: {args.save}")
    return 0 if 200 <= status < 300 else 1


if __name__ == "__main__":
    sys.exit(main())
