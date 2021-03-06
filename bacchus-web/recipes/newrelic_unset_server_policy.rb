#
# Cookbook Name:: systems
# Recipe:: newrelic_delete_server_policy
#
# Copyright (C) 2016 Frequency
#
# All rights reserved - Do Not Redistribute
#
#
require 'json'

api_key = '5209987e383b241f4958ff40652fb88dc69b81526febbe9'

ruby_block "remove the application id from the associated policy" do
    block do
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        # get server
        command = "curl -X GET 'https://api.newrelic.com/v2/servers.json' -H 'X-Api-Key:#{api_key}' -d 'filter[name]=#{node[:opsworks][:stack][:name]}-#{node[:opsworks][:instance][:hostname]}'"
        command_out = shell_out(command)
        json = command_out.stdout
        obj = JSON.parse(json)
        Chef::Log.info("*** num servers: #{obj['servers'].size}")
        server_id = -1
        policy_id = -1
        servers = []
        update_policy = '{"alert_policy": {"links": {"servers": [*]}}}'
        if obj["servers"].size > 0
            obj['servers'].each_with_index do |server, index|
                Chef::Log.info("******** serverId: #{server['id']} #{server['name']}")
                if server['name'] == node[:opsworks][:stack][:name] + '-' + node[:opsworks][:instance][:hostname]
                    server_id = server['id'];
                end
                break if server_id > -1
            end
            if server_id != -1
                Chef::Log.info("******** serverId: #{server_id}")
                #  get policy info for specified policy name ...
                command = "curl -X GET 'https://api.newrelic.com/v2/alert_policies.json' -H 'X-Api-Key:#{api_key}' -d 'filter[name]=#{node[:opsworks][:stack][:name]}&filter[type]=server'"
                command_out = shell_out(command)
                json = command_out.stdout
                obj = JSON.parse(json)
                # does policy exist?
                if obj['alert_policies'].size > 0
                    obj['alert_policies'].each_with_index do |policy, index|
                        Chef::Log.info("******** policy name: #{policy['name']} id: #{policy['id']}")
                        if policy['name'].downcase == node[:opsworks][:stack][:name].downcase && policy['type'] == 'server'
                            servers = policy['links']['servers']
                            policy_id = policy['id'];
                        end
                    end
                    Chef::Log.info("******** servers assigned to policy: #{servers} policy id: #{policy_id}")
                    s_ids = '';
                    in_list = 0
                    servers.each_with_index do |s_id, index|
                        Chef::Log.info("******** server id assoicated with policy: #{s_id}")
                        if s_id != server_id
                            s_ids += s_id.to_s + ','
                            else
                            in_list = 1
                        end
                    end
                    if in_list == 1
                        s_ids.slice!(s_ids.length-1,s_ids.length)
                        update_policy['*'] = s_ids
                        Chef::Log.info("******** server ids to PUT back: #{s_ids}")
                        command = "curl -X PUT 'https://api.newrelic.com/v2/alert_policies/#{policy_id}.json' -H 'X-Api-Key:#{api_key}' -H 'Content-Type: application/json' -d '#{update_policy}'"
                        command_out = shell_out(command)
                        #                        Chef::Log.info("******** curl command: curl -X PUT 'https://api.newrelic.com/v2/alert_policies/#{policy_id}.json' -H 'X-Api-Key:b45db701025ac3714fa93428a7d3f3fbf3f604abbe56a79' -H 'Content-Type: application/json' -d '#{update_policy}'")
                    end
                    else
                    Chef::Log.info("*** No Server Policy #{node[:opsworks][:stack][:name]} found")
                end
            end
            else
            Chef::Log.info("*** No matching server found for: #{node[:opsworks][:stack][:name]}")
        end
    end
    action :create
end


