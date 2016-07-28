# Description
  This docker command script combines some frequently used docker operations as one command.
  Each operation in this script file is soft-linked as a docker command in format  
  'docker-\*', in order to distinguish from docker cli. For example, the command 'docker-ip' 
  is a soft link to docker-cmd.sh which performs an operation that lists IP address of a 
  container in host environment. 

# Usage
## Install
  1. cd into docker-cmd dir
  2. run make install
  3. run a new shell and try available commands in the new shell

## Uninstall
  1. cd into docker-cmd dir
  2. run make clean

