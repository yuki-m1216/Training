"""Gateway Lambda ターゲット(VerifyTarget___echo_profile)— Gateway から何が渡ってくるかを観測する。

流れ:
  1. Gateway が tools/call を受け、JWT 検証(V3)・Policy 評価(V4)を通ったら、この関数を Invoke する
  2. event にはツールの入力引数(inputSchema の properties)だけが入る(例 {"note": "hi"})
  3. context.client_context.custom に Gateway のメタデータが入る(公式の列挙は 6 キー:
     bedrockAgentCoreMessageVersion / AwsRequestId / McpMessageId / GatewayId / TargetId / ToolName)
  4. ユーザーの sub・クレーム・トークンが渡るか(計画 §6-6)を見るため、event と client_context を**丸ごと**ログと応答に出す。
     予想: 公式の 6 キーのみで、ユーザー情報は届かない(届けるには interceptor が要る)
  5. 万一トークンらしき値(eyJ で始まる)が混ざっていたらマスクして出す(ログ・応答に秘密を残さない)

参照(公式): https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway-add-target-lambda.html
"""
from __future__ import annotations

import json
import logging
from typing import Any

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# ツール名は "<TargetName>___<tool>"(アンダースコア 3 本。仮決め #6)
DELIMITER = "___"


def _mask(value: Any) -> Any:
    """JWT らしき文字列を伏せる(辞書・配列は再帰)。"""
    if isinstance(value, str) and value.startswith("eyJ") and value.count(".") == 2:
        return f"{value[:12]}…(masked JWT, len={len(value)})"
    if isinstance(value, dict):
        return {k: _mask(v) for k, v in value.items()}
    if isinstance(value, list):
        return [_mask(v) for v in value]
    return value


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    client_context = getattr(context, "client_context", None)
    custom = dict(getattr(client_context, "custom", None) or {})
    # client_context.env / client(モバイル SDK 由来の枠)も、何か入っていないか念のため見る
    cc_env = getattr(client_context, "env", None)
    cc_client = getattr(client_context, "client", None)

    prefixed = custom.get("bedrockAgentCoreToolName", "")
    tool_name = prefixed.split(DELIMITER, 1)[-1] if DELIMITER in prefixed else prefixed

    observed = {
        "tool_name_received": prefixed,
        "tool_name_stripped": tool_name,
        "event": _mask(event),
        "client_context_custom": _mask(custom),
        "client_context_env": _mask(cc_env) if cc_env else None,
        "client_context_client": str(cc_client) if cc_client else None,
        "lambda_request_id": getattr(context, "aws_request_id", None),
    }
    logger.info("echo_profile observed: %s", json.dumps(observed, ensure_ascii=False, default=str))

    if tool_name != "echo_profile":
        raise ValueError(f"Unknown tool: {prefixed}")
    return observed
