provider "scaleway" {
  organization = "${var.access_key}"
  token        = "${var.token}"
  region       = "${var.region}"
}

provider "digitalocean" {
  token = "${var.do_token}"
}

data "scaleway_bootscript" "latest" {
  architecture = "x86_64"
  name_filter  = "latest"
}

data "scaleway_image" "ubuntu" {
  architecture = "x86_64"
  name         = "${var.image}"
}

resource "scaleway_security_group" "default" {
  name        = "ssh_security_group"
  description = "Allow SSH traffic"
}

resource "scaleway_security_group_rule" "ssh_accept" {
  security_group = "${scaleway_security_group.default.id}"

  action    = "accept"
  direction = "inbound"
  ip_range  = "0.0.0.0/0"
  protocol  = "TCP"
  port      = 22
}

data "template_file" "knife_config" {
  template = "${file("data/knife.tpl")}"

  vars {
    chef_organization_id = "${var.chef_organization_id}"
    chef_username        = "${var.chef_username}"
    dns_record           = "${var.dns_record}"
  }
}

data "template_file" "chef_bootstrap" {
  template = "${file("data/chef_bootstrap.tpl")}"

  vars {
    chef_username          = "${var.chef_username}"
    chef_first_name        = "${var.chef_first_name}"
    chef_last_name         = "${var.chef_last_name}"
    chef_password          = "${var.chef_password}"
    chef_user_email        = "${var.chef_user_email}"
    chef_organization_id   = "${var.chef_organization_id}"
    chef_organization_name = "${var.chef_organization_name}"
    chef_version           = "${var.chef_version}"
  }
}

data "template_file" "gd-config" {
  template = "${file("data/gd-config.tpl")}"

  vars {
    git_username   = "${var.git_username}"
    chef_repo_name = "${var.chef_repo_name}"
  }
}

data "template_file" "id_rsa" {
  template = "${file("~/.ssh/private_chef_repo")}"
}

data "template_file" "cron_gd" {
  template = "${file("data/cron_gd")}"
}

resource "digitalocean_record" "chef_dns" {
  domain = "bkurtz.net"
  type   = "A"
  name   = "chef"
  value  = "${scaleway_ip.server_ip.ip}"
}

resource "digitalocean_record" "chef_dns_2" {
  domain = "bkurtz.io"
  type   = "A"
  name   = "chef"
  value  = "${scaleway_ip.server_ip.ip}"
}

resource "scaleway_ip" "server_ip" {
  server = "${scaleway_server.chef_server.id}"
}

resource "scaleway_server" "chef_server" {
  name                = "${var.server_name}"
  image               = "${data.scaleway_image.ubuntu.id}"
  type                = "${var.server_type}"
  bootscript          = "${data.scaleway_bootscript.latest.id}"
  security_group      = "${scaleway_security_group.default.id}"
  dynamic_ip_required = true

  volume {
   size_in_gb = 50
   type       = "l_ssd"
  }

  provisioner "remote-exec" {

    connection {
      host        = "${scaleway_server.chef_server.public_ip}"
      private_key = "${file("~/.ssh/id_rsa")}"
      timeout     = "50s"
    }

    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt-get install tzdata -y",
      "mkdir /root/.chef",

      "touch /root/.chef/knife.rb",
      "cat <<FILE1 > /root/.chef/knife.rb",
      "${data.template_file.knife_config.rendered}",
      "FILE1",

      "touch /etc/gd-config.rb",
      "cat <<FILE2 > /etc/gd-config.rb",
      "${data.template_file.gd-config.rendered}",
      "FILE2",

      "touch /root/.ssh/id_rsa",
      "cat <<FILE3 > /root/.ssh/id_rsa",
      "${data.template_file.id_rsa.rendered}",
      "FILE3",
      "chmod 0600 /root/.ssh/id_rsa",

      "touch /etc/cron.d/gd",
      "cat <<FILE4 > /etc/cron.d/gd",
      "${data.template_file.cron_gd.rendered}",
      "FILE4",

      "echo '127.0.0.1 chef chef.bkurtz.net' >> /etc/hosts",

      "touch /tmp/bootstrap-chef-server.sh",
      "cat <<FILE5 > /tmp/bootstrap-chef-server.sh",
      "${data.template_file.chef_bootstrap.rendered}",
      "FILE5",

      "chmod +x /tmp/bootstrap-chef-server.sh",
      "sudo sh /tmp/bootstrap-chef-server.sh"
    ]
  }
}

output "hostname" {
  value = "${var.server_name}"
}

output "public_ip" {
  value = "${scaleway_ip.server_ip.ip}"
}
