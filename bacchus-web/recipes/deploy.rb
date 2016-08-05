directory  "/srv/www/"  do
    mode '0775'
    user 'deploy'
    group 'www-data'
    recursive true
    action :create
end
