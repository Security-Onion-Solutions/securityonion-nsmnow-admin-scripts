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
# the sguil-server package and dependancies. 
#
#   sguil-server components are used on the Server component and is used to
# correlate all the information that has been pass by the Sensor components.
#
# Dependencies:
#   <= tcl
#   <= mysql
#

SGUIL_SRC_DIR="sguil-0.7.0"
SGUIL_TARBALL="sguil-0.7.0.tar.gz"
SGUIL_SRC_URL="http://downloads.sourceforge.net/sguil/sguil-0.7.0.tar.gz?modtime=1206487221&big_mirror=0"

nsm_package_sguilserver_required_options()
{
	# grab input variables with sane defaulting
    OPTIONS=${1:-1}
	
    for OPT in "GENERAL_DOWNLOAD_DIR" "GENERAL_SOURCE_DIR"
    do
	    required_option_set "$OPT"
    done
	
	if [ ${OPTIONS} -eq 1 ]
    then
		required_option_set "SERVER_NAME"
		required_option_set "SERVER_CONF_PATH"
		required_option_set "SERVER_CONF_NAME"
		required_option_set "SERVER_DATA_PATH"
		required_option_set "SERVER_LIB_PATH"
		required_option_set "SERVER_DB_NAME"
		required_option_set "SERVER_DB_USER"
		required_option_set "SERVER_DB_PASS"
		required_option_set "SERVER_CLIENT_USER"
		required_option_set "SERVER_CLIENT_PASS"
		required_option_set "SERVER_CA_PASSPHRASE"
    fi

	return 0
}

nsm_package_sguilserver_download()
{
   	prompt_user_yesno "" "Download sguilserver packages(s)?" "Y"
   	[ ${?} -ne 0 ] && return 1

	# check if we are an ubuntu or debian system
    is_ubuntu || is_debian
    if [ ${?} -eq 0 ]
    then

        # use native package manager apt-get
		CMD="apt-get -y -d install openssl pads tcpflow tcpdump"
        print_all "Downloading with: ${CMD}" 2
		system_log "${CMD}"
        if [ ${?} -ne 0 ]
        then
            return 1
        fi

        sguil_tarball_download
        return $?
    fi
    
    # check if we are a redhat'ish system
    is_fedora || is_rhel || is_centos
    if [ ${?} -eq 0 ]
    then

        # use native package manager yum
		CMD="yum --downloadonly -y install openssl pads tcpflow tcpdump"
		print_all "Downloading with: ${CMD}" 2
		system_log "${CMD}"
		#FIXME: yum's "--downloadonly" returns exit code 1 regardless of download success
  
        sguil_tarball_download
        return $?
	fi

	print_all "Not sure how to download sguilserver tools on this UNKNOWN system." 1
	return 1
}

nsm_package_sguilserver_reconfigure()
{
	# check if sguilserver (sguil) has been installed
    is_binary_installed "sguild"
	if [ ${?} -ne 0 ]
    then
		print_all "sguilserver (sguil) is NOT installed"
		return 1
	fi

	# configure server via the NSM adminsitration scripts
	print_all "Generating sguilserver config file(s)" 1
	nsm_server_add -y --server-name="${SERVER_NAME}" --server-sensor-name="${SENSOR_NAME}" --server-db-name="${SERVER_DB_NAME}" --server-db-user="${SERVER_DB_USER}" --server-db-pass="${SERVER_DB_PASS}" --server-client-user="${SERVER_CLIENT_USER}" --server-client-pass="${SERVER_CLIENT_PASS}" --server-auto=yes
	return $?
}

nsm_package_sguilserver_fix()
{
	print_all "sguilserver has no fix options enabled" 2
}

nsm_package_sguilserver_install()
{
	# always install (there is NO harm in this)
	print_all "Installing sguilserver tools" 2

	# check if we are an ubuntu or debian system
    is_ubuntu || is_debian
    if [ ${?} -eq 0 ]
    then

        # use native package manager apt-get
		CMD="apt-get -y install openssl pads tcpflow tcpdump"
		print_all "Installing with: ${CMD}" 2
		system_log "${CMD}"

		if [ ${?} -ne 0 ]
		then
			return 1
		fi
    fi


    # check if we are a redhat'ish system
	is_fedora || is_rhel || is_centos
    if [ ${?} -eq 0 ]
    then

        # use native package manager yum
        # TODO: pads is ommitted until it's dependancy issues are satisfied
		CMD="yum -y install openssl tcpflow tcpdumpl"
		print_all "Installing with: ${CMD}" 2
		system_log "${CMD}"

		if [ ${?} -ne 0 ]
		then
			return 1
		fi
	fi
        
#	print_all "Not sure how to download mysql on this system." 1
#	return 1

	# check it's presence and install if required
	print_all "Checking if sguilserver is installed" 2
    is_binary_installed "sguild"
	if [ ${?} -eq 0 ]
    then
        print_all "sguilserver already installed" 2
		return 0
	fi

	# check if the source is present and download if necessary
	print_all "Checking sguilserver (sguil) source presence: ${GENERAL_SOURCE_DIR}/${SGUIL_SRC_DIR}" 2
    sguil_source_exists
    if [ ${?} -ne 0 ]
    then
		print_all "sguil source NOT found" 2
	
		# abort if tarball can not be obtained
        sguil_tarball_download
        if [ ${?} -ne 0 ]
        then
            return 1
        fi
		
		# extract the source tarball as required
		if [ ! -d "${GENERAL_SOURCE_DIR}" ]
        then
            create_dir "${GENERAL_SOURCE_DIR}"
            if [ ${?} -ne 0 ]
            then
                return 1
            fi
		fi

		CMD="tar -xzf ${GENERAL_DOWNLOAD_DIR}/${SGUIL_TARBALL} -C ${GENERAL_SOURCE_DIR}"
		print_all "Extracting sguilserver source with: ${CMD}" 3
		$CMD
		if [ ${?} -ne 0 ]
        then
			print_all "sguilserver source could NOT be obtained" 2
			return 1
		fi
	else
		print_all "sguilserver source found" 2
	fi

	# create the server lib directory if it doesn't exist
	create_dir "${SERVER_LIB_PATH}"
    if [ ${?} -ne 0 ]
    then
        return 1
    fi

	# copy user files to templates directory for future sensor creation
    create_dir "/usr/share/nsmnow/templates/server/sguil/config"
    if [ ${?} -ne 0 ]
    then
        return 1
    fi

	print_all "Copying sguilserver config file(s) to templates" 2
    copy_and_cache_files "${GENERAL_SOURCE_DIR}/${SGUIL_SRC_DIR}/server" "sguild.queries sguild.users sguild.access sguild.email sguild.queries autocat.conf" "/usr/share/nsmnow/templates/server/sguil/config" "" "" "sguilserver"
    if [ ${?} -ne 0 ]
    then
        return 1
    fi

	# copy all lib files to the lib directory
	print_all "Installing sguilserver library file(s)" 1
    copy_and_cache_files "${GENERAL_SOURCE_DIR}/${SGUIL_SRC_DIR}/server/lib" "*" "${SERVER_LIB_PATH}" "" "" "sguilserver"
    if [ ${?} -ne 0 ]
    then
        return 1
    fi

	# install the binary
	print_all "Installing sguilserver binary" 1
    copy_and_cache_files "${GENERAL_SOURCE_DIR}/${SGUIL_SRC_DIR}/server" "sguild" "${GENERAL_BIN_DIR}" "" "755" "sguilserver"
    if [ ${?} -ne 0 ]
    then
        return 1
    fi

	# confirm it's installed
    is_binary_installed "sguild"
	if [ ${?} -ne 0 ]
    then
        print_all "sguil-server is NOT installed" 2
		return 0
	fi

	print_all "sguilserver is installed" 2
	return 0
}

nsm_package_sguilserver_uninstall()
{
    cache_group_remove "sguilserver"
    return $?
}

nsm_package_sguilserver_upgrade()
{
	print_all "sguilserver has no upgrade options enabled" 2
}

#
# LOCAL FUNCTIONS
#
sguil_source_exists()
{
	if [ -d "${GENERAL_SOURCE_DIR}/${SGUIL_SRC_DIR}" ]
    then
        return 0
    fi

	return 1
}

sguil_tarball_exists()
{
	if [ -r "${GENERAL_DOWNLOAD_DIR}/${SGUIL_TARBALL}" ]
    then
        return 0
    fi

	return 1
}

sguil_tarball_download()
{
	print_all "Checking sguilserver tarball presence: ${GENERAL_DOWNLOAD_DIR}/${SGUIL_TARBALL}" 2
	
	# check if we already have the file
    sguil_tarball_exists
	if [ ${?} -ne 0 ]
    then
		print_all "sguilserver tarball NOT found" 2

		print_all "Downloading sguilserver tarball: ${SGUIL_SRC_URL}" 3
		download_file "${SGUIL_SRC_URL}" "${GENERAL_DOWNLOAD_DIR}/${SGUIL_TARBALL}"
	else
		print_all "sguilserver tarball found" 2
	fi

	# confirm we got the file
    sguil_tarball_exists
	if [ ${?} -ne 0 ]
    then
		print_all "sguilserver could NOT be downloaded" 2
		return 1
	fi

	return 0
}

