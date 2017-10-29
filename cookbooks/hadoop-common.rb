# hosts設定
template "/etc/hosts" do
  owner "root"
  group "root"
  mode "744"
end

package "java-1.8.0-openjdk"
package "java-1.8.0-openjdk-devel"
package "wget"

# Hadoopユーザ
User = "hadoop"
# パスワードはhadoop
Pass = "$6$kBt3hzLQUPBpqG8s$sBiQMYBLRSGuiwC3S.BnfhusawvJAMeb52zqrM0Ne1/qH8JgPXobbEmgvdkWGKtjkys2Ze8I8Q6Z0oSMCyA7B/"
# グループ名はhadoop
Group = "hadoop"

group Group do
  action :create
end

user User do
  home "/usr/hadoop"
  password Pass
  gid Group
end

directory "/usr/hadoop" do
  action :create
  mode "755"
  owner User
  group Group
end

directory "/usr/hadoop/.ssh" do
  action :create
  mode "700"
  owner User
  group Group
end

# Java環境変数の設定
remote_file "/etc/profile.d/java.sh" do
  mode "744"
end

# SSH設定
remote_file "/usr/hadoop/.ssh/id_rsa.pub" do
  mode "644"
  owner User
  group Group
end
remote_file "/usr/hadoop/.ssh/id_rsa" do
  mode "600"
  owner User
  group Group
end
remote_file "/usr/hadoop/.ssh/authorized_keys" do
  source "files/id_rsa.pub"
  mode "600"
  owner User
  group Group
end
execute 'sed -i -e "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config'
service "sshd" do
  action [:restart]
end

# Hadoopインストール 
execute "download hadoop-2-8.1.tar.gz" do
  command "curl -O http://ftp.jaist.ac.jp/pub/apache/hadoop/common/hadoop-2.8.1/hadoop-2.8.1.tar.gz"
  cwd "/tmp"
  not_if "test -e /tmp/download hadoop-2-8.1.tar.gz"
end
execute "extract hadoop" do
  command "tar zxf hadoop-2.8.1.tar.gz -C /usr/hadoop --strip-components 1"
  cwd "/tmp"
  user User
  only_if "test -e /tmp/hadoop-2.8.1.tar.gz"
  not_if "test -d /usr/hadoop/etc"
end
remote_file "/etc/profile.d/hadoop.sh" do
  mode "744"
  owner  "root"
  group  "root"
end

# Hadoopディレクトリ作成
directory "/hadoop" do
  action :create
  mode "775"
  owner User
  group Group
end
directory "/hadoop/hdfs" do
  action :create
  mode "775"
  owner User
  group Group
end
directory "/hadoop/hdfs/data" do
  action :create
  mode "775"
  owner User
  group Group
end
directory "/hadoop/hdfs/name" do
  action :create
  mode "775"
  owner User
  group Group
end
directory "/hadoop/hdfs/jn" do
  action :create
  mode "775"
  owner User
  group Group
end
directory "/hadoop/yarn" do
  action :create
  mode "775"
  owner User
  group Group
end
directory "/hadoop/tmp" do
  action :create
  mode "777"
end

# Hadoop設定ファイル
template "/usr/hadoop/etc/hadoop/yarn-site.xml" do
  owner User
  group Group
  mode "744"
end
template "/usr/hadoop/etc/hadoop/core-site.xml" do
  owner User
  group Group
  mode "744"
end
template "/usr/hadoop/etc/hadoop/hdfs-site.xml" do
  owner User
  group Group
  mode "744"
end
template "/usr/hadoop/etc/hadoop/slaves" do
  owner User
  group Group
  mode "744"
end

