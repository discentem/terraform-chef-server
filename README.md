## Summary

Automated building of [Chef-Server](https://docs.chef.io/install_server.html) with [Grocery Delivery](https://github.com/facebook/grocery-delivery) via Terraform.
This also grabs a Lets Encrypt cert for the Chef server and configures it.

This project currently builds the sever and DNS on Digital Ocean; however, it is easily modified to build on any other Cloud Platform supported by Terraform. The provisioning bits are mostly cloud agnostic.

## Basic usage:

Run `terraform apply -var-file=variable_values.tfvars -var-file=secrets.tfvars` where `secrets.tfvars` is a file created you by (it's already in the .gitignore). `secrets.tfvars` would look something like this:

```
dns_record = "<main dns record here>"

# i.e. website.org not chef.website.org.
# https://github.com/discentem/terraform-chef-server/blob/digital_ocean/main.tf#L116    # assumes the top level DNS record is already set up in Digital Ocean. We are just    
# referencing here so that we can create chef.website.org.

do_token = "<digital ocean API token here>"

chef_username = "bkurtz"
chef_first_name = "Brandon"
chef_last_name = "Kurtz"
chef_user_email = "email@gmail.com"
chef_organization_id = "pretendco"
chef_organization_name = "pretendco"

git_username = "<username>"
git_repo_name = "<repo_name"
# github.com/<username>/<repo_name>

```
