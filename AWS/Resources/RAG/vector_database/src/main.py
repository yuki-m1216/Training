import boto3
import json
import os
from opensearchpy import OpenSearch, RequestsHttpConnection, AWSV4SignerAuth
from opensearchpy.helpers import bulk
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
    print(f"[info] Start load_and_split")
    pages = loader.load_and_split()
    print(f"[info] End load_and_split")
    print(f"[info] Start split_documents")
    splitter = CharacterTextSplitter(chunk_size=8192)
    text_docs = splitter.split_documents(pages)
    print(f"[info] End split_documents")
    print(f"[info] End pdf_to_text")
    print(f"[info] Start Uploading text to s3://{S3BUCKET}/text.txt")
    # JSON 形式に変換（各ページをリストで保持）
    text_data = [{"page": i + 1, "content": doc.page_content} for i, doc in enumerate(text_docs)]
    json_content = json.dumps(text_data, ensure_ascii=False, indent=2)

    # 一時ファイルに書き込み
    tmp_path = "/tmp/text.json"
    with open(tmp_path, "w", encoding="utf-8") as f:
        f.write(json_content)

    # S3 にアップロード
    print(f"[info] Start Uploading JSON to s3://{S3BUCKET}/text.json")
    s3_client.upload_file(tmp_path, S3BUCKET, "text.json")
    print(f"[info] End Uploaded JSON to s3://{S3BUCKET}/text.json")

    print(f"[info] End pdf_to_text")
    return text_docs

def invoke_bedrock_embedding(client, model_id, input_text, dimensions=512, normalize=True):
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
    opensearch_client = connect_opensearch()

    results = []
    model_id = "amazon.titan-embed-text-v2:0"

# embed_pdf() で PDF をダウンロードしてテキスト化しチャンクサイズに分割後、チャンクごとにベクトル化して OpenSearch に投入
    local_path = download_pdf()
    text_docs = pdf_to_text(local_path)
    text_chunks = [doc.page_content for doc in text_docs]

    documents = []

    for chunk in text_chunks:
        embedding = invoke_bedrock_embedding(bedrock_client, model_id, chunk, dimensions=512, normalize=True)
        documents.append({"text": chunk, "embedding": embedding})

    response = index_documents_bulk(opensearch_client, documents)
    results.append(response)

    return {
        'statusCode': 200,
        'results': results
    }
