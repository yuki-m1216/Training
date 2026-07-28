#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { FoundationStack } from '../lib/foundation-stack';

const app = new cdk.App();

new FoundationStack(app, 'FoundationStack', {
  env: {
    // アカウントIDはリポジトリにコミットせず、実行時の認証情報(プロファイル)から解決する
    account: process.env.CDK_DEFAULT_ACCOUNT,
    // AgentCore ハンズオンの利用リージョンに合わせて東京に固定(環境非依存にしない意図の表明)
    region: 'ap-northeast-1',
  },
});
