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
        # get server
        command = "curl -X GET 'https://api.newrelic.com/v2/servers.json' -H 'X-Api-Key:5209987e383b241f4958ff40652fb88dc69b81526febbe9' -d 'filter[name]=#{node[:opsworks][:stack][:name]}-#{node[:opsworks][:instance][:hostname]}'"
        command_out = shell_out(command)
        json = command_out.stdout
        obj = JSON.parse(json)
        Chef::Log.info("*** num servers: #{obj['servers'].size}")
        server_id = -1
        policy_id = -1
        servers = []
        update_policy = '{"alert_policy": {"links": {"servers": [22918797,23203973]}}}'
        if obj["servers"].size > 0
            obj['servers'].each_with_index do |server, index|
                Chef::Log.info("******** serverId: #{server['id']} #{server['name']}")
                if server['name'] == node[:opsworks][:stack][:name] + '-' + node[:opsworks][:instance][:hostname]
                    server_id = server['id'];
                end
            end
            if server_id != -1
                Chef::Log.info("******** serverId: #{server_id}")
                #  get policy info for specified policy name ...
                command = "curl -X GET 'https://api.newrelic.com/v2/alert_policies.json' -H 'X-Api-Key:5209987e383b241f4958ff40652fb88dc69b81526febbe9' -d 'filter[name]=#{node[:opsworks][:stack][:name]}'"
                command_out = shell_out(command)
                json = command_out.stdout
                obj = JSON.parse(json)
                # does policy exist?
                if obj['alert_policies'].size > 0
                    obj['alert_policies'].each_with_index do |policy, index|
                        Chef::Log.info("******** policy name: #{policy['name']}")
                        if policy['name'] == node[:opsworks][:stack][:name]
                            servers = policy['links']['servers']
                            policy_id = policy['id'];
                        end
                    end
                    Chef::Log.info("******** servers assigned to policy: #{servers} policy id: #{policy_id}")
                    s_ids = '';
                    already_in_list = 0
                    servers.each_with_index do |s_id, index|
                        Chef::Log.info("******** server id assoicated with policy: #{s_id}")
                        s_ids += s_id.to_s + ','
                        if s_id == server_id
                             Chef::Log.info("******** server id already in list")
                            already_in_list = 1
                        end
                    end
                    if already_in_list == 0
                        s_ids += server_id.to_s
                    else
                        s_ids.slice!(s_ids.length-1,s_ids.length)
                    end
                    Chef::Log.info("******** server ids to PUT back: #{s_ids}")
                    # build JSON here
                    command = "curl -X PUT 'https://api.newrelic.com/v2/alert_policies/#{policy_id}.json' -H 'X-Api-Key:5209987e383b241f4958ff40652fb88dc69b81526febbe9' -H 'Content-Type: application/json' -d '#{update_policy}'"
                    command_out = shell_out(command)
                    Chef::Log.info("******** curl command: curl -X PUT 'https://api.newrelic.com/v2/alert_policies/#{policy_id}.json' -H 'X-Api-Key:5209987e383b241f4958ff40652fb88dc69b81526febbe9' -H 'Content-Type: application/json' -d '#{update_policy}'")
                else
                    Chef::Log.info("*** No Server Policy #{node[:opsworks][:stack][:name]} not found")
                end
            end
        else
            Chef::Log.info("*** No matching server found for: #{node[:opsworks][:stack][:name]}")
        end
    end
    action :create
end



