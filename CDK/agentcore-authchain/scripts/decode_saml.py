#!/usr/bin/env python3
"""SAML メッセージを「見るため」にデコードして要約する。署名は検証しない。

対応する入力(自動判別):
  - SAMLResponse(HTTP-POST バインディング。Entra → Cognito の /saml2/idpresponse への POST フォーム値)
      = base64 のみ
  - SAMLRequest(HTTP-Redirect バインディング。Cognito → Entra の login.microsoftonline.com へのリダイレクト
    URL のクエリ値)
      = raw DEFLATE → base64 → URL エンコード
  DevTools からコピーしたときの "SAMLRequest=...&RelayState=..." のような貼り付けにも対応する。

使い方:
  python3 scripts/decode_saml.py '<base64...>'          # 要約を表示
  python3 scripts/decode_saml.py saml_response.txt     # ファイル(中身は base64)
  cat x.txt | python3 scripts/decode_saml.py -          # stdin
  python3 scripts/decode_saml.py x.txt --xml            # 整形した XML 全文を表示
  python3 scripts/decode_saml.py x.txt --json           # 要約を JSON で出力
"""
from __future__ import annotations

import argparse
import base64
import binascii
import json
import sys
import urllib.parse
import xml.dom.minidom
import xml.etree.ElementTree as ET
import zlib
from typing import Any

NS_SAMLP = "urn:oasis:names:tc:SAML:2.0:protocol"
NS_SAML = "urn:oasis:names:tc:SAML:2.0:assertion"
NS_DS = "http://www.w3.org/2000/09/xmldsig#"


def _local(tag: str) -> str:
    """'{ns}Name' → 'Name'"""
    return tag.rsplit("}", 1)[-1]


def _extract_param(text: str) -> str:
    """'SAMLRequest=xxx&RelayState=yyy' や 'SAMLResponse=xxx' が丸ごと貼られた場合に値だけ取り出す。"""
    if "=" in text and ("SAMLRequest" in text or "SAMLResponse" in text):
        params = urllib.parse.parse_qs(text, keep_blank_values=True)
        for key in ("SAMLResponse", "SAMLRequest"):
            if key in params and params[key]:
                # parse_qs は URL デコード済みの値を返す
                return params[key][0]
    return text


def decode_saml_message(data: str) -> tuple[str, str]:
    """base64(＋raw DEFLATE)を解いて XML 文字列と種別を返す。

    戻り値: (xml_text, kind)  kind は "base64"(POST バインディング) か "base64+deflate"(Redirect バインディング)
    """
    text = _extract_param(data.strip())
    # 改行・空白除去(ブラウザやエディタで折り返された貼り付けに耐える)
    text = "".join(text.split())
    if "%" in text:
        text = urllib.parse.unquote(text)  # クエリ値のままコピーされたケース(%2B, %3D など)
    if not text:
        raise ValueError("入力が空です")
    padding = (-len(text)) % 4
    try:
        raw = base64.b64decode(text + "=" * padding, validate=False)
    except (binascii.Error, ValueError) as e:
        raise ValueError(f"base64 のデコードに失敗しました: {e}") from e
    if not raw:
        raise ValueError("base64 を解いた結果が空です")

    if raw.lstrip(b"\xef\xbb\xbf \t\r\n").startswith(b"<"):
        return raw.decode("utf-8"), "base64"

    try:
        inflated = zlib.decompress(raw, -15)  # -15: zlib ヘッダ無しの raw DEFLATE(SAML Redirect バインディング)
    except zlib.error as e:
        raise ValueError(f"XML でも raw DEFLATE でもありません(展開失敗: {e})") from e
    if not inflated.lstrip(b"\xef\xbb\xbf \t\r\n").startswith(b"<"):
        raise ValueError("DEFLATE 展開後も XML になりません")
    return inflated.decode("utf-8"), "base64+deflate"


def pretty_xml(xml_text: str) -> str:
    """minidom で整形(2 スペースインデント)。XML 宣言行は落として本文だけ返す。"""
    dom = xml.dom.minidom.parseString(xml_text.encode("utf-8"))
    pretty = dom.toprettyxml(indent="  ")
    lines = [line for line in pretty.splitlines() if line.strip()]
    if lines and lines[0].startswith("<?xml"):
        lines = lines[1:]
    return "\n".join(lines)


def _first(elem: ET.Element | None, path: str) -> ET.Element | None:
    return None if elem is None else elem.find(path)


def _text(elem: ET.Element | None) -> str | None:
    if elem is None or elem.text is None:
        return None
    return elem.text.strip()


def _summarize_assertion(assertion: ET.Element) -> dict[str, Any]:
    subject = _first(assertion, "{*}Subject")
    name_id = _first(subject, "{*}NameID")
    conf_data = _first(subject, "{*}SubjectConfirmation/{*}SubjectConfirmationData")
    conditions = _first(assertion, "{*}Conditions")
    authn = _first(assertion, "{*}AuthnStatement")

    attributes: dict[str, list[str]] = {}
    for attr in assertion.iterfind("{*}AttributeStatement/{*}Attribute"):
        name = attr.get("Name", "")
        values = [(_text(v) or "") for v in attr.iterfind("{*}AttributeValue")]
        attributes.setdefault(name, []).extend(values)

    return {
        "id": assertion.get("ID"),
        "issue_instant": assertion.get("IssueInstant"),
        "issuer": _text(_first(assertion, "{*}Issuer")),
        "signed": _first(assertion, f"{{{NS_DS}}}Signature") is not None,
        "name_id": _text(name_id),
        "name_id_format": None if name_id is None else name_id.get("Format"),
        "subject_confirmation": None
        if conf_data is None
        else {
            "recipient": conf_data.get("Recipient"),
            "in_response_to": conf_data.get("InResponseTo"),
            "not_on_or_after": conf_data.get("NotOnOrAfter"),
        },
        "conditions": None
        if conditions is None
        else {"not_before": conditions.get("NotBefore"), "not_on_or_after": conditions.get("NotOnOrAfter")},
        "audience": _text(_first(assertion, "{*}Conditions/{*}AudienceRestriction/{*}Audience")),
        "authn_instant": None if authn is None else authn.get("AuthnInstant"),
        "session_index": None if authn is None else authn.get("SessionIndex"),
        "authn_context": _text(_first(authn, "{*}AuthnContext/{*}AuthnContextClassRef")),
        "attributes": attributes,
    }


def summarize(xml_text: str) -> dict[str, Any]:
    """SAML Response / AuthnRequest / LogoutRequest 等の見どころを dict にまとめる。署名は「有無」だけ見る。"""
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError as e:
        raise ValueError(f"XML として解析できません: {e}") from e

    kind = _local(root.tag)
    summary: dict[str, Any] = {
        "type": kind,
        "id": root.get("ID"),
        "version": root.get("Version"),
        "issue_instant": root.get("IssueInstant"),
        "destination": root.get("Destination"),
        "issuer": _text(_first(root, "{*}Issuer")),
        "signed": _first(root, f"{{{NS_DS}}}Signature") is not None,
    }

    if kind == "Response":
        status = _first(root, "{*}Status/{*}StatusCode")
        assertion = _first(root, "{*}Assertion")
        summary.update(
            {
                "in_response_to": root.get("InResponseTo"),
                "status": None if status is None else status.get("Value"),
                "status_message": _text(_first(root, "{*}Status/{*}StatusMessage")),
                "encrypted_assertion": _first(root, "{*}EncryptedAssertion") is not None,
                "assertion": None if assertion is None else _summarize_assertion(assertion),
            }
        )
    elif kind == "AuthnRequest":
        policy = _first(root, "{*}NameIDPolicy")
        summary.update(
            {
                "assertion_consumer_service_url": root.get("AssertionConsumerServiceURL"),
                "protocol_binding": root.get("ProtocolBinding"),
                "force_authn": root.get("ForceAuthn"),
                "name_id_policy_format": None if policy is None else policy.get("Format"),
                "allow_create": None if policy is None else policy.get("AllowCreate"),
            }
        )
    elif kind in ("LogoutRequest", "LogoutResponse"):
        status = _first(root, "{*}Status/{*}StatusCode")
        summary.update(
            {
                "in_response_to": root.get("InResponseTo"),
                "name_id": _text(_first(root, "{*}NameID")),
                "status": None if status is None else status.get("Value"),
            }
        )
    return summary


# ---------------------------------------------------------------- CLI

def _read_source(source: str) -> str:
    if source == "-":
        return sys.stdin.read()
    try:
        with open(source, encoding="utf-8") as f:
            return f.read()
    except (FileNotFoundError, OSError):
        return source


def _print_summary(summary: dict[str, Any], kind: str) -> None:
    binding = "HTTP-POST(base64 のみ)" if kind == "base64" else "HTTP-Redirect(base64 + raw DEFLATE)"
    print(f"===== SAML {summary.get('type')}  [{binding}] =====")
    skip = {"assertion", "type"}
    for key, value in summary.items():
        if key in skip:
            continue
        print(f"  {key:32s} {value}")
    assertion = summary.get("assertion")
    if summary.get("encrypted_assertion"):
        print("  ※ Assertion は暗号化されています(EncryptedAssertion)。属性は復号鍵(SP 側)なしには見えません")
    if assertion:
        print("  --- Assertion ---")
        for key, value in assertion.items():
            if key == "attributes":
                continue
            print(f"  {key:32s} {value}")
        print("  --- Attributes(IdP が実際に送った属性の現物) ---")
        if not assertion["attributes"]:
            print("  (なし)")
        for name, values in assertion["attributes"].items():
            print(f"  {name}")
            for v in values:
                print(f"      = {v}")
    print("  ※署名は検証していません(存在の有無のみ表示)")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="SAMLResponse / SAMLRequest をデコードして要約する(署名は検証しない)")
    parser.add_argument("source", help="base64 文字列 / それを含むファイル / '-'(stdin)")
    parser.add_argument("--xml", action="store_true", help="整形した XML 全文を表示")
    parser.add_argument("--json", action="store_true", help="要約を JSON で出力")
    args = parser.parse_args(argv)

    try:
        xml_text, kind = decode_saml_message(_read_source(args.source))
        summary = summarize(xml_text)
    except ValueError as e:
        print(f"デコード失敗: {e}", file=sys.stderr)
        return 1

    if args.xml:
        print(pretty_xml(xml_text))
        return 0
    if args.json:
        print(json.dumps({"binding": kind, **summary}, ensure_ascii=False, indent=2))
        return 0
    _print_summary(summary, kind)
    return 0


if __name__ == "__main__":
    sys.exit(main())
