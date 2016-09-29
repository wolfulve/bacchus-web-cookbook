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
        app_id = -1
        update_policy = '{"alert_policy": {"links": {"applications": [*]}}}'
        
        node["opsworks"]["applications"].each_with_index do |application, index|
            Chef::Log.info("******** Application: #{application[:name]}, type: #{application[:application_type]} (#{index+1}/#{node[:opsworks][:applications].size})")
            if application[:application_type] == 'java'
                app_name = node[:opsworks][:stack][:name] + '-' + application[:name];
                
                if app_name != ''
                    Chef::Log.info("******** appname: #{app_name}")
                    command = "curl -X GET 'https://api.newrelic.com/v2/alert_policies.json' -H 'X-Api-Key:#{api_key}' -d 'filter[name]=#{app_name}'"
                    command_out = shell_out(command)
                    json = command_out.stdout
                    obj = JSON.parse(json)
                    Chef::Log.info("******** matching policies: #{obj['alert_policies'].size} #{node[:opsworks][:stack][:name]}-#{app_name}")
                    if obj['alert_policies'].size > 0
                        obj['alert_policies'].each_with_index do |policy, index|
                            Chef::Log.info("******** policy name: #{policy['name']} id: #{policy['id']}")
                            if policy['name'].downcase == app_name.downcase && policy['type'] == 'application'
                                applications = policy['links']['applications']
                                policy_id = policy['id'];
                                Chef::Log.info("******** found application policy for app")
                            end
                        end
                        
                        if policy_id != -1
                            # call API to get applications and match by exact name (have to iterate because of name substring matches,  save app ID
                            command = "curl -X GET 'https://api.newrelic.com/v2/applications.json' -H 'X-Api-Key:#{api_key}' -d 'filter[name]=#{app_name}'"
                            command_out = shell_out(command)
                            json = command_out.stdout
                            obj = JSON.parse(json)
                            obj['applications'].each_with_index do |app, index|
                                Chef::Log.info("******** app name: #{app['name']} id: #{app['id']}")
                                if app['name'].downcase == app_name.downcase
                                    app_id = app['id'];
                                    Chef::Log.info("******** appId: #{app_id}")
                                end
                            end
                            
                            if app_id != -1
                                Chef::Log.info("******** applications assigned to policy: #{applications} policy id: #{policy_id}")
                                a_ids = '';
                                in_list = 0
                                applications.each_with_index do |a_id, index|
                                    Chef::Log.info("******** app id assoicated with policy: #{a_id}")
                                    a_ids += a_id.to_s + ','
                                    if a_id == app_id
                                        Chef::Log.info("******** app id already in list")
                                        in_list = 1
                                    end
                                    break if in_list == 1
                                end
                                # send update if needed
                                if in_list == 1
                                    a_ids.slice!(a_ids.length-1,a_ids.length)
                                    update_policy['*'] = a_ids
                                    Chef::Log.info("******** app ids to PUT back: #{a_ids}")
                                    command = "curl -X PUT 'https://api.newrelic.com/v2/alert_policies/#{policy_id}.json' -H 'X-Api-Key:#{api_key}' -H 'Content-Type: application/json' -d '#{update_policy}'"
                                    command_out = shell_out(command)
                                    #                        Chef::Log.info("******** curl command: curl -X PUT 'https://api.newrelic.com/v2/alert_policies/#{policy_id}.json' -H 'X-Api-Key:b45db701025ac3714fa93428a7d3f3fbf3f604abbe56a79' -H 'Content-Type: application/json' -d '#{update_policy}'")
                                end
                            end
                        end
                    end
                end
            end
        end
        
    end
    action :create
end


