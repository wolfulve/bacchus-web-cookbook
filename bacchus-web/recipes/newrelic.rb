#
# Cookbook Name:: systems
# Recipe:: newrelic
#
# Copyright (C) 2015 Frequency
#
# All rights reserved - Do Not Redistribute
#
#

execute "what am i" do
    time = Time.now.to_i
    cwd '/tmp'
    command "mkdir -p freq-cb_systems_newrelic_#{time}"
    action :run
end

#
# todo: execute conditionally based on layer type, e.g., java-app, nodejs-app etc
# start agent install
execute "fetch agent and unzip" do
    cwd '/tmp'
    package = 'newrelic-java.zip'
    command "aws s3 cp s3://elasticbeanstalk-us-west-2-227102987351/bacchus/#{package} . && unzip -o #{package}"
    action :run
end

# set app name
template "/tmp/newrelic/newrelic.yml" do
    source "newrelic.yml.erb"
    owner "root"
    group "root"
    mode 0644
end


execute "copy agent to tomcat base" do
    cwd '/usr/share/tomcat7'
    command "rm -rf newrelic && mv /tmp/newrelic ."
    action :run
end
# end agent install

log 'message' do
    message '************************ A message add to the log. #{node[:opsworks][:instance][:instance_type]}'
    level :info
end

execute "install new relic repo" do
    cwd '/tmp'
#    command "rm -rf /tmp/newrelic-repo-5-3.noarch.rpm && rm -rf /etc/yum.repos.d/newrelic.repo && yum -y remove newrelic-repo-5-3 newrelic-sysmond && rm -rf /etc/newrelic/* && aws s3 cp s3://freq-cb-repo/newrelic-repo-5-3.noarch.rpm . && rpm -Uvh /tmp/newrelic-repo-5-3.noarch.rpm"
    command "rm -rf /tmp/newrelic-repo-5-3.noarch.rpm && rm -rf /etc/yum.repos.d/newrelic.repo && yum -y remove newrelic-repo-5-3 newrelic-sysmond && rm -rf /etc/newrelic/* && aws s3 cp s3://elasticbeanstalk-us-west-2-227102987351/bacchus/newrelic-repo-5-3.noarch.rpm . && rpm -Uvh /tmp/newrelic-repo-5-3.noarch.rpm"
    action :run
end

execute "install new relic via yum" do
    command "yum -y install newrelic-sysmond"
    action :run
end

execute "configure new relic" do
    command "nrsysmond-config --set license_key=221e63f2ee0ed178aac7c2e3de018e5f26febbe9"
    action :run
end

template "/etc/newrelic/nrsysmond.cfg" do
    source "nrsysmond.cfg.erb"
    owner "newrelic"
    group "newrelic"
    mode 0644
end

service "newrelic-sysmond" do
    action [:enable, :restart]
end