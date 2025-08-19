import pytest
import json
import os
from unittest.mock import Mock, patch, mock_open
from main import (
    download_json_from_s3,
    load_json,
    connect_opensearch,
    index_documents_bulk,
    lambda_handler
)


@pytest.fixture
def mock_s3_client():
    """S3 クライアントのモック"""
    mock_client = Mock()
    return mock_client


@pytest.fixture
def mock_opensearch_client():
    """OpenSearch クライアントのモック"""
    mock_client = Mock()
    return mock_client


@pytest.fixture
def sample_documents():
    """サンプルのドキュメントデータ"""
    return [
        {
            "page": 1,
            "text": "AWS Lambda はサーバーレスコンピューティングサービスです。",
            "embedding": [0.1, 0.2, 0.3, 0.4, 0.5]
        },
        {
            "page": 2,
            "text": "AWS S3 はオブジェクトストレージサービスです。",
            "embedding": [0.6, 0.7, 0.8, 0.9, 1.0]
        },
        {
            "page": 3,
            "text": "AWS OpenSearch はマネージド検索・分析サービスです。",
            "embedding": [1.1, 1.2, 1.3, 1.4, 1.5]
        }
    ]


@pytest.fixture
def sample_json_content(sample_documents):
    """サンプルのJSONコンテンツ"""
    return json.dumps(sample_documents, ensure_ascii=False)


class TestDownloadJsonFromS3:
    """download_json_from_s3 関数のテスト"""
    
    @patch.dict(os.environ, {
        'S3BUCKET': 'test-bucket',
        'S3BUCKET_KEY': 'output/text-with-embedding.json'
    })
    @patch('main.s3_client')
    def test_download_json_from_s3_success(self, mock_s3_client):
        """正常にJSONファイルをS3からダウンロードできること"""
        # テスト実行
        result = download_json_from_s3()
        
        # 検証
        assert result == "/tmp/document.json"
        mock_s3_client.download_file.assert_called_once_with(
            'test-bucket',
            'output/text-with-embedding.json',
            '/tmp/document.json'
        )
    
    @patch.dict(os.environ, {
        'S3BUCKET': 'test-bucket',
        'S3BUCKET_KEY': 'output/text-with-embedding.json'
    })
    @patch('main.s3_client')
    def test_download_json_from_s3_error(self, mock_s3_client):
        """S3ダウンロードエラーが発生した場合"""
        from botocore.exceptions import ClientError
        
        # S3エラーをシミュレート
        mock_s3_client.download_file.side_effect = ClientError(
            error_response={'Error': {'Code': 'NoSuchKey', 'Message': 'The specified key does not exist.'}},
            operation_name='download_file'
        )
        
        # テスト実行（エラーが発生することを確認）
        with pytest.raises(ClientError):
            download_json_from_s3()
    
    @patch.dict(os.environ, {
        'S3BUCKET': 'test-bucket',
        'S3BUCKET_KEY': 'output/text-with-embedding.json'
    })
    @patch('main.s3_client')
    def test_download_json_from_s3_access_denied(self, mock_s3_client):
        """S3アクセス権限エラーが発生した場合"""
        from botocore.exceptions import ClientError
        
        # アクセス拒否エラーをシミュレート
        mock_s3_client.download_file.side_effect = ClientError(
            error_response={'Error': {'Code': 'AccessDenied', 'Message': 'Access Denied'}},
            operation_name='download_file'
        )
        
        # テスト実行（エラーが発生することを確認）
        with pytest.raises(ClientError):
            download_json_from_s3()


class TestLoadJson:
    """load_json 関数のテスト"""
    
    def test_load_json_success(self, sample_json_content, sample_documents):
        """正常にJSONファイルを読み込めること"""
        # mock_openを使用してファイル読み込みをモック
        with patch('builtins.open', mock_open(read_data=sample_json_content)):
            # テスト実行
            result = load_json("/tmp/document.json")
            
            # 検証
            assert result == sample_documents
            assert len(result) == 3
            assert result[0]['text'] == "AWS Lambda はサーバーレスコンピューティングサービスです。"
            assert result[0]['embedding'] == [0.1, 0.2, 0.3, 0.4, 0.5]
    
    def test_load_json_file_not_found(self):
        """ファイルが存在しない場合のエラーハンドリング"""
        # ファイルが存在しないエラーをシミュレート
        with patch('builtins.open', side_effect=FileNotFoundError("File not found")):
            # テスト実行（エラーが発生することを確認）
            with pytest.raises(FileNotFoundError):
                load_json("/tmp/nonexistent.json")
    
    def test_load_json_invalid_json(self):
        """無効なJSONの場合のエラーハンドリング"""
        # 無効なJSONコンテンツ
        invalid_json = "{ invalid json content"
        
        with patch('builtins.open', mock_open(read_data=invalid_json)):
            # テスト実行（JSONDecodeErrorが発生することを確認）
            with pytest.raises(json.JSONDecodeError):
                load_json("/tmp/document.json")
    
    def test_load_json_empty_file(self):
        """空のファイルの場合のエラーハンドリング"""
        # 空のファイル
        with patch('builtins.open', mock_open(read_data="")):
            # テスト実行（JSONDecodeErrorが発生することを確認）
            with pytest.raises(json.JSONDecodeError):
                load_json("/tmp/document.json")


class TestConnectOpensearch:
    """connect_opensearch 関数のテスト"""
    
    @patch.dict(os.environ, {'OPENSEARCH_ENDPOINT': 'https://test-endpoint.region.aoss.amazonaws.com'})
    @patch('main.boto3.Session')
    @patch('main.OpenSearch')
    def test_connect_opensearch_success(self, mock_opensearch_class, mock_session_class):
        """正常にOpenSearchに接続できること"""
        # boto3 Sessionのモック
        mock_session = Mock()
        mock_session_class.return_value = mock_session
        mock_credentials = Mock()
        mock_session.get_credentials.return_value = mock_credentials
        
        # OpenSearchクライアントのモック
        mock_opensearch_client = Mock()
        mock_opensearch_class.return_value = mock_opensearch_client
        
        # テスト実行
        result = connect_opensearch()
        
        # 検証
        assert result == mock_opensearch_client
        
        # OpenSearchクラスが正しい引数で呼ばれたか確認
        mock_opensearch_class.assert_called_once()
        call_args = mock_opensearch_class.call_args
        
        # 接続設定の確認
        assert call_args[1]['hosts'] == [{"host": "test-endpoint.region.aoss.amazonaws.com", "port": 443}]
        assert call_args[1]['use_ssl'] == True
        assert call_args[1]['verify_certs'] == True
        assert call_args[1]['timeout'] == 30
    
    @patch.dict(os.environ, {'OPENSEARCH_ENDPOINT': 'https://test-endpoint.region.aoss.amazonaws.com'})
    @patch('main.boto3.Session')
    def test_connect_opensearch_credentials_error(self, mock_session_class):
        """AWS認証情報の取得でエラーが発生した場合"""
        # boto3 Sessionのエラーをシミュレート
        mock_session = Mock()
        mock_session_class.return_value = mock_session
        mock_session.get_credentials.side_effect = Exception("認証情報の取得に失敗しました")
        
        # テスト実行（エラーが発生することを確認）
        with pytest.raises(Exception, match="認証情報の取得に失敗しました"):
            connect_opensearch()


class TestIndexDocumentsBulk:
    """index_documents_bulk 関数のテスト"""
    
    def test_index_documents_bulk_success(self, mock_opensearch_client, sample_documents):
        """正常にドキュメントをバルクインデックスできること"""
        # opensearchpy.helpers.bulkのモック
        with patch('main.bulk') as mock_bulk:
            # bulk関数の戻り値を設定
            mock_bulk.return_value = (3, [])  # 成功3件、失敗0件
            
            # テスト実行
            result = index_documents_bulk(mock_opensearch_client, sample_documents)
            
            # 検証
            assert result == {"success": 3, "failed": []}
            
            # bulk関数が正しく呼ばれたか確認
            mock_bulk.assert_called_once()
            call_args = mock_bulk.call_args
            assert call_args[0][0] == mock_opensearch_client  # 第1引数：OpenSearchクライアント
            
            # アクションデータの確認
            actions = call_args[0][1]  # 第2引数：アクションリスト
            assert len(actions) == 3
            
            # 1番目のアクション確認
            assert actions[0]['_index'] == 'faqs'
            assert actions[0]['_source']['text'] == "AWS Lambda はサーバーレスコンピューティングサービスです。"
            assert actions[0]['_source']['embedding'] == [0.1, 0.2, 0.3, 0.4, 0.5]
            
            # 2番目のアクション確認
            assert actions[1]['_index'] == 'faqs'
            assert actions[1]['_source']['text'] == "AWS S3 はオブジェクトストレージサービスです。"
            assert actions[1]['_source']['embedding'] == [0.6, 0.7, 0.8, 0.9, 1.0]
    
    def test_index_documents_bulk_partial_failure(self, mock_opensearch_client, sample_documents):
        """一部のドキュメントでインデックスが失敗した場合"""
        with patch('main.bulk') as mock_bulk:
            # 成功2件、失敗1件
            failed_docs = [{"index": {"_id": "3", "status": 400, "error": {"reason": "Invalid document"}}}]
            mock_bulk.return_value = (2, failed_docs)
            
            # テスト実行
            result = index_documents_bulk(mock_opensearch_client, sample_documents)
            
            # 検証
            assert result == {"success": 2, "failed": failed_docs}
    
    def test_index_documents_bulk_empty_documents(self, mock_opensearch_client):
        """空のドキュメントリストの場合"""
        with patch('main.bulk') as mock_bulk:
            mock_bulk.return_value = (0, [])
            
            # テスト実行
            result = index_documents_bulk(mock_opensearch_client, [])
            
            # 検証
            assert result == {"success": 0, "failed": []}
            
            # bulk関数が呼ばれたか確認
            mock_bulk.assert_called_once()
            call_args = mock_bulk.call_args
            actions = call_args[0][1]
            assert len(actions) == 0
    
    def test_index_documents_bulk_opensearch_error(self, mock_opensearch_client, sample_documents):
        """OpenSearchでエラーが発生した場合"""
        from opensearchpy.exceptions import OpenSearchException
        
        with patch('main.bulk') as mock_bulk:
            # OpenSearchエラーをシミュレート
            mock_bulk.side_effect = OpenSearchException("OpenSearch connection failed")
            
            # テスト実行（エラーが発生することを確認）
            with pytest.raises(OpenSearchException):
                index_documents_bulk(mock_opensearch_client, sample_documents)


class TestLambdaHandler:
    """lambda_handler 関数のテスト"""
    
    @patch('main.index_documents_bulk')
    @patch('main.connect_opensearch')
    @patch('main.load_json')
    @patch('main.download_json_from_s3')
    def test_lambda_handler_success(
        self,
        mock_download_json,
        mock_load_json,
        mock_connect_opensearch,
        mock_index_documents_bulk,
        sample_documents
    ):
        """正常にLambda関数が実行されること"""
        # モックの設定
        mock_download_json.return_value = "/tmp/document.json"
        mock_load_json.return_value = sample_documents
        mock_opensearch_client = Mock()
        mock_connect_opensearch.return_value = mock_opensearch_client
        mock_index_documents_bulk.return_value = {"success": 3, "failed": 0}
        
        # テスト実行
        result = lambda_handler({}, {})
        
        # 検証
        assert result['statusCode'] == 200
        assert result['message'] == "Indexed 3 documents, Failed 0"
        
        # 各関数が正しい順序で呼ばれたか確認
        mock_download_json.assert_called_once()
        mock_load_json.assert_called_once_with("/tmp/document.json")
        mock_connect_opensearch.assert_called_once()
        mock_index_documents_bulk.assert_called_once_with(mock_opensearch_client, sample_documents)
    
    @patch('main.index_documents_bulk')
    @patch('main.connect_opensearch')
    @patch('main.load_json')
    @patch('main.download_json_from_s3')
    def test_lambda_handler_partial_success(
        self,
        mock_download_json,
        mock_load_json,
        mock_connect_opensearch,
        mock_index_documents_bulk,
        sample_documents
    ):
        """一部のドキュメントでインデックスが失敗した場合"""
        # モックの設定
        mock_download_json.return_value = "/tmp/document.json"
        mock_load_json.return_value = sample_documents
        mock_opensearch_client = Mock()
        mock_connect_opensearch.return_value = mock_opensearch_client
        mock_index_documents_bulk.return_value = {"success": 2, "failed": 1}
        
        # テスト実行
        result = lambda_handler({}, {})
        
        # 検証
        assert result['statusCode'] == 200
        assert result['message'] == "Indexed 2 documents, Failed 1"
    
    @patch('main.download_json_from_s3')
    def test_lambda_handler_s3_download_error(self, mock_download_json):
        """S3ダウンロードでエラーが発生した場合"""
        from botocore.exceptions import ClientError
        
        # S3エラーをシミュレート
        mock_download_json.side_effect = ClientError(
            error_response={'Error': {'Code': 'NoSuchKey', 'Message': 'Key not found'}},
            operation_name='download_file'
        )
        
        # テスト実行（エラーが発生することを確認）
        with pytest.raises(ClientError):
            lambda_handler({}, {})
    
    @patch('main.load_json')
    @patch('main.download_json_from_s3')
    def test_lambda_handler_json_load_error(self, mock_download_json, mock_load_json):
        """JSON読み込みでエラーが発生した場合"""
        # モックの設定
        mock_download_json.return_value = "/tmp/document.json"
        mock_load_json.side_effect = json.JSONDecodeError("Invalid JSON", "", 0)
        
        # テスト実行（エラーが発生することを確認）
        with pytest.raises(json.JSONDecodeError):
            lambda_handler({}, {})
    
    @patch('main.connect_opensearch')
    @patch('main.load_json')
    @patch('main.download_json_from_s3')
    def test_lambda_handler_opensearch_connection_error(
        self,
        mock_download_json,  
        mock_load_json,
        mock_connect_opensearch,
        sample_documents
    ):
        """OpenSearch接続でエラーが発生した場合"""
        # モックの設定
        mock_download_json.return_value = "/tmp/document.json"
        mock_load_json.return_value = sample_documents
        mock_connect_opensearch.side_effect = Exception("OpenSearch connection failed")
        
        # テスト実行（エラーが発生することを確認）
        with pytest.raises(Exception, match="OpenSearch connection failed"):
            lambda_handler({}, {})


class TestIntegration:
    """統合テスト"""
    
    @patch.dict(os.environ, {
        'OPENSEARCH_ENDPOINT': 'https://test-endpoint.region.aoss.amazonaws.com',
        'S3BUCKET': 'test-bucket',
        'S3BUCKET_KEY': 'output/text-with-embedding.json'
    })
    @patch('main.s3_client')
    @patch('main.boto3.Session')
    @patch('main.OpenSearch')
    @patch('main.bulk')
    def test_full_pipeline_mock(
        self,
        mock_bulk,
        mock_opensearch_class,
        mock_session_class,
        mock_s3_client,
        sample_documents,
        sample_json_content
    ):
        """全体的なパイプラインのモックテスト"""
        # S3クライアントのモック設定（ダウンロードは成功させる）
        # 実際のファイル内容はmock_openで制御
        
        # boto3 Sessionのモック
        mock_session = Mock()
        mock_session_class.return_value = mock_session
        mock_credentials = Mock()
        mock_session.get_credentials.return_value = mock_credentials
        
        # OpenSearchクライアントのモック
        mock_opensearch_client = Mock()
        mock_opensearch_class.return_value = mock_opensearch_client
        
        # bulk indexingのモック
        mock_bulk.return_value = (3, [])  # 成功3件、失敗0件
        
        # ファイル読み込みのモック
        with patch('builtins.open', mock_open(read_data=sample_json_content)):
            # テスト実行
            result = lambda_handler({}, {})
        
        # 検証
        assert result['statusCode'] == 200
        assert result['message'] == "Indexed 3 documents, Failed []"
        
        # 各コンポーネントが正しく呼ばれたか確認
        mock_s3_client.download_file.assert_called_once_with(
            'test-bucket',
            'output/text-with-embedding.json',
            '/tmp/document.json'
        )
        mock_opensearch_class.assert_called_once()
        mock_bulk.assert_called_once()
        
        # bulkインデックスのアクションデータ確認
        call_args = mock_bulk.call_args
        actions = call_args[0][1]
        assert len(actions) == 3
        assert actions[0]['_index'] == 'faqs'
        assert actions[0]['_source']['text'] == "AWS Lambda はサーバーレスコンピューティングサービスです。"