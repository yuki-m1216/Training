import * as cdk from 'aws-cdk-lib';
import { Match, Template } from 'aws-cdk-lib/assertions';
import { ObservabilityStack } from '../lib/observability-stack';

/**
 * ObservabilityStack の期待仕様(TDD: 実装より先に定義)
 *
 * Transaction Search 有効化 = 「受ける側の許可(Logs リソースポリシー)」と
 * 「送る側の設定(TransactionSearchConfig)」の2点セット + 順序保証。
 * 公式の有効化手順(ポリシー → 送信先切替)に対応する。
 */
describe('ObservabilityStack', () => {
  let template: Template;

  beforeAll(() => {
    const app = new cdk.App();
    // アカウント/リージョンを固定すると ARN が具体値で合成され、
    // PolicyDocument を文字列として検証できる(Foundation のテストと同じ理屈)
    const stack = new ObservabilityStack(app, 'TestObservabilityStack', {
      env: { account: '111111111111', region: 'ap-northeast-1' },
    });
    template = Template.fromStack(stack);
  });

  test('受ける側: X-Ray に aws/spans への書き込みを許可するリソースポリシー (要件1)', () => {
    template.resourceCountIs('AWS::Logs::ResourcePolicy', 1);
    template.hasResourceProperties('AWS::Logs::ResourcePolicy', Match.objectLike({
      // PolicyDocument は JSON 文字列として合成されるため serializedJson で復元して照合
      PolicyDocument: Match.serializedJson(Match.objectLike({
        Statement: Match.arrayWith([
          Match.objectLike({
            Effect: 'Allow',
            Principal: { Service: 'xray.amazonaws.com' },
            Action: 'logs:PutLogEvents',
            // 公式手順が示す2つのロググループ(スパン本体と Application Signals データ)
            Resource: Match.arrayWith([
              Match.stringLikeRegexp('log-group:aws/spans'),
              Match.stringLikeRegexp('log-group:/aws/application-signals/data'),
            ]),
            // 混同代理(confused deputy)対策: 自アカウントの X-Ray 起点に限定
            Condition: Match.objectLike({
              StringEquals: { 'aws:SourceAccount': '111111111111' },
              ArnLike: {
                'aws:SourceArn': Match.stringLikeRegexp(
                  'arn:aws:xray:ap-northeast-1:111111111111',
                ),
              },
            }),
          }),
        ]),
      })),
    }));
  });

  test('送る側: TransactionSearchConfig で indexingPercentage=100 (要件2: 検証用の全量インデックス)', () => {
    template.resourceCountIs('AWS::XRay::TransactionSearchConfig', 1);
    template.hasResourceProperties('AWS::XRay::TransactionSearchConfig', {
      IndexingPercentage: 100,
    });
  });

  test('順序: 許可(ポリシー)が先、スイッチ(設定)が後 (DependsOn で保証)', () => {
    template.hasResource('AWS::XRay::TransactionSearchConfig', Match.objectLike({
      DependsOn: [Match.stringLikeRegexp('XRayAccessPolicy')],
    }));
  });
});
