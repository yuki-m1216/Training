# SG
resource "aws_security_group" "sg" {
  name        = var.sg_name
  description = var.sg_description
  vpc_id      = var.sg_vpc_id
  tags = {
    Name = var.sg_name
  }




}

# SG Rule
resource "aws_security_group_rule" "sg_rule" {
  for_each                 = var.sg_rule
  security_group_id        = aws_security_group.sg.id
  type                     = each.value.type
  to_port                  = each.value.to_port
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  source_security_group_id = each.value.source_security_group_id
  cidr_blocks              = each.value.cidr_blocks
  description              = each.value.description
}

output "sg_id" {
  value = aws_security_group.sg.id
}
