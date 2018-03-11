provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_eip" "fxbattle" {
  instance = "${aws_instance.fxbattle.id}"
  vpc      = true
}

resource "aws_security_group" "fxbattle" {
  name        = "fxbattle"
  description = "FXBattle Ports"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "fxbattle" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "ubuntu"

    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "${var.instance_size}"

  # Lookup the correct AMI based on the region
  # we specified
  ami = "${data.aws_ami.ubuntu.id}"

  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.auth.id}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.fxbattle.id}"]

  # Copy the chef solo recipe to the created instance
  provisioner "file" {
    source      = "chef"
    destination = "/home/ubuntu"

    connection {
      private_key = "${file("~/.ssh/id_rsa")}"
    }
  }

  # Install the chef omnibus, and delegate to chef-solo
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get install -y build-essential",
      "curl -L https://www.opscode.com/chef/install.sh | sudo bash",
      "sudo /opt/chef/embedded/bin/gem install berkshelf --no-ri --no-rdoc",
      "cd /home/ubuntu/chef",
      "sudo /opt/chef/embedded/bin/berks vendor --berksfile cookbooks/fxbattle/Berksfile cookbooks",
      "sudo chef-client -z -o fxbattle",
    ]

    connection {
      private_key = "${file("~/.ssh/id_rsa")}"
    }
  }
}
