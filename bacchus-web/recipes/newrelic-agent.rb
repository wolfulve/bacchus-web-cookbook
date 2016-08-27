#
# Cookbook Name:: systems
# Recipe:: newrelic
#
# Copyright (C) 2015 Frequency
#
# All rights reserved - Do Not Redistribute
#
#

#Chef::Log.info("********** app name: '#{node[:deploy][:appshortname]}' **********")

node[:deploy].each do |application, deploy|
    if deploy[:application_type] == 'java'
        Chef::Log.info("Deploying java application #{application}")
    end
end

execute "copy agent to tomcat base" do
    cwd '/usr/share/tomcat7'
    command "rm -rf newrelic && mv /tmp/newrelic ."
    action :run
end


