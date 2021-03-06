default[:hadoop][:hadoop_handle] = 'hadoop-0.20'
set[:hadoop][:cdh_version]   = 'cdh3b1'

default[:hadoop][:cluster_reduce_tasks]       = 57
default[:hadoop][:dfs_replication]            = 3
default[:groups]['hadoop'    ][:gid]          = 300
default[:groups]['supergroup'][:gid]          = 301

#
# For ebs-backed volumes (or in general, machines with small or slow root
# volumes), you may wish to exclude the root volume from consideration
#
default[:hadoop][:use_root_as_scratch_vol]    = true
default[:hadoop][:use_root_as_persistent_vol] = false

#
# Tune cluster settings for size of instance
#
# NOTE: the below assumes EC2 instances with EBS-backed volumes
#
case node[:ec2][:instance_type]
when 'm1.xlarge', 'c1.xlarge'
  hadoop_performance_settings = {
    :max_map_tasks        => 8,
    :max_reduce_tasks     => 4,
    :java_child_opts      => '-Xmx680m',
    :java_child_ulimit    => 1392640,
  }
when 'm1.large'
  hadoop_performance_settings = {
    :max_map_tasks        => 4,
    :max_reduce_tasks     => 2,
    :java_child_opts      => '-Xmx1024m',
    :java_child_ulimit    => 2097152,
  }
when 'c1.medium'
  hadoop_performance_settings = {
    :max_map_tasks        => 4,
    :max_reduce_tasks     => 2,
    :java_child_opts      => '-Xmx550m',
    :java_child_ulimit    => 1126400,
  }
else # 'm1.small'
  hadoop_performance_settings = {
    :max_map_tasks        => 2,
    :max_reduce_tasks     => 1,
    :java_child_opts      => '-Xmx550m',
    :java_child_ulimit    => 1126400,
  }
end

hadoop_performance_settings[:local_disks]=[]
[ [ '/mnt',  'block_device_mapping_ephemeral0'],
  [ '/mnt2', 'block_device_mapping_ephemeral1'],
  [ '/mnt3', 'block_device_mapping_ephemeral2'],
  [ '/mnt4', 'block_device_mapping_ephemeral3'],
].each do |mnt, ephemeral|
  dev_str = node[:ec2][ephemeral]
  hadoop_performance_settings[:local_disks] << [mnt, '/dev/'+dev_str] unless dev_str.blank?
end
Chef::Log.info(hadoop_performance_settings.inspect)

hadoop_performance_settings.each{|k,v| set[:hadoop][k] = v }
