# Terraform

Terraform practice repository  

## Linux

```shell
export TF_VAR_access_key="AKIAXXXXXXXXXXXXXXXXXX"
export TF_VAR_secret_key="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

or

```shell
export AWS_PROFILE="your profile"
```

## Windows  

```PowerShell
PS C:> $Env:TF_VAR_access_key="AKIAXXXXXXXXXXXXXXXXXX"  
PS C:> $Env:TF_VAR_secret_key="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

or

```PowerShell
PS C:> $Env:AWS_PROFILE="your profile"  
```

## tfstate  

>Terraform is an administrative tool that manages your infrastructure, and so ideally the infrastructure that is used by Terraform should exist outside of the infrastructure that Terraform manages.
><https://www.terraform.io/docs/backends/types/s3.html>

- tfstateファイルを管理するS3はAWS CLIで作成する  

### Linux

```shell
$ BUCKET_NAME=s3-terraform-state-y-mitsuyama
$ REGION=ap-northeast-1
$ aws --region $REGION s3api create-bucket \
  --create-bucket-configuration LocationConstraint=$REGION \
  --bucket $BUCKET_NAME
$ aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled
```

### Windows

```Powershell
PS C:> $BUCKET_NAME = "s3-terraform-state-y-mitsuyama"
PS C:> $REGION = "ap-northeast-1"

PS C:> aws --region $REGION s3api create-bucket `
  --create-bucket-configuration LocationConstraint=$REGION `
  --bucket $BUCKET_NAME

PS C:> aws s3api put-bucket-versioning `
  --bucket $BUCKET_NAME `
  --versioning-configuration Status=Enabled
```

### statelock

- DynamoDBを利用してstateロック機能を追加する場合

### Linux

```shell
$ aws dynamodb create-table \
      --table-name terrform-state \
      --attribute-definitions \
          AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
      --table-class STANDARD \
      --deletion-protection-enabled \
      --tags \
          Key=Name,Value=terrform-state
```

### Windows

```Powershell
PS C:> aws dynamodb create-table `
    --table-name terrform-state `
    --attribute-definitions `
        AttributeName=LockID,AttributeType=S `
    --key-schema AttributeName=LockID,KeyType=HASH `
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 `
    --table-class STANDARD `
    --deletion-protection-enabled `
    --tags `
        Key=Name,Value=terrform-state
```
