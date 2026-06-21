provider "aws" {
  region = "us-west-2"
}

resource "aws_kms_key" "ebs_key" {
  description             = "Customer managed key for EBS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_instance" "example" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  subnet_id     = "subnet-12345678"

  vpc_security_group_ids = [aws_security_group.example.id]

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted  = true
    kms_key_id = aws_kms_key.ebs_key.arn
  }
}

resource "aws_ebs_volume" "example" {
  availability_zone = "us-west-2a"
  size              = 20
  encrypted         = true
  kms_key_id        = aws_kms_key.ebs_key.arn
}

resource "aws_security_group" "example" {
  name        = "allow_tls_restricted"
  description = "Allow restricted TLS inbound traffic"

  ingress {
    description = "Allow HTTPS from trusted network"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Allow HTTPS outbound only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_elb" "example" {
  name               = "internal-example-elb"
  availability_zones = ["us-west-2a"]
  internal           = true

  listener {
    instance_port      = 443
    instance_protocol  = "HTTPS"
    lb_port            = 443
    lb_protocol        = "HTTPS"
    ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/example-cert"
  }
}