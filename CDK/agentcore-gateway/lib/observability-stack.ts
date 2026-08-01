import * as cdk from 'aws-cdk-lib';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as xray from 'aws-cdk-lib/aws-xray';
import { Construct } from 'constructs';

/**
 * 可観測性スタック(3スタック分割の3つ目)。
 * Transaction Search の有効化 = アカウント×リージョンレベルの設定であり、
 * アプリ(Foundation/Platform)への依存が無いため props も受け取らない。
 */
export class ObservabilityStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // 本スタックは下記の理由で ARN のパーティションを 'arn:aws:' に直書きしている。
    // 非標準パーティション(aws-cn / aws-us-gov / iso系)のリージョンで synth すると
    // 誤った ARN のポリシーが作られるため、その場合は synth 時点で失敗させる
    if (cdk.Token.isUnresolved(this.region)) {
      throw new Error(
        'ObservabilityStack は env.region の明示が必要です(ARN パーティション判定のため)',
      );
    }
    if (/^(cn-|us-gov-|us-iso|eu-isoe-)/.test(this.region)) {
      throw new Error(
        `ObservabilityStack は標準 AWS パーティションのみ対応です(region: ${this.region})`,
      );
    }

    // 【受ける側の許可】X-Ray サービスが自アカウントの CloudWatch Logs へ
    // スパンを書き込むことを許すリソースベースポリシー。文面は公式の
    // 有効化手順(Enable-TransactionSearch)が示すポリシーに合わせている。
    // ARN の 'arn:aws:' を直書きしているのは、formatArn だとパーティションが
    // トークンになり PolicyDocument が JSON 文字列で合成されなくなるため
    // (個人検証アカウントは標準パーティション固定なので問題ない)
    const xrayAccessPolicy = new logs.ResourcePolicy(this, 'XRayAccessPolicy', {
      resourcePolicyName: 'TransactionSearchXRayAccess',
      policyStatements: [
        new iam.PolicyStatement({
          sid: 'TransactionSearchXRayAccess',
          effect: iam.Effect.ALLOW,
          principals: [new iam.ServicePrincipal('xray.amazonaws.com')],
          actions: ['logs:PutLogEvents'],
          resources: [
            // スパン本体の格納先と Application Signals の分析データ格納先
            `arn:aws:logs:${this.region}:${this.account}:log-group:aws/spans:*`,
            `arn:aws:logs:${this.region}:${this.account}:log-group:/aws/application-signals/data:*`,
          ],
          conditions: {
            // 混同代理(confused deputy)対策: 「自アカウントの X-Ray が起点」のときだけ許可
            ArnLike: {
              'aws:SourceArn': `arn:aws:xray:${this.region}:${this.account}:*`,
            },
            StringEquals: { 'aws:SourceAccount': this.account },
          },
        }),
      ],
    });

    // 【送る側の設定】セグメント送信先を X-Ray 既定ストアから CloudWatch Logs へ
    // 切り替えるスイッチ。indexingPercentage=100 は検証用の全量インデックス
    // (本番は 1% 超過分が $0.75/100万スパンで課金されるため既定1%から調整する)
    const transactionSearch = new xray.CfnTransactionSearchConfig(
      this,
      'TransactionSearchConfig',
      { indexingPercentage: 100 },
    );

    // 「許可が先、スイッチが後」(公式手順 Step1→Step2 の順序)。
    // 依存を明示しないと CFn が並列作成し、書き込み許可の無い状態で
    // 有効化が走って失敗し得る
    transactionSearch.node.addDependency(xrayAccessPolicy);
  }
}
