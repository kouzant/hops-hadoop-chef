hdfs_user_home = conda_helpers.get_user_home(node['hops']['hdfs']['user'])
if not node['hops']['aws_access_key_id'].eql?("") and not node['hops']['aws_secret_access_key'].eql?("")
  directory "#{hdfs_user_home}/.aws" do
    owner node['hops']['hdfs']['user']
    group node['hops']['group']
    mode "0755"
    action :create
  end
  
  template "#{hdfs_user_home}/.aws/credentials" do
    source "credentials.erb"
    owner node['hops']['hdfs']['user']
    group node['hops']['group']
    mode "600"
    action :create
  end
end