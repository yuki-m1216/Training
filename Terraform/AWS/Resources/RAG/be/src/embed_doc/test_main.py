import pytest
import json
import os
from unittest.mock import Mock, patch, MagicMock, mock_open
from main import (
    download_pdf,
    pdf_to_text,
    invoke_bedrock_embedding,
    process_and_upload_text,
    lambda_handler
)


@pytest.fixture
def mock_s3_client():
    """S3 クライアントのモック"""
    mock_client = Mock()
    return mock_client


@pytest.fixture
def mock_bedrock_client():
    """Bedrock クライアントのモック"""
    mock_client = Mock()
    return mock_client


@pytest.fixture
def sample_text_docs():
    """サンプルのテキストドキュメント"""
    mock_doc1 = Mock()
    mock_doc1.page_content = "AWS Lambda はサーバーレスコンピューティングサービスです。"
    
    mock_doc2 = Mock()
    mock_doc2.page_content = "AWS S3 はオブジェクトストレージサービスです。"
    
    return [mock_doc1, mock_doc2]


@pytest.fixture
def sample_embedding():
    """サンプルのembedding ベクトル"""
    return [0.1, 0.2, 0.3, 0.4, 0.5]


class TestDownloadPdf:
    """download_pdf 関数のテスト"""
    
    @patch.dict(os.environ, {
        'S3BUCKET': 'test-bucket',
        'S3BUCKET_KEY': 'test-document.pdf'
    })
    @patch('main.s3_client')
    def test_download_pdf_success(self, mock_s3_client):
        """正常にPDFをダウンロードできること"""
        # テスト実行
        result = download_pdf()
        
        # 検証
        assert result == "/tmp/document.pdf"
        mock_s3_client.download_file.assert_called_once_with(
            'test-bucket',
            'test-document.pdf',
            '/tmp/document.pdf'
        )
    
    @patch.dict(os.environ, {
        'S3BUCKET': 'test-bucket',
        'S3BUCKET_KEY': 'test-document.pdf'
    })
    @patch('main.s3_client')
    def test_download_pdf_s3_error(self, mock_s3_client):
        """S3ダウンロードエラーが発生した場合"""
        from botocore.exceptions import ClientError
        
        # S3エラーをシミュレート
        mock_s3_client.download_file.side_effect = ClientError(
            error_response={'Error': {'Code': 'NoSuchKey', 'Message': 'Key not found'}},
            operation_name='download_file'
        )
        
        # テスト実行（エラーが発生することを確認）
        with pytest.raises(ClientError):
            download_pdf()


class TestPdfToText:
    """pdf_to_text 関数のテスト"""
    
    @patch('main.PyPDFLoader')
    @patch('main.CharacterTextSplitter')
    def test_pdf_to_text_success(self, mock_splitter_class, mock_loader_class):
        """正常にPDFをテキストに変換できること"""
        # PyPDFLoaderのモック
        mock_loader = Mock()
        mock_loader_class.return_value = mock_loader
        
        # load_and_splitの戻り値（ページごとのドキュメント）
        mock_pages = [Mock(), Mock(), Mock()]
        mock_loader.load_and_split.return_value = mock_pages
        
        # CharacterTextSplitterのモック
        mock_splitter = Mock()
        mock_splitter_class.return_value = mock_splitter
        
        # split_documentsの戻り値（チャンクごとのドキュメント）
        mock_text_docs = [Mock(), Mock(), Mock(), Mock()]
        mock_splitter.split_documents.return_value = mock_text_docs
        
        # テスト実行
        result = pdf_to_text("/tmp/document.pdf")
        
        # 検証
        assert result == mock_text_docs
        mock_loader_class.assert_called_once_with("/tmp/document.pdf")
        mock_loader.load_and_split.assert_called_once()
        mock_splitter_class.assert_called_once_with(chunk_size=8192)
        mock_splitter.split_documents.assert_called_once_with(mock_pages)
    
    @patch('main.PyPDFLoader')
    def test_pdf_to_text_loader_error(self, mock_loader_class):
        """PDFローダーでエラーが発生した場合"""
        # PyPDFLoaderのエラーをシミュレート
        mock_loader_class.side_effect = Exception("PDF読み込みエラー")
        
        # テスト実行（エラーが発生することを確認）
        with pytest.raises(Exception, match="PDF読み込みエラー"):
            pdf_to_text("/tmp/document.pdf")


class TestInvokeBedrockEmbedding:
    """invoke_bedrock_embedding 関数のテスト"""
    
    def test_invoke_bedrock_embedding_success(self, mock_bedrock_client):
        """正常にembeddingを取得できること"""
        # モックの設定
        mock_response = {
            'body': Mock()
        }
        mock_response['body'].read.return_value = json.dumps({
            'embedding': [0.1, 0.2, 0.3, 0.4, 0.5]
        }).encode()
        mock_bedrock_client.invoke_model.return_value = mock_response
        
        # テスト実行
        result = invoke_bedrock_embedding(
            mock_bedrock_client,
            "amazon.titan-embed-text-v2:0",
            "テスト用のテキスト",
            dimensions=512,
            normalize=True
        )
        
        # 検証
        assert result == [0.1, 0.2, 0.3, 0.4, 0.5]
        mock_bedrock_client.invoke_model.assert_called_once()
        
        # 呼び出し引数の確認
        call_args = mock_bedrock_client.invoke_model.call_args
        assert call_args[1]['modelId'] == "amazon.titan-embed-text-v2:0"
        assert call_args[1]['contentType'] == "application/json"
        assert call_args[1]['accept'] == "application/json"
        
        # ボディの内容確認
        body_json = json.loads(call_args[1]['body'])
        assert body_json['inputText'] == "テスト用のテキスト"
        assert body_json['dimensions'] == 512
        assert body_json['normalize'] == True
    
    def test_invoke_bedrock_embedding_api_error(self, mock_bedrock_client):
        """Bedrock APIでエラーが発生した場合"""
        from botocore.exceptions import ClientError
        
        # Bedrock APIエラーをシミュレート
        mock_bedrock_client.invoke_model.side_effect = ClientError(
            error_response={'Error': {'Code': 'ValidationException', 'Message': 'Invalid model'}},
            operation_name='invoke_model'
        )
        
        # テスト実行（エラーが発生することを確認）
        with pytest.raises(ClientError):
            invoke_bedrock_embedding(
                mock_bedrock_client,
                "invalid-model-id",
                "テスト用のテキスト"
            )


class TestProcessAndUploadText:
    """process_and_upload_text 関数のテスト"""
    
    @patch('main.bedrock_client')
    @patch('main.s3_client')
    @patch('builtins.open', new_callable=mock_open)
    @patch('main.invoke_bedrock_embedding')
    @patch.dict(os.environ, {'S3BUCKET': 'test-bucket'})
    def test_process_and_upload_text_success(
        self,
        mock_invoke_bedrock,
        mock_file,
        mock_s3_client,
        mock_bedrock_client,
        sample_text_docs
    ):
        """正常にテキストを処理してアップロードできること"""
        # モックの設定
        mock_invoke_bedrock.side_effect = [
            [0.1, 0.2, 0.3, 0.4, 0.5],  # 1番目のドキュメント用embedding
            [0.6, 0.7, 0.8, 0.9, 1.0]   # 2番目のドキュメント用embedding
        ]
        
        # テスト実行
        result = process_and_upload_text(sample_text_docs)
        
        # 検証
        assert result == "output/text-with-embedding.json"
        
        # invoke_bedrock_embeddingが各ドキュメントに対して呼ばれたか確認
        assert mock_invoke_bedrock.call_count == 2
        mock_invoke_bedrock.assert_any_call(
            mock_bedrock_client,
            "amazon.titan-embed-text-v2:0",
            "AWS Lambda はサーバーレスコンピューティングサービスです。",
            dimensions=512,
            normalize=True
        )
        mock_invoke_bedrock.assert_any_call(
            mock_bedrock_client,
            "amazon.titan-embed-text-v2:0",
            "AWS S3 はオブジェクトストレージサービスです。",
            dimensions=512,
            normalize=True
        )
        
        # ファイル書き込みが呼ばれたか確認
        mock_file.assert_called_once_with("/tmp/text-with-embedding.json", "w", encoding="utf-8")
        
        # S3アップロードが呼ばれたか確認
        mock_s3_client.upload_file.assert_called_once_with(
            "/tmp/text-with-embedding.json",
            "test-bucket",
            "output/text-with-embedding.json"
        )
        
        # ファイルに書き込まれた内容の確認
        written_content = mock_file().write.call_args[0][0]
        written_data = json.loads(written_content)
        
        # データ構造の確認
        assert len(written_data) == 2
        assert written_data[0]['page'] == 1
        assert written_data[0]['text'] == "AWS Lambda はサーバーレスコンピューティングサービスです。"
        assert written_data[0]['embedding'] == [0.1, 0.2, 0.3, 0.4, 0.5]
        assert written_data[1]['page'] == 2
        assert written_data[1]['text'] == "AWS S3 はオブジェクトストレージサービスです。"
        assert written_data[1]['embedding'] == [0.6, 0.7, 0.8, 0.9, 1.0]
    
    @patch('main.bedrock_client')
    @patch('main.s3_client')
    @patch('main.invoke_bedrock_embedding')
    @patch.dict(os.environ, {'S3BUCKET': 'test-bucket'})
    def test_process_and_upload_text_s3_upload_error(
        self,
        mock_invoke_bedrock,
        mock_s3_client,
        mock_bedrock_client,
        sample_text_docs
    ):
        """S3アップロードでエラーが発生した場合"""
        from botocore.exceptions import ClientError
        
        # モックの設定
        mock_invoke_bedrock.return_value = [0.1, 0.2, 0.3, 0.4, 0.5]
        
        # S3アップロードエラーをシミュレート
        mock_s3_client.upload_file.side_effect = ClientError(
            error_response={'Error': {'Code': 'AccessDenied', 'Message': 'Access denied'}},
            operation_name='upload_file'
        )
        
        # ファイル書き込みをモック（実際にファイルを作成しない）
        with patch('builtins.open', mock_open()):
            # テスト実行（エラーが発生することを確認）
            with pytest.raises(ClientError):
                process_and_upload_text(sample_text_docs)


class TestLambdaHandler:
    """lambda_handler 関数のテスト"""
    
    @patch('main.process_and_upload_text')
    @patch('main.pdf_to_text')
    @patch('main.download_pdf')
    @patch.dict(os.environ, {'S3BUCKET': 'test-bucket'})
    def test_lambda_handler_success(
        self,
        mock_download_pdf,
        mock_pdf_to_text,
        mock_process_and_upload_text
    ):
        """正常にLambda関数が実行されること"""
        # モックの設定
        mock_download_pdf.return_value = "/tmp/document.pdf"
        mock_pdf_to_text.return_value = [Mock(), Mock()]  # サンプルドキュメント
        mock_process_and_upload_text.return_value = "output/text-with-embedding.json"
        
        # テスト実行
        result = lambda_handler({}, {})
        
        # 検証
        assert result['statusCode'] == 200
        assert result['message'] == "Uploaded text with embedding to s3://test-bucket/output/text-with-embedding.json"
        
        # 各関数が正しい順序で呼ばれたか確認
        mock_download_pdf.assert_called_once()
        mock_pdf_to_text.assert_called_once_with("/tmp/document.pdf")
        mock_process_and_upload_text.assert_called_once()
    
    @patch('main.download_pdf')
    def test_lambda_handler_download_error(self, mock_download_pdf):
        """PDFダウンロードでエラーが発生した場合"""
        from botocore.exceptions import ClientError
        
        # ダウンロードエラーをシミュレート
        mock_download_pdf.side_effect = ClientError(
            error_response={'Error': {'Code': 'NoSuchKey', 'Message': 'Key not found'}},
            operation_name='download_file'
        )
        
        # テスト実行（エラーが発生することを確認）
        with pytest.raises(ClientError):
            lambda_handler({}, {})
    
    @patch('main.process_and_upload_text')
    @patch('main.pdf_to_text')
    @patch('main.download_pdf')
    def test_lambda_handler_pdf_processing_error(
        self,
        mock_download_pdf,
        mock_pdf_to_text,
        mock_process_and_upload_text
    ):
        """PDF処理でエラーが発生した場合"""
        # モックの設定
        mock_download_pdf.return_value = "/tmp/document.pdf"
        mock_pdf_to_text.side_effect = Exception("PDF処理エラー")
        
        # テスト実行（エラーが発生することを確認）
        with pytest.raises(Exception, match="PDF処理エラー"):
            lambda_handler({}, {})


class TestIntegration:
    """統合テスト"""
    
    @patch.dict(os.environ, {
        'S3BUCKET': 'test-bucket',
        'S3BUCKET_KEY': 'test-document.pdf'
    })
    @patch('main.s3_client')
    @patch('main.bedrock_client')
    @patch('main.PyPDFLoader')
    @patch('main.CharacterTextSplitter')
    @patch('builtins.open', new_callable=mock_open)
    def test_full_pipeline_mock(
        self,
        mock_file,
        mock_splitter_class,
        mock_loader_class,
        mock_bedrock_client,
        mock_s3_client
    ):
        """全体的なパイプラインのモックテスト"""
        # PyPDFLoaderのモック
        mock_loader = Mock()
        mock_loader_class.return_value = mock_loader
        
        # ページデータのモック
        mock_page = Mock()
        mock_page.page_content = "AWS サービスについての説明文書です。"
        mock_loader.load_and_split.return_value = [mock_page]
        
        # TextSplitterのモック
        mock_splitter = Mock()
        mock_splitter_class.return_value = mock_splitter
        
        # 分割されたドキュメントのモック
        mock_text_doc = Mock()
        mock_text_doc.page_content = "AWS サービスについての説明文書です。"
        mock_splitter.split_documents.return_value = [mock_text_doc]
        
        # Bedrock embeddingのモック
        mock_bedrock_response = {'body': Mock()}
        mock_bedrock_response['body'].read.return_value = json.dumps({
            'embedding': [0.1, 0.2, 0.3, 0.4, 0.5]
        }).encode()
        mock_bedrock_client.invoke_model.return_value = mock_bedrock_response
        
        # テスト実行
        result = lambda_handler({}, {})
        
        # 検証
        assert result['statusCode'] == 200
        assert 'Uploaded text with embedding to s3://test-bucket/output/text-with-embedding.json' in result['message']
        
        # 各コンポーネントが正しく呼ばれたか確認
        mock_s3_client.download_file.assert_called_once()
        mock_loader_class.assert_called_once_with("/tmp/document.pdf")
        mock_splitter_class.assert_called_once_with(chunk_size=8192)
        mock_bedrock_client.invoke_model.assert_called_once()
        mock_s3_client.upload_file.assert_called_once()