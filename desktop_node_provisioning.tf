resource "aws_instance" "desktop_node" { 

  depends_on             = ["aws_instance.chef_automate", "null_resource.harvest_key"]
  count                  = var.desktop_count
  ami                    = var.aws_ami_id == "" ? data.aws_ami.windows10.id : var.aws_ami_id
  key_name               = var.aws_key_pair_name
  subnet_id              = aws_subnet.habmgmt-subnet-a.id
  instance_type          = var.desktop_type
  vpc_security_group_ids = ["${aws_security_group.chef_automate.id}"]

  root_block_device {
    delete_on_termination = true
    volume_size           = 50
    volume_type           = "gp2"
  }

  connection {
    host        = self.public_ip
    type        = "winrm"
    user        = "${var.admin-user}"
    password     = "${var.windows-admin-password}"
  }

  user_data = file("./files/win-userdata.ps1")

  provisioner "local-exec" {
        command = "sleep 160"
  }

  provisioner "local-exec" {
    command = "knife bootstrap ${self.public_ip} -U ${var.admin-user} -P ${var.windows-admin-password} -o winrm --policy-group ${var.chef_policy_group} --policy-name ${var.chef_policy_name} -N desktop-node-${count.index + 1} --config ../../chef-repo/.chef/knife.rb"
  }

  tags = {
    Name          = format("${var.tag_project}_desktop_${count.index + 1}")
    X-Dept        = var.tag_dept
    X-Customer    = var.tag_customer
    X-Project     = var.tag_project
    X-Application = var.tag_application
    X-Contact     = var.tag_contact
    X-TTL         = var.tag_ttl
  }
}