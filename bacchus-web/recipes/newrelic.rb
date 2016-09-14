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


execute "install new relic repo" do
    cwd '/tmp'
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

require 'json'

ruby_block "add the server id to the associated policy list" do
    block do
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
#        command = "curl -X GET 'https://api.newrelic.com/v2/servers.json' -H 'X-Api-Key:b45db701025ac3714fa93428a7d3f3fbf3f604abbe56a79' -d 'filter[name]=dev-freq-collection-blueberry'"
        command = "curl -X GET 'https://api.newrelic.com/v2/servers.json' -H 'X-Api-Key:5209987e383b241f4958ff40652fb88dc69b81526febbe9' -d 'filter[name]=test-stack4-magic2'"
        command_out = shell_out(command)
        json = command_out.stdout
        obj = JSON.parse(json)
        server_id = obj["servers"][0]["id"]
        server_name = obj["servers"][0]["name"]
        Chef::Log.info("******** Server Id: #{server_id} Name: #{server_name} #{obj} #{server_id}")
#        get policy info ...
        command = "curl -X GET 'https://api.newrelic.com/v2/alert_policies.json' -H 'X-Api-Key:5209987e383b241f4958ff40652fb88dc69b81526febbe9' -d 'filter[name]=#{node[:opsworks][:stack][:name]}'"
        command_out = shell_out(command)
        json = command_out.stdout
        obj = JSON.parse(json)[0]
        num_servers = obj['alert_policies'][0]['links'][0]['servers'].size;
        Chef::Log.info("******** policies: #{obj} #{num_servers}")
#       add server id to list of servers
#       post JSON back to newrelic
    end
    action :create
end



