name 'bacchus-web'
maintainer 'The Authors'
maintainer_email 'you@example.com'
license 'all_rights'
description 'Installs/Configures bacchus-web'
long_description 'Installs/Configures bacchus-web'
version '0.1.0'

#recipe "php-tagr::default","Upgrades php to 5.6. Does a System apt-get update"
#recipe "php-tagr::configure","Configures for php "
recipe "bacchus-web::deploy","Adds more deploy configuration for Java Server "
depends "apache2"
