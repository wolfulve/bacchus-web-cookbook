#
# Cookbook Name:: bacchus-web-cookbook
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.


execute "set hostname" do
    user 'root'
    command "hostname test-stack3-java-app1"
    action :run
end
