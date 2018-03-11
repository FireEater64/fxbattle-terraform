name 'fxbattle'
maintainer 'George Vanburgh'
license 'All Rights Reserved'
description 'Installs/Configures an fxbattle application server'
long_description 'Installs/Configures an fxbattle application server'
version '0.1.0'
chef_version '>= 12.1' if respond_to?(:chef_version)

issues_url 'https://github.com/FireEater64/fxbattle-terraform/issues'
source_url 'https://github.com/FireEater64/fxbattle-terraform'

depends 'acme'
depends 'docker'
depends 'nginx'