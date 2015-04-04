#!/bin/bash
#
# Copyright (C) 2008-2009 SecurixLive   <dev@securixlive.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License Version 2 as
# published by the Free Software Foundation.  You may not use, modify or
# distribute this program under any other version of the GNU General
# Public License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#
# Description:
#   Handling of the installation, configuration, fixing and uninstallation of
# the mysql package and dependancies. mysql is a dependancy for sguild.
#

nsm_package_mysql_required_options()
{
	print_all "mysql has no required options to be configured" 2
}

nsm_package_mysql_download()
{
   	prompt_user_yesno "" "Download mysql packages(s)?" "Y"
   	[ ${?} -ne 0 ] && return 1

	# check if we are a ubuntu or debian system
	is_ubuntu || is_debian
    if [ ${?} -eq 0 ]
    then

        # use native package manager apt-get
		CMD="apt-get -y -d install mysql-server"
		print_all "Downloading with: ${CMD}" 2
		system_log "${CMD}"
        return $?
	fi

    # check if we are a redhat'ish system
	is_fedora || is_rhel || is_centos
    if [ ${?} -eq 0 ]
    then

        # use native package manager yum
		cmd="yum --downloadonly -y install mysql-server"
		print_all "Downloading with: ${CMD}" 2
		system_log "${CMD}"
        return $?
	fi
        
	print_all "Not sure how to download mysql on this system." 1
	return 1
}

nsm_package_mysql_reconfigure()
{
    # only debian/ubuntu systems need configuring at this stage
    is_ubuntu || is_debian
    if [ ${?} -eq 0 ]
    then
    	# check it's running
    	print_all "Ensuring mysql is stopped" 2

    	# ensure mysql is stopped whilst configuring
    	mysql_is_running
    	if [ ${?} -eq 0 ]
    	then
    		mysql_stop
    		[ ${?} -ne 0 ] && return 1
    	fi

		# execute dpkg-reconfigure but don't pipe output
		CMD="dpkg-reconfigure mysql-server"
		print_all "Reconfiguring with: ${CMD}" 3
		$CMD
        if [ ${?} -ne 0 ]
        then
            return 1
        fi
	fi

	# ensure mysql is running
	print_all "Ensuring if mysql is running" 2
	mysql_is_running
	if [ ${?} -ne 0 ]
	then
		mysql_start
		[ ${?} -ne 0 ] && return 1
	fi

	return 0
}

nsm_package_mysql_fix()
{
	print_all "mysql has no fix options enabled" 2
}

nsm_package_mysql_install()
{
	# always install (there is NO harm in this)
	print_all "Installing mysql" 2

	# check if we are an ubuntu or debian system
    is_ubuntu || is_debian
    if [ ${?} -eq 0 ]
    then
		# ensure debconf priority is "critical"
		DEBCONF_PRIORITY=$(debconf_priority_get)
        if [ ${?} -ne 0 ]
        then
            return 1
        fi

		debconf_priority_set "critical" 
        if [ ${?} -ne 0 ]
        then
            return 1
        fi

        # use native package manager apt-get
		CMD="apt-get -y install mysql-server"
		print_all "Installing with: ${CMD}" 2
		system_log "$CMD"
		return $?

        # reset debconf priority
        debconf_priority_set "${DEBCON_PRIORITY}"
    fi
    
    # check if we are a redhat'ish system
    is_fedora || is_rhel || is_centos
    if [ ${?} -eq 0 ]
    then

        # use native package manager yum
		CMD="yum -y install mysql-server"
		print_all "Installing with: ${CMD}" 2
		system_log "$CMD"
		return $?
    fi

    print_all "Not sure how to install mysql on this system." 1
    return 1
}

nsm_package_mysql_uninstall()
{
	# check it's presence and remove if required
	print_all "Checking if mysql is installed" 2
    
	# check if we are an ubuntu or debian system
    is_ubuntu || is_debian
    if [ ${?} -eq 0 ]
    then
        is_deb_installed "mysql-server"
        
        if [ ${?} -eq 0 ]
        then
    		# apt-get remove and purge
			CMD="apt-get -y --purge --auto-remove remove mysql-server"
			print_all "Uninstalling with: ${CMD}" 1
			system_log "${CMD}"
			return $?
        else
		    print_all "mysql is NOT installed" 2
		fi
	fi

}

nsm_package_mysql_upgrade()
{
	print_all "mysql has no upgrade options enabled" 2
}

