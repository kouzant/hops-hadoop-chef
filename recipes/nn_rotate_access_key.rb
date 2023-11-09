include_recipe "hops::_aws_credentials"

systemd_unit "namenode.service" do
    action :restart
end

bash 'wait-for-namenode' do
    user node['hops']['hdfs']['user']
    group node['hops']['group']
    timeout 260
    code <<-EOH
      # Wait for local NameNode to start and to leave SafeMode
      #{node['hops']['bin_dir']}/nn-waiter.sh
    EOH
    not_if { node["install"]["secondary_region"].casecmp?("true") }
end