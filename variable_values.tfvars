chef_dns_prefix = "chef"
chef_version    = "12.17.15"

do_image        = "ubuntu-16-04-x64"
os_version      = "${split("-", do_image)[1]}.${split("-", do_image)[2]}"
do_droplet_name = "crepitus"
do_region       = "nyc3"
do_size         = "4gb"
