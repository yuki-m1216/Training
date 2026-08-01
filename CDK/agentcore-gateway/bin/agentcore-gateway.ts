#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { AgentPlatformStack } from '../lib/agent-platform-stack';
import { FoundationStack } from '../lib/foundation-stack';
import { ObservabilityStack } from '../lib/observability-stack';

const app = new cdk.App();

const env = {
  // アカウントIDはリポジトリにコミットせず、実行時の認証情報(プロファイル)から解決する
  account: process.env.CDK_DEFAULT_ACCOUNT,
  // AgentCore ハンズオンの利用リージョンに合わせて東京に固定(環境非依存にしない意図の表明)
  region: 'ap-northeast-1',
};

const foundation = new FoundationStack(app, 'FoundationStack', { env });

// Foundation のコンストラクト参照を props で渡す(CFN 上は Export/Import になる)
new AgentPlatformStack(app, 'AgentPlatformStack', {
  env,
  userPool: foundation.userPool,
  userPoolClient: foundation.userPoolClient,
});

// アカウント×リージョンレベルの設定のため、他スタックへの依存なし(単独デプロイ可)
new ObservabilityStack(app, 'ObservabilityStack', { env });
