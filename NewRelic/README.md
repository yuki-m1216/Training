# 環境変数設定

## provider 内の環境変数設定

https://registry.terraform.io/providers/newrelic/newrelic/latest/docs/guides/provider_configuration#configuration-via-environment-variables

### Linux

```sh
export NEW_RELIC_ACCOUNT_ID="<your New Relic Account ID>"
export NEW_RELIC_API_KEY="<your New Relic User API key>"
```

### Windows

```powershell
$Env:NEW_RELIC_ACCOUNT_ID="<your New Relic Account ID>"
$Env:NEW_RELIC_API_KEY="<your New Relic User API key>"
```

## terraform 実行時の環境変数設定

https://developer.hashicorp.com/terraform/language/v1.3.x/values/variables#environment-variables

### Linux

```sh
export TF_VAR_NEW_RELIC_ACCOUNT_ID="<your New Relic Account ID>"
```

### Windows

```powershell
$Env:TF_VAR_NEW_RELIC_ACCOUNT_ID="<your New Relic Account ID>"
```
