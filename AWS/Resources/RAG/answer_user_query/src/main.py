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

    if 'hits' in response and 'hits' in response['hits']:
        return response['hits']['hits']
    else:
        print(f"Error searching OpenSearch: {response}")
        return []

def lambda_handler(event, context):
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
    
    return {
        "statusCode": 200,
        "body": json.dumps({"results": search_results}, ensure_ascii=False)
    }
