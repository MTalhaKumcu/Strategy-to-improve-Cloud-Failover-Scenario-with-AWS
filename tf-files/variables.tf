variable "vpc_cidr_block" {
  default     = "90.90.0.0/16"
  description = "Default VPC cidr block"
}
variable "tag_owner" {
  default = "mehmet talha kumcu"
}

variable "tag_name" {
  default = "thesisproject"
}

variable "key_name" {
  default = "newKeyPair"
}

#vpc-subnet

variable "subnet_cidrs_public" {
  description = "Subnet CIDRs for public subnets (length must match configured availability_zones)"
  default     = ["90.90.10.0/24", "90.90.20.0/24"]
  type        = list(string)
}

variable "subnet_cidrs_private" {
  description = "Subnet CIDRs for private subnets (length must match configured availability_zones)"
  default     = ["90.90.11.0/24", "90.90.21.0/24"]
  type        = list(string)
}

variable "availability_zones" {
  description = "AZs in this region to use"
  default     = ["us-east-1a", "us-east-1b"]
  type        = list(string)
}

variable "s3_bucket_content" {
  default = "thesisproject-s3-bucket-content"
}

variable "s3_bucket_failover" {
  default = "thesisproject-s3-bucket-failover"
}

variable "rds_db_name" {
  default = "thesis"
}
variable "db_username" {
  default = "admin"
}

variable "db_password" {
  default = "admin1234"
}

variable "content_bucket_region" {
  default = "us-east-1"
}

variable "operator_email" {
  default = "mtkcloudevops@gmail.com"
}

variable "domain_name" {
  type    = string
  default = "www.mtkcloud.online"
}

variable "existing_hosted_zone" {
  default = "mtkcloud.online"
}

variable "files_to_upload" {
  description = "List of file paths to upload to S3"
  type        = list(string)
  default     = ["S3_Static_Website/index.html", "S3_Static_Website/sorry.jpg"]
}

variable "git-token" {
  default = "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"
}

variable "s3_vpc_endpoint_service_name" {
  default = "com.amazonaws.us-east-1.s3"
}

variable "provider_region" {
  default = "us-east-1"
}

variable "rds_db_engine_version" {
  default = "8.0.28"
}

variable "rds_db_instance_class" {
  default = "db.t2.micro"
}

variable "nat_instance_type" {
  default = "t2.micro"
}

variable "asg_max_instance_size" {
  default = "4"
}

variable "asg_min_instance_size" {
  default = "2"
}

variable "asg_desired_capacity" {
  default = "2"
}

variable "asg_policy_target_value" {
  default = "80.0"
}

variable "bastion_host_instance_type" {
  default = "t2.micro"
}

variable "asg_lt_instance_type" {
  default = "t2.micro"
}
