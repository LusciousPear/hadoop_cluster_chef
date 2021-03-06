#
# Cookbook Name:: hadoop_cluster
# Recipe::        make_standard_hdfs_dirs
#
# Copyright 2010, Infochimps, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Make the standard HDFS directories:
#
#   /tmp
#   /user
#   /user/hive/warehouse
#
# and
#
#   /user/USERNAME
#
# for each user in the 'supergroup' group.
#
# I'd love feedback on whether this can be made less kludgey,
# and whether the logic for creating the user dirs makes sense.

# This is a bit kludgey, but it minimizes hits to the HDFS
# Also, quoting Tom White:
#   "The [chmod +w] is questionable, as it allows a user to delete another
#    user. It's needed to allow users to create their own user directories"
execute 'create user dirs on HDFS' do
  only_if "service hadoop-0.20-namenode status"
  not_if do File.exists?("/mnt/hadoop/logs/made_initial_dirs.log") end
  user 'hadoop'
  command %Q{
    hadoop_users=/user/"`grep supergroup /etc/group | cut -d: -f4 | sed -e 's|,| /user/|g'`" ;
    hadoop fs -mkdir    /tmp /user /user/hive/warehouse $hadoop_users;
    hadoop fs -chmod +w /tmp /user /user/hive/warehouse;
    for user in $hadoop_users ; do
      hadoop fs -chown ${user#/user/} $user;
    done ;
    touch /mnt/hadoop/logs/made_initial_dirs.log ;
  }
end
