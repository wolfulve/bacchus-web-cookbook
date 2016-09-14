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

execute "set new relic server policy (in-progress)" do
    command "curl -X GET 'https://api.newrelic.com/v2/servers.json' -H 'X-Api-Key:b45db701025ac3714fa93428a7d3f3fbf3f604abbe56a79' -d 'filter[name]=dev-freq-collection-blueberry' > /tmp/s-policy.json"
    action :run
end

require 'json'

json = File.read('/tmp/s-policy.json')
obj = JSON.parse(json)
server_id = obj["servers"][0]["id"]

Chef::Log.info("******** server JSON file: #{obj} #{server_id}")

obj["servers"].each_with_index do |server, index|
    Chef::Log.info("******** server data: #{server} #{server['id]'} #{server['name']}")
    myId = server[:id]
end

Chef::Log.info("******** serverId: #{myId}")

ruby_block "something" do
    block do
        #tricky way to load this Chef::Mixin::ShellOut utilities
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        command = "curl -X GET 'https://api.newrelic.com/v2/servers.json' -H 'X-Api-Key:b45db701025ac3714fa93428a7d3f3fbf3f604abbe56a79' -d 'filter[name]=dev-freq-collection-blueberry'"
        command_out = shell_out(command)
        node.set['abc'] = command_out.stdout
    end
    action :create
end


Chef::Log.info("******** server JSON: #{node[:abc]}")