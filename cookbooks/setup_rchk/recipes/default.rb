require 'yaml'

# read configuration

configfile = "/vagrant/config.yml"
unless File.exists? configfile
    raise "config.yml does not exist!"
end

privfile = "/vagrant/private.yml"
unless File.exists? configfile
    raise "private.yml does not exist!"
end

yamlconfig = YAML.load_file configfile
yamlpriv = YAML.load_file privfile

def read_fixnum_var(config, varname)
  if config.has_key? varname
    res = config[varname]
    unless res.class == Fixnum
      raise "config error (#{configgile})): ${varname} must be a number"
    end
    return res
  else
    return 0
  end
end

bcheck_max_states = read_fixnum_var(yamlconfig, "bcheck_max_states")
callocators_max_states = read_fixnum_var(yamlconfig, "callocators_max_states")
checking_timeout_mins = read_fixnum_var(yamlconfig, "checking_timeout_mins")

setup_cron = yamlconfig["setup_cron"]
cron_hour = yamlconfig["cron_hour"]
cron_minute = yamlconfig["cron_minute"]

publish_repo = yamlpriv["publish_repo"]

# install some packages

username = nil
["vagrant", "ubuntu"].each do |user|
  res = `grep "^#{user}" /etc/passwd`
  username = user unless res.empty?
end

execute "apt-get update" do
  command "apt-get update"
  user "root"
  action :run
  not_if 'find /var/lib/apt/periodic/update-success-stamp -mmin -180 | grep update-success-stamp'
    # do not run if updated less than 3 hours ago
end

execute "install R (dev) build deps" do
  command "apt-get build-dep -y r-base-dev"
  user "root"
  action :run
  not_if 'dpkg --get-selections | grep -q "^xvfb\s"'
end

directory "/opt" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end

# install LLVM

llvmtarbase = "clang+llvm-3.6.1-x86_64-linux-gnu-ubuntu-15.04.tar.xz"
llvmtarfile = "/opt/#{llvmtarbase}"
llvmdir = "/opt/clang+llvm-3.6.1-x86_64-linux-gnu"

remote_file llvmtarfile do
  source "http://llvm.org/releases/3.6.1/#{llvmtarbase}"
  not_if {File.exists?("#{llvmdir}/bin/clang")}
end

execute "unpack LLVM" do
  command "tar xf #{llvmtarfile}"
  cwd "/opt"
  user "root"
  action :run
  not_if {File.exists?("#{llvmdir}/bin/clang")}
end

file llvmtarfile do
  action :delete
end

# install whole-program-llvm

git "/opt/whole-program-llvm" do
  repository "git://www.github.com/kalibera/whole-program-llvm"
  revision "master"
  action :export
  user "root"
  not_if {File.exists?("/opt/rchk/whole-program-llvm")}
end

# install rchk

["g++-4.8","gcc-4.8-locales"].each do |pkg|
  package pkg do
    action :install
    not_if 'dpkg --get-selections | grep -q "^#{pkg}\s"'
  end
end

rchkdir = "/opt/rchk"
bcheck = "#{rchkdir}/src/bcheck"
maacheck = "#{rchkdir}/src/maacheck"

git rchkdir do
  repository "git://www.github.com/kalibera/rchk"
  revision "master"
  action :export
  user "root"
  not_if {File.exists?("#{rchkdir}/src")}
end

makeargs = ""
if bcheck_max_states > 0
  makeargs.concat("BCHECK_MAX_STATES=#{bcheck_max_states}")
end
if callocators_max_states > 0
  makeargs.concat(" CALLOCATORS_MAX_STATES=#{callocators_max_states}")
end

execute "make rchk" do
  command "make LLVM=#{llvmdir} CXX=g++-4.8 #{makeargs}"
  cwd "#{rchkdir}/src"
  user "root"
  action :run
  not_if {File.exists?(bcheck)}
end

# install more packages

["subversion","git"].each do |pkg|
  package pkg do
    action :install
    not_if 'dpkg --get-selections | grep -q "^#{pkg}\s"'
  end
end

# copy scripts

["run_rchk.sh", "publish_results.sh"].each do |file|
  remote_file "/home/#{username}/#{file}" do
    owner username
    group username
    mode "0755"
    source "file:///vagrant/#{file}"
    action :create_if_missing
  end
end

execute "fill in publish repository" do
  command "sed -i -e 's|___PUBLISH_REPO___|#{publish_repo}|g' /home/#{username}/publish_results.sh"
  user username
  action :run
  #only_if 'grep -q ___PUBLISH_REPO___ /home/#{username}/publish_results.sh'
end

# set up periodic checking

if setup_cron
  cron "periodic_checking" do
    command "cd /home/#{username} && /usr/bin/timeout -k 5 #{checking_timeout_mins}m ./run_rchk.sh >>/home/#{username}/periodic_rchk.out 2>&1" +
            " && cd /home/#{username} && /usr/bin/timeout -k 5 10m ./publish_results.sh >>/home/#{username}/publish_results.out 2>&1"
             
    user username
    action :create
    hour cron_hour
    minute cron_minute
  end
end

