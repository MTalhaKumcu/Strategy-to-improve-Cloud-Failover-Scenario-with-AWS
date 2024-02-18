data "template_file" "s3_policy" {
  template = file("${path.module}/aws-s3-static-website-policy.json")
  vars = {
    failover_bucket_name = aws_s3_bucket.s3_bucket_failover.id
  }
}

data "aws_caller_identity" "current" {}

data "archive_file" "lambdazip" {
  type        = "zip"
  output_path = "lambda_function_payload.zip"
  source_file = "${path.module}/lambda.py"

  depends_on = [
    local_file.config,
  ]
}

data "aws_ami" "nat_instance_ami" {
  most_recent = true
  owners      = ["301380864081"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }


  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat-*"]
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu*"]
  }
  filter {
    name   = "image-id"
    values = ["ami-0729e439b6769d6ab"]
  }
}

# Userdata will work with this ubuntu AMI. In case of AMI change, the userdata has to be adjusted.

data "aws_route53_zone" "selected" {
  name         = var.existing_hosted_zone
  private_zone = false
}
