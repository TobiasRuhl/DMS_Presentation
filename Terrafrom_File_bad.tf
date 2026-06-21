provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "example" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  subnet_id     = "subnet-12345678"

  security_groups = ["sg-12345678"]
  key_name        = "my_key"

  # FINDING #18:
  # Die EC2-Instanz hat kein verschlüsseltes root_block_device.
  # Trivy meldet deshalb: "Instance with unencrypted block device."

  # FINDING #13:
  # Es fehlen metadata_options mit http_tokens = "required".
  # Dadurch wird IMDSv2 nicht erzwungen.
  # Trivy meldet: "aws_instance should activate session tokens for Instance Metadata Service."
}

resource "aws_ebs_volume" "example" {
  availability_zone = "us-west-2a"
  size              = 20
  encrypted         = true

  # FINDING #12:
  # Das Volume ist zwar verschlüsselt, nutzt aber keinen Customer Managed Key.
  # Es fehlt z. B.: kms_key_id = aws_kms_key.ebs_key.arn
  # Trivy meldet: "EBS volume encryption should use Customer Managed Keys."
}

resource "aws_security_group" "example" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"

  ingress {
    # FINDING #16:
    # Für diese Security-Group-Regel fehlt eine description.
    # Trivy meldet: "Missing description for security group rule."

    from_port   = 443
    to_port     = 443
    protocol    = "tcp"

    # Risiko:
    # Zugriff auf Port 443 ist aus dem gesamten Internet erlaubt.
    # Das wurde in deinen Findings nicht als eigener High/Critical Alert gelistet,
    # ist aber sicherheitstechnisch trotzdem sehr offen.
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    # FINDING #17:
    # Auch hier fehlt eine description.
    # Trivy meldet: "Missing description for security group rule."

    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    # FINDING #15:
    # Ausgehender Traffic ist zu jeder IP-Adresse erlaubt.
    # Trivy meldet: "A security group rule should not allow unrestricted egress to any IP address."
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "example" {
  name               = "example-elb"
  availability_zones = ["us-west-2a"]

  # FINDING #14:
  # Der Load Balancer ist nicht als internal = true gesetzt.
  # Dadurch gilt er als öffentlich/exposed.
  # Trivy meldet: "Load balancer is exposed to the internet."

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"

    # Zusätzliches Risiko:
    # HTTP ist unverschlüsselt.
    # Für eine sichere Variante wäre HTTPS mit Zertifikat nötig.
  }
}