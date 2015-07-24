# rchk-image

This repository contains scripts to set up and configure a virtual machine
with installed [rchk](http://www.github.com/kalibera/rchk), a set of
bug-finding tools for the source code of [GNU-R](http://www.r-project.org/). 
The virtual machine is further set up for periodic execution of the checking
tools on recent versions of GNU-R.  The results are automatically pushed to
[rdevchk](http://www.github.com/kalibera/rdevchk) and are somewhat
post-processed.  The post-processing currently includes detecting errors
possibly introduced or fixed between consecutive R versions and linking the
error messages to R source code for easy navigation in a web browser.

To install the virtual machine, one needs [vagrant](https://www.vagrantup.com/) and
[virtualbox](https://www.virtualbox.org/). On Ubuntu 15.04, these simply do

```
apt-get -s install virtualbox vagrant
```

Then, customize `private.yml` file (provide your repository URL for
publishing the results).  Then, run vagrant as

```
vagrant up --provider virtualbox
```

in the root directory of the project (where `Vagrantfile` is). The first
invocation will take long, because the script will be downloading a base
installation of Ubuntu and then installing a lot of packages to it which are
needed to build R. Once it finishes, do 

```vagrant ssh```

to login into the newly created VM. See the script `run_rchk.sh` in the home
directory of the default user (`vagrant`) in the VM on how to build R for
`rchk` and how to run `rchk` tools on it.  Run the script to download and
check the latest version of GNU-R.  The `publish_results.sh` script then
does the post-processing and pushing the results out of the VM.  To run the
checking periodically from cron, modify `config.yml` accordingly and re-run
the provisioning with

```vagrant provision```

It will run already fast, not repeating the steps done before.
