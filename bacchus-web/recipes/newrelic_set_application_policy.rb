#
# Cookbook Name:: systems
# Recipe:: newrelic_set_server_policy
#
# Copyright (C) 2016 Frequency
#
# All rights reserved - Do Not Redistribute
#
#
require 'json'

api_key = '5209987e383b241f4958ff40652fb88dc69b81526febbe9'

ruby_block "add the server id to the associated policy" do
    block do
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)

        server_id = -1
        policy_id = -1
        applications = []
        app_name = ''
        update_policy = '{"alert_policy": {"links": {"servers": [*]}}}'
        
        node["opsworks"]["applications"].each_with_index do |application, index|
            Chef::Log.info("******** Application: #{application[:name]}, type: #{application[:application_type]} (#{index+1}/#{node[:opsworks][:applications].size})")
            if application[:application_type] == 'java'
                    app_name = node[:opsworks][:stack][:name] + '-' + application[:name];
                     Chef::Log.info("******** appname: #{app_name}")
                    if app_name != ''
                        command = "curl -X GET 'https://api.newrelic.com/v2/alert_policies.json' -H 'X-Api-Key:#{api_key}' -d 'filter[name]=#{node[:opsworks][:stack][:name]}-#{app_name}'"
                        command_out = shell_out(command)
                        json = command_out.stdout
                        obj = JSON.parse(json)
                        if obj['alert_policies'].size > 0
                            obj['alert_policies'].each_with_index do |policy, index|
                                Chef::Log.info("******** policy name: #{policy['name']} id: #{policy['id']}")
                                if policy['name'].downcase == app_name.downcase && policy['type'] == 'application'
                                    applications = policy['links']['applications']
                                    policy_id = policy['id'];
                                    Chef::Log.info("******** found application policy for app")
                                end
                            end

                    end
        
                end
            end
        end

    end
    action :create
end


