"""V2 観測用の最小エージェント(inspect_headers)。LLM は使わない。

やること(payload["action"] で切替):
  - "inspect"(既定): Runtime から渡ってきた HTTP ヘッダ名の一覧と、Authorization の JWT の中身(署名検証はしない。
    署名・iss・client_id・customClaims は Runtime の JWT オーソライザが検証済み)を返す
  - "gateway": 同じ Authorization(Bearer)をそのまま付けて Gateway(MCP)を呼ぶ(tools/list と、指定があれば tools/call)。
    「ユーザーのトークンを透過させる」経路の実体(計画_追加要件 §3)

前提:
  - Runtime の requestHeaderConfiguration.allowlistedHeaders に "Authorization" が入っていないと、
    Runtime は Authorization を検証だけして転送しない → received_header_names に出てこない(V2a で観測)
  - bedrock-agentcore SDK は Authorization を大小文字正規化して context.request_headers["Authorization"] に入れる
参照(公式): https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-header-allowlist.html
            https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway-agent-integration.html
"""
from __future__ import annotations

import os
import time
from typing import Any

import httpx
import jwt  # PyJWT
from bedrock_agentcore import BedrockAgentCoreApp
from bedrock_agentcore.runtime.context import RequestContext
from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client
from mcp.shared.exceptions import McpError

app = BedrockAgentCoreApp()

# CDK から渡す。customClaims(agents CONTAINS <AGENT_KEY>)と AgentEntitlement の sk と同じ値
AGENT_KEY = os.environ.get("AGENT_KEY", "<unset>")
# V3 以降で CDK から渡す(V2 では未設定 → action=gateway はエラーを返す)
GATEWAY_URL = os.environ.get("GATEWAY_URL", "")
# Gateway の Policy 拒否の JSON-RPC エラーコード(V4b 実測)。Gateway 入口の 403 の本文も同じコードなので、HTTP ステータスと併せて区別する
POLICY_DENIED_CODE = -32002

# 表示するクレーム(存在するものだけ)。トークン全体を返さないのは、ログ・応答に不要なものを載せないため
SHOW_CLAIMS = [
    "sub", "iss", "token_use", "client_id", "aud", "username", "cognito:groups", "scope",
    "company_code", "department_code", "agents", "upn", "iat", "exp", "auth_time", "origin_jti",
]


def _mask(value: str, keep: int = 6) -> str:
    return value if len(value) <= keep * 2 else f"{value[:keep]}…{value[-4:]}"


def _inspect_authorization(auth_header: str) -> dict[str, Any]:
    """Authorization ヘッダの JWT を検証なしでデコードして要点を返す。"""
    scheme, _, token = auth_header.partition(" ")
    if scheme.lower() != "bearer" or not token:
        return {"present": True, "scheme": scheme, "note": "Bearer 形式ではない"}
    try:
        header = jwt.get_unverified_header(token)
        claims = jwt.decode(token, options={"verify_signature": False})
    except jwt.PyJWTError as exc:  # 改ざん実験で JWT の形が壊れている場合など
        return {"present": True, "scheme": scheme, "decode_error": f"{type(exc).__name__}: {exc}"}
    now = int(time.time())
    return {
        "present": True,
        "scheme": scheme,
        "token_masked": _mask(token),
        "header": {k: header.get(k) for k in ("alg", "kid") if k in header},
        "claims": {k: claims[k] for k in SHOW_CLAIMS if k in claims},
        "other_claim_names": sorted(k for k in claims if k not in SHOW_CLAIMS),
        "expires_in_seconds": (claims.get("exp") or 0) - now,
        "agent_key_in_agents": AGENT_KEY in (claims.get("agents") or []),
    }


async def _call_gateway(auth_header: str, tool: str | None, arguments: dict[str, Any] | None) -> dict[str, Any]:
    """同じ Bearer で Gateway(MCP)を呼ぶ。tools/list → (指定があれば) tools/call。"""
    if not GATEWAY_URL:
        return {"error": "GATEWAY_URL が未設定(V3 で Gateway スタックの出力を渡す)"}
    result: dict[str, Any] = {"gateway_url": GATEWAY_URL}
    # mcp 1.x: streamablehttp_client は (read, write, get_session_id) を返す。initialize で MCP バージョンを交渉する
    async with streamablehttp_client(GATEWAY_URL, headers={"Authorization": auth_header}) as (read, write, _get_sid):
        async with ClientSession(read, write) as session:
            init = await session.initialize()
            result["protocol_version"] = getattr(init, "protocolVersion", None)
            listed = await session.list_tools()
            # ツール名の実物(<Target>___<tool> の区切りを確認する。仮決め #6)
            result["tools"] = [t.name for t in listed.tools]
            if tool:
                result["call"] = {"tool": tool, "arguments": arguments or {}}
                try:
                    call = await session.call_tool(tool, arguments or {})
                except McpError as exc:
                    # Policy の拒否は HTTP 200 の JSON-RPC error -32002 で返り、call_tool が McpError を投げる(V4b で実測。
                    # 公式の isError=true ではない)。async with の内側で捕まえないと TaskGroup の ExceptionGroup に包まれる
                    result["call"]["error"] = {
                        "kind": "policy_denied" if exc.error.code == POLICY_DENIED_CODE else "mcp_error",
                        "code": exc.error.code,
                        "message": exc.error.message,
                    }
                else:
                    result["call"]["isError"] = call.isError
                    result["call"]["content"] = [getattr(c, "text", None) or c.model_dump() for c in call.content]
    return result


def _http_error(exc: httpx.HTTPStatusError) -> dict[str, Any]:
    """Gateway 入口の拒否(401: Bearer 無し・非 JWT／403: 検証失敗。V3 で実測)を、呼び出し元が次に何をすべきかと一緒に返す。"""
    status = exc.response.status_code
    error: dict[str, Any] = {"kind": "gateway_http_error", "http_status": status}
    if status in (401, 403):
        # 本文(JSON-RPC -32001/-32002)と WWW-Authenticate に理由が入る。トークンの取り直しで直る可能性がある
        error["www_authenticate"] = exc.response.headers.get("WWW-Authenticate")
        error["hint"] = "トークンを取り直して再試行する(期限切れ・クライアント不一致など)"
    return error


@app.entrypoint
async def invoke(payload: dict[str, Any] | None, context: RequestContext) -> dict[str, Any]:
    payload = payload or {}
    headers = context.request_headers or {}
    observed: dict[str, Any] = {
        "agent_key": AGENT_KEY,
        "session_id": context.session_id,
        # どのヘッダが Runtime を通過してきたか(allowlist の効果を見る本体)
        "received_header_names": sorted(headers.keys()),
    }
    auth_header = headers.get("Authorization")
    observed["authorization"] = (
        _inspect_authorization(auth_header)
        if auth_header
        else {"present": False, "note": "Authorization が転送されていない(allowlist 未設定なら期待どおり)"}
    )

    action = payload.get("action", "inspect")
    if action == "gateway":
        if not auth_header:
            observed["gateway"] = {"error": "Authorization が無いため透過できない"}
        else:
            try:
                observed["gateway"] = await _call_gateway(auth_header, payload.get("tool"), payload.get("arguments"))
            except* httpx.HTTPStatusError as eg:
                # HTTP の失敗は streamablehttp_client の裏タスクで起きるので、TaskGroup の ExceptionGroup に包まれて上がる
                observed["gateway"] = {"error": _http_error(eg.exceptions[0])}
            except* Exception as eg:  # 想定外(接続失敗など)。中身をそのまま観測結果として返す
                exc = eg.exceptions[0]
                observed["gateway"] = {"error": {"kind": "unexpected", "detail": f"{type(exc).__name__}: {exc}"}}
    return observed


if __name__ == "__main__":
    app.run()
