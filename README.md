Automated building of [Chef-Server](https://docs.chef.io/install_server.html) with [Grocery Delivery](https://github.com/facebook/grocery-delivery) via Terraform.
This also grabs a Lets Encrypt cert for the Chef server and configures it.

This project builds the sever and DNS on Digital Ocean; however, it is easily modified to build on any other Cloud Platform supported by Terraform. The provisioning bits are mostly cloud agnostic.

A blog post on how to use this is coming soon.
