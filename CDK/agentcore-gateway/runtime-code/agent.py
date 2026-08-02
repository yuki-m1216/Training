from bedrock_agentcore import BedrockAgentCoreApp
from strands import Agent
from strands.models import BedrockModel

# /invocations (POST) と /ping (GET) を 8080 番で提供する HTTP サーバーの実体。
# AgentCore Runtime のサービスコントラクトはこの SDK が担うため、自前実装は不要
app = BedrockAgentCoreApp()

# strands のデフォルトモデルは US リージョン向けプロファイルのため、東京では
# ValidationException になる。jp. プレフィックス(国内クロスリージョン推論)を明示する
model = BedrockModel(
    model_id="jp.anthropic.claude-haiku-4-5-20251001-v1:0",
    region_name="ap-northeast-1",
)
agent = Agent(model=model)


# Runtime が /invocations で受けたリクエストボディ(JSON)が payload に渡ってくる
@app.entrypoint
def invoke(payload):
    # ペイロード形式はエージェント実装の自由だが、公式サンプルの慣例に合わせて
    # {"prompt": "..."} を受ける。キー欠落時は挙動確認しやすい固定文にフォールバック
    prompt = payload.get("prompt", "こんにちは。自己紹介してください")
    result = agent(prompt)
    # AgentResult.message は {role, content} の dict で JSON 直列化可能。
    # テキストだけ返すと途中経過が失われるため message ごと返す
    return {"result": result.message}


# entrypoint 指定で `python agent.py` として実行された時のみサーバーを起動する。
# (将来テスト等で import された場合に起動してしまうのを防ぐ)
if __name__ == "__main__":
    app.run()
