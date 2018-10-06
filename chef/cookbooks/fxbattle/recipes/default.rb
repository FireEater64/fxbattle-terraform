#
# Cookbook:: fxbattle
# Recipe:: default
#

# Pull fxbattle source
git '/home/azureuser/trading-game' do
    repository 'https://github.com/nadvamir/trading-game.git'
    enable_submodules true
end

# Install docker
docker_service 'default' do
    userland_proxy false
    action [:create, :start]
end

# Build docker container
docker_image 'fxbattle' do
    source '/home/azureuser/trading-game'
    action :build_if_missing
end

# Run up container
docker_container 'fxbattle' do
    action :run_if_missing
    port '8080:8080'
    volumes ['/home/azureuser/trading-game/:/config']
end

# Generate a self-signed if we don't have a cert to prevent bootstrap problems
include_recipe 'acme'
site = node.read!('fxbattle', 'url')
acme_directory = "/var/www/#{site}.acme"

directory "/etc/nginx/ssl" do
    recursive true
end
directory acme_directory do
    recursive true
end

acme_selfsigned site do
  crt     "/etc/nginx/ssl/#{site}.crt"
  key     "/etc/nginx/ssl/#{site}.key"
  chain    "/etc/nginx/ssl/#{site}.pem"
end

# Install nginx
include_recipe 'nginx'

nginx_site 'fxbattle' do
    template 'fxbattle.conf'
    notifies :restart, "service[nginx]", :immediately
end

# Get and auto-renew the certificate from Let's Encrypt
acme_certificate site do
  key               "/etc/nginx/ssl/#{site}.key"
  fullchain         "/etc/nginx/ssl/#{site}.pem"
  wwwroot           acme_directory
  notifies          :restart, "service[nginx]", :immediately
  retries           3
end
