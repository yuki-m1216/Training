import boto3
import requests
from bs4 import BeautifulSoup
import json

def get_document_text(url):
    response = requests.get(url)
    soup = BeautifulSoup(response.content, 'html.parser')
    return soup.get_text(separator=' ', strip=True)

def chunk_text(text, chunk_size=8192):
    return [text[i:i+chunk_size] for i in range(0, len(text), chunk_size)]

def invoke_bedrock_embedding(client, model_id, input_text, dimensions=512, normalize=True):
    body = {
        "inputText": input_text,
        "dimensions": dimensions,
        "normalize": normalize
    }
    
    response = client.invoke_model(
        modelId=model_id,
        contentType="application/json",
        accept="application/json",
        body=json.dumps(body)
    )
    
    # レスポンスの body はストリームとして返されるため、read()で内容を取得
    result = json.loads(response['body'].read())
    return result['embedding']

def lambda_handler(event, context):
    url = "https://docs.aws.amazon.com/ja_jp/bedrock/latest/userguide/what-is-bedrock.html"
    
    text = get_document_text(url)
    
    text_chunks = chunk_text(text, chunk_size=8192)
    
    client = boto3.client('bedrock-runtime', region_name='ap-northeast-1')
    
    model_id = "amazon.titan-embed-text-v2:0"
    
    embeddings = []
    
    for chunk in text_chunks:
        embedding = invoke_bedrock_embedding(client, model_id, chunk, dimensions=512, normalize=True)
        embeddings.append(embedding)
    
    return {
        'statusCode': 200,
        'embeddings': embeddings
    }
