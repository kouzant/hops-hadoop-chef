include_recipe "hops::_aws_credentials"

systemd_unit "datanode.service" do
    action :restart
end