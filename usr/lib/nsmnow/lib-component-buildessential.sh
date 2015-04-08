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
# the build-essential package(s) and dependancies.
#

nsm_package_buildessential_required_options()
{
	print_all "build-essential has no required options to be configured" 2
}

nsm_package_buildessential_download()
{
   	prompt_user_yesno "" "Download build-essential packages(s)?" "Y"
   	[ ${?} -ne 0 ] && return 1

	# check if we are an ubuntu or debian system
    is_ubuntu || is_debian
    if [ ${?} -eq 0 ]
    then

        # use native package manager apt-get
		CMD="apt-get -y -d install libpcre3-dev libpcap0.8-dev build-essential"
        print_all "Downloading with: ${CMD}" 2
		system_log "${CMD}"
        return $?
    fi
    
    # check if we are a redhat'ish system
    is_fedora || is_rhel || is_centos
    if [ ${?} -eq 0 ]
    then

        # use native package manager yum
		cmd="yum --downloadonly -y install libpcap-devel pcre-devel gcc make automake gcc-c++"
		print_all "Downloading with: ${CMD}" 2
		system_log "${CMD}"
	
		#FIXME: yum's "--downloadonly" returns exit code 1 regardless of download success
        return 0
	fi

	print_all "Not sure how to download build-essential on this UNKNOWN system." 1
	return 1
}

nsm_package_buildessential_reconfigure()
{
    print_all "build-essential has no reconfigure options enabled" 2
}

nsm_package_buildessential_fix()
{
	print_all "build-essential has no fix options enabled" 2
}

nsm_package_buildessential_install()
{
	# always install (there is NO harm in this)
	print_all "Installing build-essential(s)" 2

	# check if we are an ubuntu or debian system
    is_ubuntu || is_debian
    if [ ${?} -eq 0 ]
    then

        # use native package manager apt-get
		CMD="apt-get -y install libpcre3-dev libpcap0.8-dev build-essential"
		print_all "Installing with: ${CMD}" 2
		system_log "${CMD}"
		return $?
    fi
    
    # check if we are a redhat'ish system
    is_fedora || is_rhel || is_centos
    if [ ${?} -eq 0 ]
    then

        # use native package manager yum
    	CMD="yum -y install libpcap-devel pcre-devel gcc make automake gcc-c++"
		print_all "Installing with: ${CMD}" 2
		system_log "${CMD}"
		return $?
    fi

	utils::print_all "Not sure how to install build-essential on this system." 1
	return 1
}

nsm_package_buildessential_uninstall()
{
	# always install (there is NO harm in this)
	print_all "Uninstalling build-essential(s)" 2

	# check if we are an ubuntu or debian system
    is_ubuntu || is_debian
    if [ ${?} -eq 0 ]
    then

        # use native package manager apt-get
		cmd="apt-get -y --purge --auto-remove remove libpcre3-dev libpcap0.8-dev build-essential"
		print_all "Uninstalling with: ${cmd}" 2
		system_log $cmd
		return $?
    fi
    
    # check if we are a redhat'ish system
    is_fedora || is_rhel || is_centos
    if [ ${?} -eq 0 ]
    then

        # use native package manager yum
    	cmd="yum -y remove libpcap-devel pcre-devel gcc make automake gcc-c++"
		print_all "Uninstalling with: ${cmd}" 2
		system_log $cmd
		return $?
    fi

	utils::print_all "Not sure how to uninstall build-essential on this system." 2
	return 1
}

nsm_package_buildessential_upgrade()
{
	print_all "build-essential has no upgrade options enabled" 2
}
