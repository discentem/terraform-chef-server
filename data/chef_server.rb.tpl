server_name = "${chef_fqdn}"
api_fqdn server_name
bookshelf['vip'] = server_name
nginx['url'] = "https://#{server_name}"
nginx['server_name'] = server_name
nginx['ssl_certificate'] = "/etc/letsencrypt/live/#{server_name}/fullchain.pem"
nginx['ssl_certificate_key'] = "/etc/letsencrypt/live/#{server_name}/privkey.pem"
