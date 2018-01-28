chef_dns_prefix = "chef"
chef_version    = "12.17.15"

do_image        = "ubuntu-16-04-x64"
os_version      = "16.04"
do_droplet_name = "crepitus"
do_region       = "nyc3"

# See https://github.com/terraform-providers/terraform-provider-digitalocean/issues/60
# for size definitions.
do_size         = "s-1vcpu-3gb"
