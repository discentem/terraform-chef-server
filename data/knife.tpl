# See https://docs.getchef.com/config_rb_knife.html for more information on knife configuration options
# Yes having 'ssl_verify_mode' disabled looks bad but we are managing this
# locally on the chef server under 127.0.0.1. Plus we don't want admins
# managing this chef server via knife. Use the git repo.

log_level               :info
log_location            STDOUT
node_name               "${chef_username}"
client_key              "${chef_username}.pem"
validation_client_name  "${chef_organization_id}-validator"
validation_key          "${chef_organization_id}-validator.pem"
chef_server_url         "https://${dns_record}/organizations/${chef_organization_id}"
cookbook_path [
  "/var/chef/grocery_delivery_work/cpe/cookbooks/",
]
