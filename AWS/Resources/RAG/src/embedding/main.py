import boto3
import json
import os
from opensearchpy import OpenSearch, RequestsHttpConnection, AWSV4SignerAuth
from langchain_community.document_loaders import PyPDFLoader
from langchain.text_splitter import CharacterTextSplitter

# 環境変数から OpenSearch のエンドポイントを取得
OPENSEARCH_ENDPOINT = os.environ['OPENSEARCH_ENDPOINT'].replace("https://", "")
S3BUCKET = os.environ['S3BUCKET']
S3BUCKET_KEY = os.environ['S3BUCKET_KEY']
OPENSEARCH_INDEX = "faqs"
REGION = "ap-northeast-1"
s3_client = boto3.client("s3")
bedrock_client = boto3.client('bedrock-runtime', region_name=REGION)

def download_pdf():
    print(f"[info] Start Downloading PDF from s3://{S3BUCKET}/{S3BUCKET_KEY}")
    local_path = "/tmp/document.pdf"
    s3_client.download_file(S3BUCKET, S3BUCKET_KEY, local_path)
    print(f"[info] End Downloaded PDF to {local_path}")
    return local_path

def pdf_to_text(local_path):
    print(f"[info] Start pdf_to_text")
    loader = PyPDFLoader(local_path)
    pages = loader.load_and_split()
    splitter = CharacterTextSplitter(chunk_size=8192)
    text = splitter.split_documents(pages)
    # success message
    print(f"[info] End pdf_to_text")
    return text

def invoke_bedrock_embedding(client, model_id, input_text, dimensions=512, normalize=True):
    print(f"[info] Start Embedding")
    """Amazon Titan Text Embeddings V2 モデルを用いてベクトル化"""
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

    result = json.loads(response['body'].read())
    print(f"[info] End Embedding")
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
        connection_class=RequestsHttpConnection
    )

def index_document(opensearch_client, text, embedding):
    print(f"[info] Start Indexing Document")

    """OpenSearch Serverless にデータを投入"""
    document = {
        "text": text,
        "embedding": embedding
    }

    response = opensearch_client.index(
        index=OPENSEARCH_INDEX,
        body=document,
    )

    print(f"[info] End Indexing Document")    
    return response

def lambda_handler(event, context):
    opensearch_client = connect_opensearch()

    results = []
    model_id = "amazon.titan-embed-text-v2:0"

# embed_pdf() で PDF をダウンロードしてテキスト化しチャンクサイズに分割後、チャンクごとにベクトル化して OpenSearch に投入
    local_path = download_pdf()
    text = pdf_to_text(local_path)
    text_chunks = text.split('\n')
    # splitされているか確認
    print(text_chunks)
    for chunk in text_chunks:
        embedding = invoke_bedrock_embedding(bedrock_client, model_id, chunk, dimensions=512, normalize=True)
        response = index_document(opensearch_client, chunk, embedding)
        results.append(response)

    # for chunk in text_chunks:
    #     embedding = invoke_bedrock_embedding(bedrock_client, model_id, chunk, dimensions=512, normalize=True)
    #     response = index_document(opensearch_client, chunk, embedding)
    #     results.append(response)

    return {
        'statusCode': 200,
        'results': results
    }
