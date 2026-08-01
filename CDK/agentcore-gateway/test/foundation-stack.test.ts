import * as cdk from 'aws-cdk-lib';
import { Match, Template } from 'aws-cdk-lib/assertions';
import { FoundationStack } from '../lib/foundation-stack';

/**
 * FoundationStack の期待仕様（TDD: 実装より先に定義）
 *
 * 検証方法: スタックを合成(synth)して得られる CloudFormation テンプレートに対する
 * fine-grained assertion。実際の AWS には一切アクセスしない。
 */
describe('FoundationStack', () => {
  let template: Template;

  beforeAll(() => {
    const app = new cdk.App();
    // env.account を固定するとドメインプレフィックスがトークンではなく
    // 具体値で合成されるため、文字列として検証できる
    const stack = new FoundationStack(app, 'TestFoundationStack', {
      env: { account: '111111111111', region: 'ap-northeast-1' },
    });
    template = Template.fromStack(stack);
  });

  test('ユーザープールは1つ。検証用のため削除ポリシーは DESTROY(要件1)', () => {
    template.resourceCountIs('AWS::Cognito::UserPool', 1);
    template.hasResource('AWS::Cognito::UserPool', {
      DeletionPolicy: 'Delete',
      UpdateReplacePolicy: 'Delete',
    });
  });

  test('M2M 専用のためセルフサインアップは閉じる', () => {
    template.hasResourceProperties('AWS::Cognito::UserPool', {
      AdminCreateUserConfig: { AllowAdminCreateUserOnly: true },
    });
  });

  test('ユーザープールドメインが存在する(要件2: W1 のドメイン作成漏れ再発防止)', () => {
    template.resourceCountIs('AWS::Cognito::UserPoolDomain', 1);
    template.hasResourceProperties('AWS::Cognito::UserPoolDomain', {
      // プレフィックスはアカウントIDでリージョン内一意性を担保する設計
      Domain: 'agentcore-111111111111',
    });
  });

  test('リソースサーバー: identifier=agentcore / scope=read (要件3)', () => {
    template.hasResourceProperties('AWS::Cognito::UserPoolResourceServer', {
      Identifier: 'agentcore',
      Scopes: [
        { ScopeName: 'read', ScopeDescription: Match.anyValue() },
      ],
    });
  });

  test('M2M クライアント: client_credentials 専用でシークレット生成あり (要件4)', () => {
    template.hasResourceProperties('AWS::Cognito::UserPoolClient', {
      AllowedOAuthFlows: ['client_credentials'],
      AllowedOAuthFlowsUserPoolClient: true,
      GenerateSecret: true,
      // スコープの実値は「リソースサーバーのRefに '/read' を連結」というトークンに
      // 合成されるため、ここでは「付与スコープがちょうど1つ」であることを検証する
      // (identifier と scope 名の正しさはリソースサーバー側のテストで担保済み)
      AllowedOAuthScopes: [Match.anyValue()],
    });
  });

  test('トークン取得の動作確認に使う値が出力されている (要件5)', () => {
    template.hasOutput('UserPoolId', {});
    template.hasOutput('ClientId', {});
    template.hasOutput('TokenEndpoint', {});
    template.hasOutput('Scope', {});
  });
});
