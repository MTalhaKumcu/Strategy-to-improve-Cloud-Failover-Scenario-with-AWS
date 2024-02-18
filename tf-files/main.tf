terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.provider_region
  profile = "default"
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "${var.tag_name}_db_subnet_group"
  description = "Subnets available for the RDS DB Instance"
  subnet_ids = [
    aws_subnet.private_subnet[0].id,
    aws_subnet.private_subnet[1].id,
  ]
  tags = {
    Name = "${var.tag_name}_db_subnet_group"
  }
}

resource "aws_db_instance" "db_instance" {
  allocated_storage           = 20
  allow_major_version_upgrade = false
  backup_retention_period     = 0
  db_name                     = var.rds_db_name
  db_subnet_group_name        = aws_db_subnet_group.db_subnet_group.name
  delete_automated_backups    = true
  engine                      = "mysql"
  engine_version              = var.rds_db_engine_version
  instance_class              = var.rds_db_instance_class
  identifier                  = "${lower(var.tag_name)}-db-instance"
  username                    = var.db_username
  password                    = var.db_password
  maintenance_window          = "Mon:03:00-Mon:04:00"
  max_allocated_storage       = 30
  multi_az                    = false
  port                        = 3306
  # publicly_accessible = true
  skip_final_snapshot = true
  # storage_encrypted      = true
  vpc_security_group_ids = [aws_security_group.rds_sec_gr.id]
  tags = {
    Name = "${var.tag_name}_db_instance"
  }
}

resource "aws_s3_bucket" "s3_bucket_content" {
  bucket        = var.s3_bucket_content
  force_destroy = true

  tags = {
    Name = "${var.tag_name}-s3-bucket-content"
  }
}

resource "aws_s3_bucket_ownership_controls" "bucket_content_ownership" {
  bucket = aws_s3_bucket.s3_bucket_content.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_content_public_access_block" {
  bucket = aws_s3_bucket.s3_bucket_content.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "bucket_content_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.bucket_content_ownership,
    aws_s3_bucket_public_access_block.bucket_content_public_access_block,
  ]

  bucket = aws_s3_bucket.s3_bucket_content.id
  acl    = "public-read"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.s3_bucket_content.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_dynamodb_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "media/"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

resource "aws_s3_bucket" "s3_bucket_failover" {
  bucket        = var.domain_name
  force_destroy = true

  tags = {
    Name = "${var.tag_name}-s3-bucket-failover"
  }
}

resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket     = aws_s3_bucket.s3_bucket_failover.id
  policy     = data.template_file.s3_policy.rendered
  depends_on = [aws_s3_bucket_public_access_block.bucket_failover_public_access_block]
}

resource "aws_s3_bucket_ownership_controls" "bucket_failover_ownership" {
  bucket = aws_s3_bucket.s3_bucket_failover.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  depends_on = [aws_s3_bucket_public_access_block.bucket_failover_public_access_block]
}

resource "aws_s3_bucket_public_access_block" "bucket_failover_public_access_block" {
  bucket = aws_s3_bucket.s3_bucket_failover.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "bucket_failover_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.bucket_failover_ownership,
    aws_s3_bucket_public_access_block.bucket_failover_public_access_block,
  ]

  bucket = aws_s3_bucket.s3_bucket_failover.id
  acl    = "public-read"
}

resource "aws_s3_object" "object" {
  count  = length(var.files_to_upload)
  bucket = aws_s3_bucket.s3_bucket_failover.id
  key    = basename(var.files_to_upload[count.index])
  source = var.files_to_upload[count.index]
}

resource "aws_s3_bucket_website_configuration" "bucket_website_config" {
  bucket = aws_s3_bucket.s3_bucket_failover.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id   = "AllowExecutionFromS3Bucket"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.lambda_dynamodb_function.arn
  principal      = "s3.amazonaws.com"
  source_arn     = aws_s3_bucket.s3_bucket_content.arn
  source_account = local.account_id
}

resource "local_file" "config" {
  content  = templatefile("${path.module}/lambda.py", { dynamo-db-name = "${var.tag_name}-dynamodb-table" })
  filename = "${path.module}/lambda.py"
}

resource "aws_lambda_function" "lambda_dynamodb_function" {
  description   = "S3-dynamoDB lambda function"
  filename      = "lambda_function_payload.zip"
  function_name = "S3DynamoLambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.8"

  depends_on = [
    aws_dynamodb_table.dynamodb_table,
    data.archive_file.lambdazip
  ]
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.tag_name}-lambda-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        # Sid    = "",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  path = "/"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/job-function/NetworkAdministrator"
  ]

  inline_policy {
    name = "dynamodb"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Action = [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem"
          ],
          Effect   = "Allow",
          Resource = "arn:aws:dynamodb:*:*:*"
        },
      ]
    })
  }

  inline_policy {
    name = "s3"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:GetObjectVersion"
          ],
          Effect   = "Allow",
          Resource = "*"
        },
        {
          Action   = ["lambda:Invoke*"],
          Effect   = "Allow",
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_instance" "nat_instance" {
  ami               = data.aws_ami.nat_instance_ami.id
  instance_type     = var.nat_instance_type
  source_dest_check = false
  security_groups   = [aws_security_group.nat_instance_sec_gr.id]
  key_name          = var.key_name
  subnet_id         = aws_subnet.public_subnet[0].id
  tags = {
    Name = "${var.tag_name}-NAT-instance"
  }

}

resource "aws_alb" "app_lb" {
  name               = "${var.tag_name}-lb-tf"
  ip_address_type    = "ipv4"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sec_gr.id]
  subnets = [
    aws_subnet.public_subnet[0].id,
    aws_subnet.public_subnet[1].id,
  ]
  tags = {
    Name = "${var.tag_name}-lb-tf"
  }
}

resource "aws_alb_target_group" "app_lb_tg" {
  name        = "${var.tag_name}-lb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "instance"

  tags = {
    Name = "${var.tag_name}-lb-tf"
  }
}

resource "aws_alb_listener" "app_listener_http" {
  load_balancer_arn = aws_alb.app_lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  tags = {
    Name = "${var.tag_name}-listener-http"
  }
}

resource "aws_alb_listener" "app_listener_https" {
  load_balancer_arn = aws_alb.app_lb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.certificate.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.app_lb_tg.arn
  }
  tags = {
    Name = "${var.tag_name}-listener-https"
  }
}

# resource "aws_route53_zone" "r53_zone" {
#   name = var.domain_name
# }
# If there isn't a hosted zone already to be selected, the resource block above can be used
# Other resource blocks have to be adjusted accordingly

resource "aws_acm_certificate" "certificate" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_dns" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.certificate.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.certificate.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.certificate.domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.selected.zone_id
  ttl             = 60
}

resource "aws_acm_certificate_validation" "hello_cert_validate" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [aws_route53_record.cert_dns.fqdn]
}

resource "aws_iam_role" "lt_role" {
  name = "${var.tag_name}-lt-role"
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        # Sid    = "",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}

resource "aws_iam_instance_profile" "lt_role_profile" {
  name = "${var.tag_name}-lt-role-profile"
  role = aws_iam_role.lt_role.name
  path = "/"
}

resource "aws_instance" "bastion_host" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.bastion_host_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.bastion_host_sec_gr.id]
  subnet_id              = aws_subnet.public_subnet[0].id

  tags = {
    Name = "${var.tag_name}-bastion-host"
  }
}

resource "aws_launch_template" "asg_lt" {
  name     = "${var.tag_name}-lt"
  image_id = data.aws_ami.ubuntu_ami.id
  iam_instance_profile {
    name = "${var.tag_name}-lt-role-profile"
  }
  instance_type          = var.asg_lt_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sec_gr.id]
  user_data = base64encode(templatefile("new-user-data.sh", {
    user-data-git-token   = var.git-token,
    rds_db_name           = var.rds_db_name,
    db_username           = var.db_username,
    db_endpoint           = aws_db_instance.db_instance.address,
    content_bucket_name   = aws_s3_bucket.s3_bucket_content.id,
    content_bucket_region = var.content_bucket_region,
    db_password           = var.db_password
  }))
  depends_on = [
    aws_db_instance.db_instance,
    aws_route.outbound-nat-route
  ]
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.tag_name}-lt"
    }
  }
}

resource "aws_autoscaling_group" "app_asg" {
  default_cooldown          = 200
  max_size                  = var.asg_max_instance_size
  min_size                  = var.asg_min_instance_size
  desired_capacity          = var.asg_desired_capacity
  name                      = "${var.tag_name}-lt-asg"
  health_check_grace_period = 300
  health_check_type         = "ELB"
  target_group_arns         = [aws_alb_target_group.app_lb_tg.arn]
  vpc_zone_identifier = [
    aws_subnet.private_subnet[0].id,
    aws_subnet.private_subnet[1].id,
  ]
  tag {
    key                 = "Name"
    value               = "${var.tag_name}-lt-asg"
    propagate_at_launch = true
  }
  launch_template {
    id      = aws_launch_template.asg_lt.id
    version = aws_launch_template.asg_lt.latest_version
  }
}

resource "aws_autoscaling_policy" "asg_policy" {
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  name                   = "${var.tag_name}-asg-policy"
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.asg_policy_target_value
  }
}

resource "aws_autoscaling_notification" "asg_notifications" {
  group_names = [
    aws_autoscaling_group.app_asg.name
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.sns_topic.arn
}

resource "aws_sns_topic" "sns_topic" {
  name = "server-status-change"
}

resource "aws_sns_topic_subscription" "EmailSubscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "email"
  endpoint  = var.operator_email
}

resource "aws_cloudfront_distribution" "alb_cf_distro" {
  origin {
    domain_name = aws_alb.app_lb.dns_name
    origin_id   = local.alb_origin_id
    custom_origin_config {
      origin_keepalive_timeout = 5
      origin_ssl_protocols     = ["TLSv1"]
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "match-viewer"
    }
  }
  enabled = true
  aliases = [var.domain_name]
  comment = "Cloudfront Distribution pointing to ALBDNS"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.alb_origin_id
    smooth_streaming = false
    forwarded_values {
      query_string = true
      headers = ["Host",
        "Accept",
        "Accept-Charset",
        "Accept-Datetime",
        "Accept-Encoding",
        "Accept-Language",
        "Authorization",
        "Cloudfront-Forwarded-Proto",
      "Origin", "Referrer"]
      cookies {
        forward = "all"
      }
    }
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }
  price_class = "PriceClass_All"
  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.certificate.arn
    ssl_support_method  = "sni-only"
  }
  tags = {
    Name = "${var.tag_name}-cf-distro"
  }
}

resource "aws_dynamodb_table" "dynamodb_table" {
  name           = "${var.tag_name}-dynamodb-table"
  read_capacity  = 3
  write_capacity = 3
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "${var.tag_name}-dynamodb-table"
  }
}

resource "aws_route53_health_check" "r53_health_check" {
  fqdn              = aws_cloudfront_distribution.alb_cf_distro.domain_name
  port              = 443
  type              = "HTTPS"
  failure_threshold = "3"
  request_interval  = "30"

  tags = {
    Name = "${var.tag_name}-r53_health_check"
  }
}

resource "aws_route53_record" "primary" {
  zone_id         = data.aws_route53_zone.selected.zone_id
  name            = var.domain_name
  type            = "A"
  health_check_id = aws_route53_health_check.r53_health_check.id
  set_identifier  = "www1"
  alias {
    name                   = aws_alb.app_lb.dns_name
    zone_id                = aws_alb.app_lb.zone_id
    evaluate_target_health = true
  }
  failover_routing_policy {
    type = "PRIMARY"
  }
}

resource "aws_route53_record" "secondary" {
  zone_id         = data.aws_route53_zone.selected.zone_id
  name            = var.domain_name
  type            = "A"
  health_check_id = aws_route53_health_check.r53_health_check.id
  set_identifier  = "www2"
  alias {
    name                   = aws_s3_bucket_website_configuration.bucket_website_config.website_domain
    zone_id                = aws_s3_bucket.s3_bucket_failover.hosted_zone_id
    evaluate_target_health = true
  }
  failover_routing_policy {
    type = "SECONDARY"
  }
}
