import pytest
import json
import os
from unittest.mock import Mock, patch, MagicMock
from main import (
    invoke_bedrock_embedding,
    connect_opensearch,
    search_opensearch,
    ask_claude,
    lambda_handler
)


@pytest.fixture
def mock_bedrock_client():
    """Bedrock クライアントのモック"""
    mock_client = Mock()
    return mock_client


@pytest.fixture
def mock_opensearch_client():
    """OpenSearch クライアントのモック"""
    mock_client = Mock()
    return mock_client


@pytest.fixture
def sample_event():
    """サンプルのLambdaイベント"""
    return {
        "httpMethod": "POST",
        "body": json.dumps({"question": "AWS Lambda とは何ですか？"})
    }


@pytest.fixture
def options_event():
    """CORS preflightリクエストのイベント"""
    return {"httpMethod": "OPTIONS"}


@pytest.fixture
def invalid_event():
    """無効なイベント（質問なし）"""
    return {
        "httpMethod": "POST",
        "body": json.dumps({})
    }


class TestInvokeBedrock:
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
            "テスト質問",
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


@pytest.mark.skip(reason="環境変数が必要なためスキップ")
class TestConnectOpensearch:
    """connect_opensearch 関数のテスト"""
    
    @patch.dict(os.environ, {'OPENSEARCH_ENDPOINT': 'https://test-endpoint.region.aoss.amazonaws.com'})
    @patch('main.boto3.Session')
    @patch('main.OpenSearch')
    def test_connect_opensearch_success(self, mock_opensearch, mock_session):
        """正常にOpenSearchに接続できること"""
        # モックの設定
        mock_credentials = Mock()
        mock_session.return_value.get_credentials.return_value = mock_credentials
        mock_opensearch_instance = Mock()
        mock_opensearch.return_value = mock_opensearch_instance
        
        # テスト実行
        result = connect_opensearch()
        
        # 検証
        assert result == mock_opensearch_instance
        mock_opensearch.assert_called_once()


class TestSearchOpensearch:
    """search_opensearch 関数のテスト"""
    
    @patch('main.connect_opensearch')
    def test_search_opensearch_success(self, mock_connect):
        """正常に検索結果を取得できること"""
        # モックの設定
        mock_client = Mock()
        mock_connect.return_value = mock_client
        
        mock_response = {
            "hits": {
                "hits": [
                    {"_source": {"text": "回答1の内容"}},
                    {"_source": {"text": "回答2の内容"}},
                    {"_source": {"text": "回答3の内容"}}
                ]
            }
        }
        mock_client.search.return_value = mock_response
        
        # テスト実行
        embedding = [0.1, 0.2, 0.3, 0.4, 0.5]
        result = search_opensearch(embedding, top_k=3)
        
        # 検証
        expected_texts = ["回答1の内容", "回答2の内容", "回答3の内容"]
        assert result == expected_texts
        
        # 検索クエリの確認
        call_args = mock_client.search.call_args
        query = call_args[1]['body']
        assert query['size'] == 3
        assert query['query']['knn']['embedding']['vector'] == embedding
        assert query['query']['knn']['embedding']['k'] == 3
    
    @patch('main.connect_opensearch')
    def test_search_opensearch_empty_results(self, mock_connect):
        """検索結果が空の場合"""
        # モックの設定
        mock_client = Mock()
        mock_connect.return_value = mock_client
        
        mock_response = {"hits": {"hits": []}}
        mock_client.search.return_value = mock_response
        
        # テスト実行
        embedding = [0.1, 0.2, 0.3, 0.4, 0.5]
        result = search_opensearch(embedding, top_k=5)
        
        # 検証
        assert result == []


class TestAskClaude:
    """ask_claude 関数のテスト"""
    
    def test_ask_claude_success(self, mock_bedrock_client):
        """正常にClaudeから回答を取得できること"""
        # モックの設定
        mock_response = {
            'body': Mock()
        }
        mock_response['body'].read.return_value = json.dumps({
            'content': [{'text': 'AWS Lambdaはサーバーレスコンピューティングサービスです。'}]
        }).encode()
        mock_bedrock_client.invoke_model.return_value = mock_response
        
        # テスト実行
        result = ask_claude(
            mock_bedrock_client,
            "AWS Lambda とは何ですか？",
            "AWS Lambda はサーバーレスコンピューティングサービスです。"
        )
        
        # 検証
        assert result == 'AWS Lambdaはサーバーレスコンピューティングサービスです。'
        mock_bedrock_client.invoke_model.assert_called_once()
        
        # 呼び出し引数の確認
        call_args = mock_bedrock_client.invoke_model.call_args
        assert call_args[1]['modelId'] == "apac.anthropic.claude-3-5-sonnet-20241022-v2:0"
        assert call_args[1]['contentType'] == "application/json"


class TestLambdaHandler:
    """lambda_handler 関数のテスト"""
    
    def test_lambda_handler_options_request(self, options_event):
        """OPTIONS リクエスト（CORS preflight）の処理"""
        result = lambda_handler(options_event, {})
        
        # 検証
        assert result['statusCode'] == 200
        assert result['headers']['Access-Control-Allow-Origin'] == "*"
        assert result['headers']['Access-Control-Allow-Methods'] == "POST, OPTIONS"
        assert result['headers']['Access-Control-Allow-Headers'] == "Content-Type"
        
        body = json.loads(result['body'])
        assert body['message'] == "CORS preflight OK"
    
    def test_lambda_handler_no_question(self, invalid_event):
        """質問が提供されない場合のエラーハンドリング"""
        result = lambda_handler(invalid_event, {})
        
        # 検証
        assert result['statusCode'] == 400
        body = json.loads(result['body'])
        assert 'error' in body
        assert body['error'] == "No question provided"
    
    @patch('main.bedrock_client')
    @patch('main.search_opensearch')
    @patch('main.invoke_bedrock_embedding')
    @patch('main.ask_claude')
    def test_lambda_handler_success(
        self,
        mock_ask_claude,
        mock_invoke_bedrock,
        mock_search_opensearch,
        mock_bedrock_client,
        sample_event
    ):
        """正常なリクエストの処理"""
        # モックの設定
        mock_invoke_bedrock.return_value = [0.1, 0.2, 0.3, 0.4, 0.5]
        mock_search_opensearch.return_value = ["検索結果1", "検索結果2"]
        mock_ask_claude.return_value = "AWS Lambdaはサーバーレスコンピューティングサービスです。"
        
        # テスト実行
        result = lambda_handler(sample_event, {})
        
        # 検証
        assert result['statusCode'] == 200
        assert result['headers']['Access-Control-Allow-Origin'] == "*"
        
        body = json.loads(result['body'])
        assert body['question'] == "AWS Lambda とは何ですか？"
        assert body['answer'] == "AWS Lambdaはサーバーレスコンピューティングサービスです。"
        
        # 各関数が正しく呼ばれていることを確認
        mock_invoke_bedrock.assert_called_once_with(
            mock_bedrock_client, "amazon.titan-embed-text-v2:0", "AWS Lambda とは何ですか？", 
            dimensions=512, normalize=True
        )
        mock_search_opensearch.assert_called_once_with([0.1, 0.2, 0.3, 0.4, 0.5], top_k=5)
        mock_ask_claude.assert_called_once_with(
            mock_bedrock_client, "AWS Lambda とは何ですか？", "検索結果1\n検索結果2"
        )
    
    @patch('main.bedrock_client')
    @patch('main.search_opensearch')
    @patch('main.invoke_bedrock_embedding')
    def test_lambda_handler_no_search_results(
        self,
        mock_invoke_bedrock,
        mock_search_opensearch,
        mock_bedrock_client,
        sample_event
    ):
        """検索結果が空の場合の処理"""
        # モックの設定
        mock_invoke_bedrock.return_value = [0.1, 0.2, 0.3, 0.4, 0.5]
        mock_search_opensearch.return_value = []
        
        # テスト実行
        result = lambda_handler(sample_event, {})
        
        # 検証
        assert result['statusCode'] == 200
        body = json.loads(result['body'])
        assert body['answer'] == "提供された情報には回答が見つかりませんでした"


class TestIntegration:
    """統合テスト"""
    
    @patch.dict(os.environ, {'OPENSEARCH_ENDPOINT': 'https://test-endpoint.region.aoss.amazonaws.com'})
    @patch('main.bedrock_client')
    @patch('main.connect_opensearch')
    def test_full_pipeline_mock(self, mock_connect, mock_bedrock_client):
        """全体的なパイプラインのモックテスト"""
        
        # Embedding APIのモック
        mock_embedding_response = {'body': Mock()}
        mock_embedding_response['body'].read.return_value = json.dumps({
            'embedding': [0.1, 0.2, 0.3, 0.4, 0.5]
        }).encode()
        
        # Claude APIのモック
        mock_claude_response = {'body': Mock()}
        mock_claude_response['body'].read.return_value = json.dumps({
            'content': [{'text': 'AWS Lambda はサーバーレスコンピューティングサービスです。'}]
        }).encode()
        
        # Bedrockの呼び出しを区別するためのside_effect
        def bedrock_side_effect(*args, **kwargs):
            if kwargs['modelId'] == "amazon.titan-embed-text-v2:0":
                return mock_embedding_response
            elif kwargs['modelId'] == "apac.anthropic.claude-3-5-sonnet-20241022-v2:0":
                return mock_claude_response
            
        mock_bedrock_client.invoke_model.side_effect = bedrock_side_effect
        
        # OpenSearchクライアントのモック
        mock_opensearch_client = Mock()
        mock_connect.return_value = mock_opensearch_client
        mock_opensearch_client.search.return_value = {
            "hits": {
                "hits": [
                    {"_source": {"text": "AWS Lambda の詳細な説明"}},
                    {"_source": {"text": "サーバーレスコンピューティングについて"}}
                ]
            }
        }
        
        # テストイベント
        event = {
            "httpMethod": "POST",
            "body": json.dumps({"question": "AWS Lambda とは何ですか？"})
        }
        
        # テスト実行
        result = lambda_handler(event, {})
        
        # 検証
        assert result['statusCode'] == 200
        body = json.loads(result['body'])
        assert 'question' in body
        assert 'answer' in body
        assert body['question'] == "AWS Lambda とは何ですか？"
        assert body['answer'] == 'AWS Lambda はサーバーレスコンピューティングサービスです。'