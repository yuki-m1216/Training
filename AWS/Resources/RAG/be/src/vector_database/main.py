import boto3
import json
import os
from opensearchpy import OpenSearch, RequestsHttpConnection, AWSV4SignerAuth
from opensearchpy.helpers import bulk

OPENSEARCH_ENDPOINT = os.environ['OPENSEARCH_ENDPOINT'].replace("https://", "")
S3BUCKET = os.environ['S3BUCKET']
S3BUCKET_KEY = os.environ['S3BUCKET_KEY']
OPENSEARCH_INDEX = "faqs"
REGION = "ap-northeast-1"
s3_client = boto3.client("s3")

def download_json_from_s3():
    print(f"[info] Start Downloading JSON from s3://{S3BUCKET}/{S3BUCKET_KEY}")
    local_path = "/tmp/document.json"
    s3_client.download_file(S3BUCKET, S3BUCKET_KEY, local_path)
    print(f"[info] End Downloaded JSON to {local_path}")
    return local_path

def load_json(local_path):
    print(f"[info] Start load_json")
    with open(local_path, "r") as f:
        data = json.load(f)
    print(f"[info] End load_json")
    return data

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
        timeout = 30
    )

def index_documents_bulk(opensearch_client, documents):
    print(f"[info] Start Bulk Indexing {len(documents)} documents")

    actions = [
        {
            "_index": OPENSEARCH_INDEX,
            "_source": {"text": doc["text"], "embedding": doc["embedding"]}
        }
        for doc in documents
    ]

    success, failed = bulk(opensearch_client, actions)
    print(f"[info] Bulk Indexing Complete: Success = {success}, Failed = {failed}")

    return {"success": success, "failed": failed}

def lambda_handler(event, context):
    local_path = download_json_from_s3()
    documents = load_json(local_path)
    opensearch_client = connect_opensearch()
    response = index_documents_bulk(opensearch_client, documents)

    return {
        'statusCode': 200,
        'message': f"Indexed {response['success']} documents, Failed {response['failed']}"
    }
