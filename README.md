# Terraform
Terraform practice repository  

## windows  
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
>https://www.terraform.io/docs/backends/types/s3.html

- tfstateファイルを管理するS3はAWS CLIで作成する  

## Linux    
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

## windows   
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
