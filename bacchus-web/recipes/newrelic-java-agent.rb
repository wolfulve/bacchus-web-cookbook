
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

# todo: Frequency only deploys 1 Java app per instance at this time, so this is ok for now
# can generalize this later for other agents
# this is run on "deploy" as we need to get the app name
node[:deploy].each_with_index do |(application, deploy), index|
    if deploy[:application_type] == 'java'
        Chef::Log.info("******** Deploying java application: #{application}, app#: #{index+1}")
#        Chef::Log.info("******** Deploying java application #{application}")
        app_name = node[:opsworks][:stack][:name] + '-' + application
    end
end

execute "fetch agent and unzip" do
    cwd '/tmp'
    package = 'newrelic-java-agent.zip'
    command "aws s3 cp s3://elasticbeanstalk-us-west-2-227102987351/bacchus/#{package} . && unzip -o #{package}"
    action :run
end

# set app name
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


