//Set up for Digitalocean resources
provider "digitalocean" {
  token = "${var.do_token}"
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

data "template_file" "chef_bootstrap" {
  template = "${file("data/chef_bootstrap.tpl")}"

  vars {
    os_version             = "${var.os_version}"
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

resource "digitalocean_ssh_key" "default" {
  name       = "id_rsa"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "digitalocean_droplet" "chef_server" {
  name                = "${var.do_droplet_name}"
  region              = "${var.do_region}"
  image               = "${var.do_image}"
  size                = "${var.do_size}"

  provisioner "remote-exec" {

    connection {
      host        = "${digitalocean_droplet.chef_server.ipv4_address}"
      private_key = "${file("~/.ssh/id_rsa")}"
      timeout     = "45s"
    }

    inline = [
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

# resource "digitalocean_record" "chef_dns" {
#   domain = "${var.dns_record}"
#   type   = "A"
#   name   = "${var.chef_dns_prefix}"
#   value  = "${digitalocean_droplet.chef_server.ipv4_address}"
# }
#
# resource "null_resource" "letsencrypt" {
#
#   depends_on = [
#                 "digitalocean_droplet.chef_server",
#                 "digitalocean_record.chef_dns"
#                ]
#
#   provisioner "remote-exec" {
#
#     connection {
#       host        = "${digitalocean_droplet.chef_server.ipv4_address}"
#       private_key = "${file("~/.ssh/id_rsa")}"
#       timeout     = "50s"
#     }
#
#     inline = [
#       "chef-server-ctl stop",
#       "cat <<FILE6 > /etc/opscode/chef-server.rb",
#       "${data.template_file.chef_server_config.rendered}",
#       "FILE6",
#
#       "git clone https://github.com/certbot/certbot",
#       "./letsencrypt/letsencrypt-auto certonly --standalone --email ${var.chef_user_email} -d ${var.chef_dns_prefix}.${var.dns_record} --agree-tos -n",
#       "chef-server-ctl reconfigure"
#     ]
#   }
# }

output "hostname" {
  value = "${var.do_droplet_name}"
}

output "public_ip" {
  value = "${digitalocean_droplet.chef_server.ipv4_address}"
}
