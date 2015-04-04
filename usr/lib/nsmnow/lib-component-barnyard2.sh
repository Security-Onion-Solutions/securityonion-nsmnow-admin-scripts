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
# the barnyard2 package and dependancies. 
#
#   barnyard2 is used on the Sensor component and is used to pass information
# captured by snort to the sguil sensor components.
#
# Dependencies:
#   <= snort
#   => sguil
#

BY2_VERSION="1.9-beta1"
BY2_SRC_DIR="barnyard2-${BY2_VERSION}";
BY2_TARBALL="${BY2_SRC_DIR}.tar.gz"
BY2_SRC_URL="http://www.securixlive.com/download/barnyard/${BY2_TARBALL}"

nsm_package_barnyard2_required_options()
{
	# grab input variables with sane defaulting
    OPTIONS=${1:-1}
	
    for OPT in "GENERAL_DOWNLOAD_DIR" "GENERAL_SOURCE_DIR" "GENERAL_INIT_DIR"
    do
	    required_option_set "$OPT"
    done
	
	if [ ${OPTIONS} -eq 1 ]
    then
		required_option_set "SENSOR_NAME"
		required_option_set "SENSOR_CONF_PATH"
		required_option_set "SENSOR_BY2_CONF_NAME"
    fi

	return 0
}

nsm_package_barnyard2_download()
{
    barnyard2_tarball_download
}

nsm_package_barnyard2_reconfigure()
{
	print_all "barnyard2 has no reconfigure options enabled" 2
}

nsm_package_barnyard2_fix()
{
	print_all "barnyard2 has no fix options enabled" 2
}

nsm_package_barnyard2_install()
{
	# check it's presence and install if required
	print_all "Checking if barnyard2 is installed" 2
    is_binary_installed "barnyard2"
    if [ ${?} -eq 0 ]
    then
		print_all "barnyard2 already installed" 2
		return 0
	fi

	# check if the source is present and download if necessary
	print_all "Checking barnyard2 source presence: ${GENERAL_SOURCE_DIR}/${BY2_SRC_DIR}" 2
    barnyard2_source_exists
    if [ ${?} -ne 0 ]
    then
		print_all "barnyard2 source NOT found" 2
	
		# abort if tarball can not be obtained
        barnyard2_tarball_download
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

		CMD="tar -xzf ${GENERAL_DOWNLOAD_DIR}/${BY2_TARBALL} -C ${GENERAL_SOURCE_DIR}"
		print_all "Extracting barnyard2 source with: ${CMD}" 3
		$CMD
		if [ ${?} -ne 0 ]
        then
			print_all "barnyard2 source could NOT be obtained" 2
			return 1
		fi
	else
		print_all "barnyard2 source found" 2
	fi

	# compile and install
    OLD_DIR="$(pwd)"
	print_all "Changing to barnyard2 source directory: ${GENERAL_SOURCE_DIR}/${BY2_SRC_DIR}" 3
	cd "${GENERAL_SOURCE_DIR}/${BY2_SRC_DIR}"

    # TODO: use the most appropriate TCL lib
	CMD="./configure --with-tcl=/usr/lib/tcl8.3"
	print_all "Configuring with: ${CMD}" 1
	system_log "$CMD"
    if [ ${?} -ne 0 ]
    then 
        return 1
    fi
	
	CMD="make";
	print_all "Compiling with: ${CMD}" 1
	system_log "$CMD"
    if [ ${?} -ne 0 ]
    then 
        return 1
    fi

	# install binary file
	print_all "Installing binary", 1
    copy_and_cache_files "./src" "barnyard2" "${GENERAL_BIN_DIR}" "" "0755" "barnyard2"
    if [ ${?} -ne 0 ]
    then
        return 1
    fi

	# restore old working directory
	cd $OLD_DIR

    is_binary_installed "barnyard2"
	if [ ${?} -ne 0 ]
    then
		print_all "barnyard2 is NOT installed" 2
		return 1
	fi
	
	print_all "barnyard2 is installed" 2
	return 0
}

nsm_package_barnyard2_uninstall()
{
    cache_group_remove "barnyard2"
}

nsm_package_barnyard2_upgrade()
{
	print_all "Checking if barnyard2 is installed" 2
    is_binary_installed "barnyard2"
    if [ ${?} -eq 0 ]
    then
        print_all "Checking if installed version is up to date" 2
        barnyard2_version_is_current

        if [ ${?} -eq 0  ]
        then
            print_all "up to date" 3
            return 0
        fi

        # TODO: need to backup existing install in case of error
        #nsm_package_barnyard2_uninstall
    fi

    nsm_package_barnyard2_install
}

#
# LOCAL FUNCTIONS
#
barnyard2_source_exists()
{
	if [ -d "${GENERAL_SOURCE_DIR}/${BY2_SRC_DIR}" ]
    then
        return 0
    fi

	return 1;
}

barnyard2_tarball_exists()
{
	if [ -r "${GENERAL_DOWNLOAD_DIR}/${BY2_TARBALL}" ]
    then
        return 0
    fi

	return 1
}

barnyard2_tarball_download()
{
	print_all "Checking barnyard2 tarball presence: ${GENERAL_DOWNLOAD_DIR}/${BY2_TARBALL}" 2
	
	# check if we already have the file
    barnyard2_tarball_exists
	if [ ${?} -ne 0 ]
    then
		print_all "barnyard2 tarball NOT found" 2
   	    prompt_user_yesno "" "Download barnyard2 tarball?" "Y"

       	if [ ${?} -ne 0 ] 
        then
			print_all "skipping download" 3
            return 1
        fi

		print_all "Downloading barnyard2 tarball: ${BY2_SRC_URL}" 3
		download_file "${BY2_SRC_URL}" "${GENERAL_DOWNLOAD_DIR}/${BY2_TARBALL}"
	else
		print_all "barnyard2 tarball found" 2
	fi

	# confirm we got the file
    barnyard2_tarball_exists
	if [ ${?} -ne 0 ]
    then
		print_all "barnyard2 could NOT be downloaded" 2
		return 1
	fi

	return 0
}

barnyard2_version_is_current()
{
    is_barnyard2_version "2.${BY2_VERSION}"
}

