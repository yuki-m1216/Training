data "terraform_remote_state" "mainvpc" {
  backend = "s3"
  config = {
    bucket = "s3-terraform-state-y-mitsuyama"
    key    = "MainVPC.tfstate"
    region = "ap-northeast-1"
  }
}