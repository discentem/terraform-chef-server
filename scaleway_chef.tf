//Set up for Scaleway resources
provider "scaleway" {
  organization = "${var.sw_access_key}"
  token        = "${var.sw_token}"
  region       = "${var.sw_region}"
}

//Set up for Digitalocean resources
provider "digitalocean" {
  token = "${var.do_token}"
}

//OS Image resource for Scaleway
data "scaleway_image" "ubuntu" {
  architecture = "${var.sw_image_architecture}"
  name         = "${var.sw_image}"
}

//Security policy for Scaleway servers
resource "scaleway_security_group" "default" {
  name        = "ssh_security_group"
  description = "Allow SSH traffic"
}

//Allowing ssh from the internet. Though later we are dropping an ssh key so...
// this should be ok.
resource "scaleway_security_group_rule" "ssh_accept" {
  security_group = "${scaleway_security_group.default.id}"

  action    = "accept"
  direction = "inbound"
  ip_range  = "0.0.0.0/0"
  protocol  = "TCP"
  port      = 22
}

//Templating knife.rb file. For grocery-delivery, this config lives on the
// Chef server.
data "template_file" "knife_config" {
  template = "${file("data/knife.tpl")}"

  vars {
    chef_organization_id = "${var.chef_organization_id}"
    chef_username        = "${var.chef_username}"
    dns_record           = "${var.chef_dns_prefix}.${var.dns_record}"
  }
}

resource "scaleway_ip" "server_ip" {
  server = "${scaleway_server.chef_server.id}"
}

data "template_file" "chef_bootstrap" {
  template = "${file("data/chef_bootstrap.tpl")}"

  vars {
    os_version             = "${var.sw_os_version}"
    chef_fqdn              = "${var.chef_dns_prefix}.${var.dns_record}"
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

data "template_file" "chef_server_config" {
  template = "${file("data/chef_server.rb.tpl")}"
  vars {
    chef_fqdn     = "${var.chef_dns_prefix}.${var.dns_record}"
  }
}

data "template_file" "gd-config" {
  template = "${file("data/gd-config.tpl")}"

  vars {
    git_username  = "${var.git_username}"
    git_repo_name = "${var.git_repo_name}"
  }
}

data "template_file" "id_rsa" {
  template = "${file("~/.ssh/private_chef_repo")}"
}

data "template_file" "cron_gd" {
  template = "${file("data/cron_gd")}"
}

data "template_file" "letsencrypt" {
  template = "${file("data/letsencrypt.tpl")}"

  vars {
    chef_user_email   = "${var.chef_user_email}"
    chef_fqdn         = "${var.chef_dns_prefix}.${var.dns_record}"
  }
}

resource "scaleway_server" "chef_server" {
  name                = "${var.sw_server_name}"
  image               = "${data.scaleway_image.ubuntu.id}"
  type                = "${var.sw_server_type}"
  security_group      = "${scaleway_security_group.default.id}"
  dynamic_ip_required = true

  volume {
    size_in_gb = 150
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

      "echo '127.0.0.1 chef ${var.chef_dns_prefix}.${var.dns_record}' >> /etc/hosts",

      "touch /tmp/bootstrap-chef-server.sh",
      "cat <<FILE5 > /tmp/bootstrap-chef-server.sh",
      "${data.template_file.chef_bootstrap.rendered}",
      "FILE5",
      "chmod +x /tmp/bootstrap-chef-server.sh",
      "sh /tmp/bootstrap-chef-server.sh",
    ]
  }
}

resource "digitalocean_record" "chef_dns" {
  domain = "${var.dns_record}"
  type   = "A"
  name   = "${var.chef_dns_prefix}"
  value  = "${scaleway_ip.server_ip.ip}"
}

resource "null_resource" "letsencrypt" {

  depends_on = ["scaleway_server.chef_server", "digitalocean_record.chef_dns"]

  provisioner "remote-exec" {

    connection {
      host        = "${scaleway_server.chef_server.public_ip}"
      private_key = "${file("~/.ssh/id_rsa")}"
      timeout     = "50s"
    }

    inline = [
      "cat <<FILE6 > /etc/opscode/chef-server.rb",
      "${data.template_file.chef_server_config.rendered}",
      "FILE6",
      "chef-server-ctl stop",

      "touch /tmp/letsencrypt.sh",
      "cat <<FILE7 > /tmp/letsencrypt.sh",
      "${data.template_file.letsencrypt.rendered}",
      "FILE7",
      "chmod +x /tmp/letsencrypt.sh",
      "sh /tmp/letsencrypt.sh",
      "chef-server-ctl reconfigure"
    ]
  }
}


output "hostname" {
  value = "${var.sw_server_name}"
}

output "public_ip" {
  value = "${scaleway_ip.server_ip.ip}"
}
