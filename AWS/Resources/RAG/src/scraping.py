import requests
from bs4 import BeautifulSoup

# 対象ページ
url = "https://docs.aws.amazon.com/ja_jp/bedrock/latest/userguide/what-is-bedrock.html"

# ページの取得
response = requests.get(url)
response.raise_for_status()  # HTTPエラーの確認
response.encoding = response.apparent_encoding  # 自動エンコーディング検出

# HTMLのパース
soup = BeautifulSoup(response.text, "html.parser")

# テキスト抽出
text = "\n".join([p.get_text() for p in soup.find_all("p")])

# 結果確認
print(text)
