include_recipe "hadoop::nn"


  hops_path = "#{Chef::Config[:file_cache_path]}/hops.sql"
  template hops_path do
    source "hops.sql.erb"
    owner "root" 
    mode "0755"
    notifies :install_hops, "hops_ndb[install]", :immediately 
  end
