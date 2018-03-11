#
# Cookbook:: fxbattle
# Recipe:: default
#

# Pull fxbattle source
git '/home/ubuntu/trading-game' do
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
    source '/home/ubuntu/trading-game'
    action :build_if_missing
end

# Run up container
docker_container 'fxbattle' do
    action :run_if_missing
end

# Install nginx
include_recipe 'nginx'
include_recipe 'acme'

nginx_site 'fxbattle' do
    template 'nginx-test.conf'
  
    notifies :reload, 'service[nginx]', :immediately
  end

include_recipe 'acme_client::nginx'