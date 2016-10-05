#! /bin/bash
#
# This docker command script combines some frequently used docker operations as one command.
# Each operation in this script file is soft-linked as a docker command in format  
# 'docker-*', in order to distinguish from docker cli. For example, the command 'docker-ip' 
# is a soft link to docker-cmd.sh which performs an operation that lists IP address of a 
# container in host environment. 
#
# When the docker-cmd.sh is executed, it will invoke functions based on from which soft-link 
# it is invoked. 
#

# Should use 'which docker' to get docker cli executable
# You may need to change this to your real docker binary's location
docker=$(which docker)

if [ ! -x "$docker" ];then
    echo "Can't find docker command in system. Please install docker first."
    exit -1
fi

# Go format template
ip_addr='{{ .NetworkSettings.IPAddress }}'
pid='{{ .State.Pid }}'

# ################ commands #################### 
# Note that since Makefile use sed pattern to match functions defined here, 
#the blank between ")" and "{" is essential

# docker-bash:  execute bash in container
# param:        <container's ID>
docker-bash() {
    exec $docker exec -it $1 bash
    return $?
}

# docker-help:  show help info of this script or a command
# param:        <command name>, give help info about a command
# param:        <null>, give overall help info about this script
docker-help() {
    echo "TODO"
    return $?
}

# docker-log:   show log of most resently created containers
docker-log() {
    exec sudo $docker logs $(sudo $docker ps -lq )
}

# docker-ip:    show container's IP address
# param:        <container ID list>
docker-ip() {
   exec $docker inspect --format "${ip_addr}" "$@"
   return $?
}
# docker-pid:   show container's PID
# param:        <container ID list>
docker-pid() {
    exec $docker inspect --format "${pid}" "$@"
    return $?
}

# docker-rmi:   delete specified images
# param:        -d delete all dangling images
# param:        -a delete all images
docker-rmi() {
    parsed_opt=`getopt -o adh -n "$0" -- "$@"`
    # parse option failed
    if [ $? != 0 ]; then echo "Parsing option failed. Terminating..." >&2 ; exit 1; fi
    
    eval set -- "$parsed_opt"

    while true; do
        case "$1" in
            -a)
                delete="all"
                shift 1 ;;
            -d)
                delete="dangling"
                shift 1 ;;
            -h) docker-help $0;
                shift ; exit 0;;
            --) shift ; break ;;
            *)  echo " Internal error!" ; exit 127
        esac
    done
    if [ "$delete" == "all" ];then
        echo "This will delete all images. Are you sure? (Y|N) "
        read line
        case "$line" in
            YES|Yes|yes|Y|y)
                exec sudo $docker rmi $(sudo docker images -q -a); 
                exit $?
            ;;
            NO|No|no|N|n) 
                break
            ;;
            *)  echo "Only yes or no accepted."; 
                exit 0
            ;;
        esac
    elif [ "$delete" == "dangling" ];then
        exec sudo $docker rmi $(sudo docker images -q --filter "dangling=true")
        exit  $?
    fi
}

# docker-rm: delete specified containers
# param: -x delete exited containers
# param: -a delete all containers
# param: -i <image ID> delete containers created from specified image
# param: -h show help info abour docker-rm
docker-rm() {
    parsed_opt=`getopt -o afhi:x -n "$0" -- "$@"`
    # parse option failed
    if [ $? != 0 ] ; then echo "Parsing option failed. Terminating..." >&2 ; exit 1 ; fi

    eval set -- "$parsed_opt"

    while true;do
    	case "$1" in
    		-a) 
    		    	delete="all"
    			shift; break;;
		-f)
		    	force="true"
			shift; break;;	
    		-i) 
               	 	delete="from_image"
               	 	delete_from_image=$2
    			shift 2; break;;
    		-h) 	
			docker-help $0 	
			shift; exit 0;;
            # delimter of non-option arguments
            	-x) 
               		delete="exited"
    			shift 1; break;;
    		--) 
			shift; break ;;	
    		*) 
			echo " Internal error!" ; exit 127 ;;
    	esac
    done
    
    if [ "$delete" == "exited" ];then
        exec sudo $docker rm $(sudo $docker ps -a |grep Exited |awk '{print $1}' )
        return $?
    elif [ "$delete" == "all" ];then
        echo "This will delete all containers. Are you sure? ( Y|N )"
        read line 
        case "$line" in
            YES|Yes|yes|Y|y)
                exec sudo $docker rm  -f $(sudo $docker ps -aq )  
            break;;
            NO|No|no|N|n) break;;
            *) echo "Only yes or no accepted."; exit 0;;
        esac
        return $?
    elif [ "$delete" == "from_image" ];then
	containers=`sudo docker ps -aq`
	for cid in $containers;do
		status=`sudo $docker inspect --format={{ .State.Status }} $cid`
		if [ "running" == "$status" ];then
			if ["$forced" == "true" ];then
				echo "This will delete running container $cid from image: $delete_from_image. Are you sure? ( Y|N )"
				read line
				case "$line" in
             				YES|Yes|yes|Y|y)
       						exec sudo $docker rm $cid
            					break;;
            				NO|No|no|N|n) break;;
            				*) echo "Only yes or no accepted."; exit 0;;
				esac
        			return $?
			else
				echo "Could not delete running containers. Use -f to force deletion"
				exit -1
			fi
		else
				exec sudo $docker rm $cid
		fi
	done
    fi
}

# ################### Main ############################

docker_cmd=${0##/*/}         # get command name from full path

case ${docker_cmd} in
    'docker-bash') docker-bash "$1"
    if [ !$? ];then 
        echo "error, docker-bash returned $?"
        exit -1; 
    fi 
    break;;
    'docker-help') docker-help "$@"
    break;;
    'docker-ip') docker-ip "$@"
    if [ !$? ];then 
        echo "error in getting ip address"
        exit -1; 
    fi 
    break;;
    'docker-log') docker-log
    break;;
    'docker-pid') docker-pid "$@"
    break;;
    'docker-rm') docker-rm "$@"
    break;;
    'docker-rmi') docker-rmi "$@"
    break;;
    *) echo "no such command"; exit 127 ;;
esac
