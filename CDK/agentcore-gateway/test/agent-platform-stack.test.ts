import * as cdk from 'aws-cdk-lib';
import { Match, Template } from 'aws-cdk-lib/assertions';
import { FoundationStack } from '../lib/foundation-stack';
import { AgentPlatformStack } from '../lib/agent-platform-stack';

/**
 * AgentPlatformStack の期待仕様(TDD: 実装より先に定義)
 *
 * FoundationStack からコンストラクト参照を props で受け取る設計のため、
 * テストでも実際に2スタックを同一 App に作って配線する。
 * Foundation 由来の値(プールID等)は Platform 側テンプレートでは
 * Fn::ImportValue トークンになるので、値そのものは Match.anyValue() で扱う。
 */
describe('AgentPlatformStack', () => {
  let template: Template;

  beforeAll(() => {
    const app = new cdk.App();
    const env = { account: '111111111111', region: 'ap-northeast-1' };
    const foundation = new FoundationStack(app, 'TestFoundationStack', { env });
    const stack = new AgentPlatformStack(app, 'TestAgentPlatformStack', {
      env,
      userPool: foundation.userPool,
      userPoolClient: foundation.userPoolClient,
    });
    template = Template.fromStack(stack);
  });

  test('Gateway は1つ。インバウンド認可は CUSTOM_JWT(usingCognito の変換結果) (要件2)', () => {
    template.resourceCountIs('AWS::BedrockAgentCore::Gateway', 1);
    template.hasResourceProperties('AWS::BedrockAgentCore::Gateway', Match.objectLike({
      AuthorizerType: 'CUSTOM_JWT',
      ProtocolType: 'MCP',
      AuthorizerConfiguration: Match.objectLike({
        CustomJwtAuthorizer: Match.objectLike({
          // 値は Foundation からの ImportValue を含むトークンのため形だけ検証。
          // 「クライアントがちょうど1つ許可されている」ことが仕様
          DiscoveryUrl: Match.anyValue(),
          AllowedClients: [Match.anyValue()],
        }),
      }),
    }));
  });

  test('exceptionLevel は DEBUG(壊し実験で既定との差を見るため) (要件3)', () => {
    template.hasResourceProperties('AWS::BedrockAgentCore::Gateway', Match.objectLike({
      ExceptionLevel: 'DEBUG',
    }));
  });

  test('Lambda ターゲットが1つ登録され、ツールは hello_world (要件4)', () => {
    template.resourceCountIs('AWS::BedrockAgentCore::GatewayTarget', 1);
    template.hasResourceProperties('AWS::BedrockAgentCore::GatewayTarget', Match.objectLike({
      Name: 'hello',
      TargetConfiguration: Match.objectLike({
        Mcp: Match.objectLike({
          Lambda: Match.objectLike({
            LambdaArn: Match.anyValue(),
            ToolSchema: Match.objectLike({
              InlinePayload: [
                Match.objectLike({
                  Name: 'hello_world',
                  Description: Match.anyValue(),
                  InputSchema: Match.anyValue(),
                }),
              ],
            }),
          }),
        }),
      }),
    }));
  });

  test('ツール用 Lambda はインラインコードの Python (要件1)', () => {
    template.hasResourceProperties('AWS::Lambda::Function', Match.objectLike({
      Runtime: 'python3.13',
      Handler: 'index.handler',
      // fromInline のコードは ZipFile プロパティとしてテンプレートに埋め込まれる
      Code: Match.objectLike({ ZipFile: Match.anyValue() }),
    }));
  });

  test('MCP エンドポイント URL が出力されている (要件5)', () => {
    template.hasOutput('GatewayUrl', {});
  });
});
