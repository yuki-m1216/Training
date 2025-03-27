import boto3
import json
import os
from langchain_community.document_loaders import PyPDFLoader
from langchain.text_splitter import CharacterTextSplitter

S3BUCKET = os.environ['S3BUCKET']
S3BUCKET_KEY = os.environ['S3BUCKET_KEY']
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

def process_and_upload_text(text_docs):
    print(f"[info] Start Process and Upload Text")
    print(f"[info] Start embedding text")
    model_id = "amazon.titan-embed-text-v2:0"
    process_data = []

    for i, doc in enumerate(text_docs):
        embedding = invoke_bedrock_embedding(bedrock_client, model_id, doc.page_content, dimensions=512, normalize=True)
        process_data.append({"page": i + 1, "text": doc.page_content, "embedding": embedding})
    print(f"[info] End embedding text")

    json_content = json.dumps(process_data, ensure_ascii=False, indent=2)
    tmp_path = "/tmp/text-with-embedding.json"

    with open(tmp_path, "w", encoding="utf-8") as f:
        f.write(json_content)

    print(f"[info] Start Uploading JSON to s3://{S3BUCKET}/output/text-with-embedding.json")
    s3_client.upload_file(tmp_path, S3BUCKET, "output/text-with-embedding.json")
    print(f"[info] End Uploaded JSON to s3://{S3BUCKET}/output/text-with-embedding.json")
    print(f"[info] End Process and Upload Text")
    return "output/text-with-embedding.json"

def lambda_handler(event, context):
    local_path = download_pdf()
    text_docs = pdf_to_text(local_path)
    json_key = process_and_upload_text(text_docs)
    return {
        'statusCode': 200,
        'message': f"Uploaded text with embedding to s3://{S3BUCKET}/{json_key}"
   }