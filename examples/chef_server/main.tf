data "terraform_remote_state" "global" {
  backend = "s3"

  config {
    bucket = "tf-remote-state-training-nov"
    key    = "chef_server/global/terraform.tfstate"
    region = "us-east-1"
  }
}

module "vpc" {
  source = "../../modules/vpc"
  tags   = "${data.terraform_remote_state.global.tags}"
}

resource "aws_key_pair" "deployer" {
  key_name   = "chef-server-key"
  public_key = "${file(var.my_public_key_path)}"
}

module "ec2" {
  source             = "../../modules/ec2"
  name               = "chef_server"
  instance_type      = "t2.medium"
  security_group_ids = "${module.vpc.sg_id}"
  key_name           = "${aws_key_pair.deployer.key_name}"
  key_path           = "${var.my_private_key_path}"
  docker_volume_size = "60"
  tags               = "${data.terraform_remote_state.global.tags}"
}

output "chef_server_public_ip" {
  value = "${module.ec2.public_ip}"
}

output "chef_server_id" {
  value = "${module.ec2.id}"
}
