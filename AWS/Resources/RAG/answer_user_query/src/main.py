import boto3
import json
import os
from opensearchpy import OpenSearch, AWSV4SignerAuth, RequestsHttpConnection

OPENSEARCH_ENDPOINT = os.environ['OPENSEARCH_ENDPOINT'].replace("https://", "")
REGION = "ap-northeast-1"
INDEX_NAME = "faqs"

bedrock_client = boto3.client('bedrock-runtime', region_name=REGION)

def invoke_bedrock_embedding(client, model_id, input_text, dimensions=512, normalize=True):
    body = {"inputText": input_text, "dimensions": dimensions, "normalize": normalize}
    response = client.invoke_model(
        modelId=model_id,
        contentType="application/json",
        accept="application/json",
        body=json.dumps(body)
    )
    result = json.loads(response['body'].read())
    return result['embedding']

def connect_opensearch():
    print(f"[info] Start Connecting to OpenSearch")
    """OpenSearch Serverless への接続を作成"""
    credentials = boto3.Session().get_credentials()
    auth = AWSV4SignerAuth(credentials, REGION, "aoss")
    
    return OpenSearch(
        hosts=[{"host": OPENSEARCH_ENDPOINT, "port": 443}],
        http_auth=auth,
        use_ssl=True,
        verify_certs=True,
        connection_class=RequestsHttpConnection,
        timeout=30
    )

def search_opensearch(embedding, top_k=5):
    query = {
        "size": top_k,
        "query": {
            "knn": {
                "embedding": {
                    "vector": embedding,
                    "k": top_k
                }
            }
        }
    }
    
    opensearch_client = connect_opensearch()
    response = opensearch_client.search(body=query, index=INDEX_NAME)

    return [hit["_source"]["text"] for hit in response["hits"]["hits"]]

def ask_claude(client, user_question, context_text):
    """Claude に検索結果を渡して回答を生成"""
    model_id = "apac.anthropic.claude-3-5-sonnet-20241022-v2:0"
    prompt = f"""
    あなたは AWS の公式 FAQ から情報を取得して質問に回答する AI です。

    【重要なルール】  
    - 提供された情報 **のみ** を使って回答してください。  
    - もし提供された情報の中に答えがない場合は、「提供された情報には回答が見つかりませんでした」と返答してください。  
    - 知識を補完しようとせず、提供された情報を **そのまま** 活用してください。  

    【質問】  
    {user_question}

    【提供された情報】  
    {context_text}

    提供された情報のみを使い、分かりやすく簡潔に回答してください。
    """
    
    response = client.invoke_model(
        modelId=model_id,
        contentType="application/json",
        accept="application/json",
        body=json.dumps({
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 4096,
            "temperature": 0.0,
            "messages": [
              {
                "role": "user",
                "content": [
                    {
                    "type": "text",
                    "text": prompt
                 }
            ]
              }
            ],
        })
    )
    result = json.loads(response['body'].read())
    return result["content"][0]["text"]

def lambda_handler(event, context):
    print(f"[info] Start Lambda Handler")
    print(f"[info] Event: {event}")
    print(f"[info] Context: {context}")
    body = json.loads(event["body"])
    user_question = body.get("question", "")
    
    if not user_question:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "No question provided"})
        }
    
    # ベクトル化
    model_id = "amazon.titan-embed-text-v2:0"
    embedding = invoke_bedrock_embedding(bedrock_client, model_id, user_question, dimensions=512, normalize=True)
    
    # OpenSearch で検索
    search_results = search_opensearch(embedding, top_k=5)
    
    if not search_results:
        return {
            "statusCode": 200,
            "body": json.dumps({"answer": "提供された情報には回答が見つかりませんでした"}, ensure_ascii=False)
        }
    
    context_text = "\n".join(search_results)
    answer = ask_claude(bedrock_client, user_question, context_text)

    return {
        "statusCode": 200,
        "headers": {  # 必要なCORSヘッダーを最終的なreturnにのみ追加
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type"
        },
        "body": json.dumps({"question": user_question, "answer": answer}, ensure_ascii=False)
    }
