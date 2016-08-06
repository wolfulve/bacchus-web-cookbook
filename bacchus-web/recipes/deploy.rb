directory  "/srv/www/"  do
    mode '0775'
    user 'deploy'
    group 'apache'
    recursive true
    action :create
end
