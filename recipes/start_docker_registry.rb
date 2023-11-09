# To be able to reconfigure the docker registry and make this recipe
# idempotent, we should stop and remove the existing docker registry
# before starting it again in the next step
bash "stop_docker_registry" do
    user "root"
    code <<-EOF
      docker stop registry
      docker rm registry
    EOF
    only_if "docker container inspect registry"
end

# we are root, using kagent's certificate should be ok
kagent_crypto_dir = x509_helper.get_crypto_dir(node['kagent']['user'])
certificate_name = x509_helper.get_certificate_bundle_name(node['kagent']['user'])
key_name = x509_helper.get_private_key_pkcs8_name(node['kagent']['user'])

registry_storage_configuration = ""
if node['hops']['docker']['registry']['storage'].casecmp("s3") == 0
  registry_storage_configuration = "-e REGISTRY_STORAGE=s3 " + 
      "-e REGISTRY_STORAGE_S3_REGION=#{node['hops']['docker']['registry']['region']} " +
      "-e REGISTRY_STORAGE_S3_BUCKET=#{node['hops']['docker']['registry']['bucket']} " +
      "-e REGISTRY_STORAGE_S3_ROOTDIRECTORY=#{node['hops']['docker']['registry']['path']} "

  if !node['hops']['docker']['registry']['endpoint'].eql?("")
    registry_storage_configuration = "#{registry_storage_configuration} -e REGISTRY_STORAGE_S3_REGIONENDPOINT=#{node['hops']['docker']['registry']['endpoint']} "
  end

  if !node['hops']['docker']['registry']['access_key'].eql?("")
    registry_storage_configuration = "#{registry_storage_configuration}" +
      "-e REGISTRY_STORAGE_S3_ACCESSKEY=#{node['hops']['docker']['registry']['access_key']} " +
      "-e REGISTRY_STORAGE_S3_SECRETKEY='#{node['hops']['docker']['registry']['secret_key']}' "
  end
end

mount_volumes = ["-v #{kagent_crypto_dir}:/certs", "-v #{node['hops']['data_volume']['docker_registry']}:/var/lib/registry"]

unless node['hops']['docker']['registry']['mount_volumes'].empty?
  mounts = node['hops']['docker']['registry']['mount_volumes'].split(";")
  mounts.each { |x|
    mount_volumes.append("-v #{x}")
  }
end
volumes = mount_volumes.join(" ")

#start docker registry
bash "start_docker_registry" do
  user "root"
  code <<-EOF
    docker run -d \
              --restart=always \
              --name registry \
              --network=host \
              #{volumes} \
              -e REGISTRY_STORAGE_DELETE_ENABLED=true \
              -e REGISTRY_HTTP_ADDR=0.0.0.0:#{node['hops']['docker']['registry']['port']} \
              -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/#{certificate_name} \
              -e REGISTRY_HTTP_TLS_KEY=/certs/#{key_name} \
              -e REGISTRY_HTTP_TLS_MINIMUMTLS=tls1.2 \
              #{registry_storage_configuration} \
              registry
  EOF
end