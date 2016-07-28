# Makefile for docker-cmd.sh

SHELL				:= /bin/bash
LN					:= ln
RM					:= rm
MKDIR				:= mkdir
CAT					:= cat
CP					:= cp
GREP				:= grep

# User must run make in the folder which contains this Makefile 
top_dir				:= $(shell pwd)
docker				:= $(shell which docker)
docker_script		:= ${top_dir}/docker-cmd.sh
docker_script_bin	:= ${top_dir}/docker-bin
bashrc				:= ~/.bashrc
bashrc_bk			:= ~/.bashrc.bk

# Makefile use grep and sed to generate available command list
cmd_list			:= $(shell grep -o \
				"docker-[a-z]\{1,\}()\ {" ${docker_script} \
				| sed '/docker-[a-z]\{1,\}()\ {/s/()\ {//g')

define install-cmd
	if [ ! -x "${docker}" ];then \
		echo "No docker cli found in system. Please install docker first."; \
		exit -1; \
	fi
	if [ -d "${docker_script_bin}" ];then \
		$(RM) -rv ${docker_script_bin};	\
	fi
	$(MKDIR) -p ${docker_script_bin} && \
	for cmd in ${cmd_list}; \
	do \
		$(LN) -s "${docker_script}" ${docker_script_bin}/$$cmd; \
	done
	if [ ! -x "${bashrc}" ];then \
		touch ${bashrc}; \
	fi
	if ! ${GREP} -q "${docker_script_bin}" ${bashrc};then \
		$(CP) -v ${bashrc} ${bashrc_bk} && \
		echo '\
		if [ -d "${docker_script_bin}" ] && \
	   		! ${GREP} -q "${docker_script_bin}" <<< $${PATH};then \
   			export PATH="$${PATH}:${docker_script_bin}";\
		else \
			export PATH="$${PATH%%:${docker_script_bin}}";\
		fi' >> ${bashrc}; \
	fi
	. ${bashrc}
endef

define delete-cmd
	if [ -d ${docker_script_bin} ];then 	\
		$(RM) -rvf ${docker_script_bin};	\
	fi
	if [ -f ${bashrc_bk} ] && [ -s ${bashrc_bk} ];then \
		$(RM) -f ${bashrc} && \
		$(CP) ${bashrc_bk} ${bashrc}; \
	fi
	. ${bashrc}
endef

.PHONY: all install clean

all: install

install: ${docker} ${docker_script}
	@$(install-cmd)
	@echo "Docker script commands successfully installed to ${docker_script_bin}."
	@echo "Try docker + TAB in a new shell to see available commands."
clean:
	@$(delete-cmd)
	@echo "Docker script commands uninstalled."
