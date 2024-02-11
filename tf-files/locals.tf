locals {
  alb_origin_id = "myALBOrigin"
}

locals {
  account_id = data.aws_caller_identity.current.account_id
}