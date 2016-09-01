#
# Cookbook Name:: bacchus-web-cookbook
# Recipe:: sethostname
#
# Copyright (c) 2016 The Authors, All Rights Reserved.


execute "set hostname" do
    user 'root'
    command "hostname #{node[:opsworks][:stack][:name] + '-' + node[:opsworks][:instance][:hostname]}"
    action :run
end
