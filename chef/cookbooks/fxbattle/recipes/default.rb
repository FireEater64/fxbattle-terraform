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

# Install nginx
include_recipe 'nginx'

nginx_site 'fxbattle' do
    template 'fxbattle.conf'
end