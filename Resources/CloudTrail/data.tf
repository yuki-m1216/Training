data "aws_caller_identity" "current" {}

data "template_file" "policy" {
  template = file("./Policy.json.tpl")

  vars = {
    account_id = data.aws_caller_identity.current.account_id
  }
}
