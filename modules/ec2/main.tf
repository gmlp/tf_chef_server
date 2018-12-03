data "aws_ami" "ubuntu" {
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  most_recent = true
  owners      = ["099720109477"] # Canonical
}

resource "aws_instance" "ec2" {
  ami                  = "${data.aws_ami.ubuntu.id}"
  instance_type        = "${var.instance_type}"
  iam_instance_profile = "${var.instance_profile_name}"
  user_data            = "${file("${path.module}/install.sh")}"
  availability_zone    = "${var.availability_zone}"

  tags = "${merge(var.tags,
    map (
      "Name", "${var.name}", 
      )
  )}"

  vpc_security_group_ids = ["${var.security_group_ids}"]
  key_name               = "${var.key_name}"

  lifecycle {
    ignore_changes = ["ami"]
  }
}

resource "null_resource" "initialize_swap_ebs" {
  triggers {
    volume_attachment = "${aws_volume_attachment.swap_ebs_att.id}"
  }

  connection {
    user        = "ubuntu"
    private_key = "${file(var.key_path)}"
    host        = "${aws_instance.ec2.public_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkswap /dev/xvdg",
      "sudo su -c 'echo \"/dev/xvdg none   swap    sw      0       0\" >> /etc/fstab' ",
      "sudo swapon -a",
    ]
  }
}

resource "aws_ebs_volume" "swap_volume" {
  availability_zone = "${var.availability_zone}"
  size              = "${var.swap_volume_size}"

  tags = "${merge(var.tags,
    map (
      "Name", "${var.name}-swap-volume",
      )
  )}"
}

resource "aws_volume_attachment" "swap_ebs_att" {
  device_name  = "/dev/xvdg"
  volume_id    = "${aws_ebs_volume.swap_volume.id}"
  instance_id  = "${aws_instance.ec2.id}"
  skip_destroy = true
}
