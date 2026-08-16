"""Cognito Pre Token Generation トリガー(V2_0)— 会社・部門の正規化クレーム注入。

流れ:
  1. Cognito がログイン(hosted UI / リフレッシュ等)のたびに、このユーザーの属性一式を
     event["request"]["userAttributes"] に入れて呼ぶ(custom:company_raw / custom:department_raw を含む)
  2. 生値を DynamoDB 認可マスタ(pk = "COMPANY#<生値>" / "DEPT#<生値>")で引き、正規化コードを得る
  3. ヒットしたクレームだけを ID トークンとアクセストークンの両方に注入する
     (event["response"]["claimsAndScopeOverrideDetails"]["idTokenGeneration" | "accessTokenGeneration"]
      ["claimsToAddOrOverride"] に {"company_code": "TESTCO", "department_code": "SALES1"})
  4. 未ヒット・生値欠落は「注入しない + WARNING ログ」(仮決め #5: fail-closed。Cedar のデフォルト拒否で落ちる)
  5. event をそのまま返す(Cognito は返ってきた event.response を適用する)

参照(公式): https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-lambda-pre-token-generation.html
  - V2_0 のレスポンス形 / 追加できるクレームは「トークンスキーマにない任意クレーム」
  - V2_0 のアクセストークン改変は Essentials / Plus プランが前提
"""
from __future__ import annotations

import json
import logging
import os
from typing import Any

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TABLE_NAME = os.environ["TABLE_NAME"]
_table = boto3.resource("dynamodb").Table(TABLE_NAME)

# 生値の受け皿(仮決め #4) → 認可マスタのキー種別 / 注入するクレーム名(仮決め #3)
RAW_ATTRIBUTE_TO_CLAIM: dict[str, tuple[str, str]] = {
    "custom:company_raw": ("COMPANY", "company_code"),
    "custom:department_raw": ("DEPT", "department_code"),
}


def lookup_code(kind: str, raw_value: str) -> str | None:
    """認可マスタから正規化コードを引く。未登録なら None。"""
    resp = _table.get_item(Key={"pk": f"{kind}#{raw_value}"}, ProjectionExpression="code")
    item = resp.get("Item")
    return item.get("code") if item else None


def normalize_claims(user_attributes: dict[str, str]) -> dict[str, str]:
    """生値属性 → 注入クレーム。クレーム単位で fail-closed。"""
    claims: dict[str, str] = {}
    for attr_name, (kind, claim_name) in RAW_ATTRIBUTE_TO_CLAIM.items():
        raw_value = (user_attributes.get(attr_name) or "").strip()
        if not raw_value:
            logger.warning("[fail-closed] %s が空または欠落のため %s を注入しません", attr_name, claim_name)
            continue
        code = lookup_code(kind, raw_value)
        if code is None:
            logger.warning("[fail-closed] %s#%s が認可マスタに未登録のため %s を注入しません", kind, raw_value, claim_name)
            continue
        claims[claim_name] = code
    return claims


def lambda_handler(event: dict[str, Any], _context: Any) -> dict[str, Any]:
    request = event.get("request") or {}
    user_attributes: dict[str, str] = request.get("userAttributes") or {}

    # 観測用: どの経路(triggerSource)で、どの属性キーが渡ってきたか(値は載せない。V1c で CloudWatch Logs を見る)
    logger.info(
        json.dumps(
            {
                "version": event.get("version"),
                "triggerSource": event.get("triggerSource"),
                "userName": event.get("userName"),
                "clientId": (event.get("callerContext") or {}).get("clientId"),
                "userAttributeKeys": sorted(user_attributes.keys()),
                "scopes": request.get("scopes"),
            },
            ensure_ascii=False,
        )
    )

    claims = normalize_claims(user_attributes)

    # V2_0 の形。ID トークンとアクセストークンの両方に同じクレームを注入する(仮決め #1: AgentCore へはアクセストークン)
    event["response"] = {
        "claimsAndScopeOverrideDetails": {
            "idTokenGeneration": {"claimsToAddOrOverride": dict(claims)},
            "accessTokenGeneration": {"claimsToAddOrOverride": dict(claims)},
        }
    }
    logger.info(json.dumps({"injectedClaims": claims}, ensure_ascii=False))
    return event
