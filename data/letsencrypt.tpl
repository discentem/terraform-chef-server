#!/bin/bash

git clone https://github.com/letsencrypt/letsencrypt
./letsencrypt/letsencrypt-auto certonly --standalone --email ${chef_user_email} -d ${chef_fqdn} --agree-tos -n
