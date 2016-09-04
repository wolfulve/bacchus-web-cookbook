
#
# Cookbook Name:: systems
# Recipe:: newrelic-java-agent
#
# Copyright (C) 2016 Frequency
#
# All rights reserved - Do Not Redistribute
#
#

app_name = ''

node[:deploy].each_with_index do |(application, deploy), index|
    Chef::Log.info("******** Application: #{application}, type: #{deploy[:application_type]} (#{index+1}/#{node[:deploy].size})")
    if deploy[:application_type] == 'java'
        Chef::Log.info("******** Deploying java application: #{application}")
        if index < 3
            app_name = app_name + node[:opsworks][:stack][:name] + '-' + application + ';'
        end
    end
end

# remove trailing/last ';'
if app_name.length > 0
    app_name.slice!(app_name.length-1,app_name.length)
end

execute "fetch agent and unzip" do
    cwd '/tmp'
    package = 'newrelic-java-3.25.0.zip'
    command "aws s3 cp s3://elasticbeanstalk-us-west-2-227102987351/bacchus/#{package} . && unzip -o #{package} && rm -r newrelic-java-*.zip"
    action :run
end

# set app name & License Key
template "/tmp/newrelic/newrelic.yml" do
    source "newrelic-java-agent.yml.erb"
    owner "root"
    group "root"
    mode 0644
    variables({
              :application_name => app_name,
              :key => '221e63f2ee0ed178aac7c2e3de018e5f26febbe9'
              })
end

# mv newrelic java agent into place
execute "copy agent to tomcat base" do
    cwd '/usr/share/tomcat7'
    command "rm -rf newrelic && mv /tmp/newrelic ."
    action :run
end


