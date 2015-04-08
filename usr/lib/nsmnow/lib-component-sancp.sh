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
# the sancp package and dependancies. 
#
#   sancp is used on the Sensor component and is used to session information
# and pass it to the sguil sensor components.
#
# Dependencies:
#   => sguil
#

SANCP_SRC_DIR="sancp-1.6.1-stable"
SANCP_TARBALL="${SANCP_SRC_DIR}.tar.gz"
SANCP_SRC_URL="http://downloads.sourceforge.net/sancp/${SANCP_TARBALL}?modtime=1183791869&big_mirror=0"

nsm_package_sancp_required_options()
{
	# grab input variables with sane defaulting
    OPTIONS=${1:-1}
	
    for OPT in "GENERAL_DOWNLOAD_DIR" "GENERAL_SOURCE_DIR" "GENERAL_INIT_DIR"
    do
	    required_option_set "$OPT"
    done
	
	if [ ${OPTIONS} -eq 1 ]
    then
		required_option_set "SENSOR_CONF_PATH"
		required_option_set "SENSOR_SANCP_CONF_NAME"
		required_option_set "SENSOR_INTERFACE"
    fi

    return 0
}

nsm_package_sancp_download()
{
    sancp_tarball_download
}

nsm_package_sancp_reconfigure()
{
	print_all "sancp has no reconfigure options enabled" 2
}

nsm_package_sancp_fix()
{
	print_all "sancp has no fix options enabled" 2
}

nsm_package_sancp_install()
{
	# check it's presence and install if required
	print_all "Checking if sancp is installed" 2
	is_binary_installed "sancp"
    if [ ${?} -eq 0 ]
    then
		print_all  "sancp already installed" 2
		return 0
	fi

	# check if the source is present and download if necessary
	print_all "Checking sancp source presence: ${GENERAL_SOURCE_DIR}/${SANCP_SRC_DIR}" 2
    sancp_source_exists
	if [ ${?} -ne 0 ]
	then
		print_all "sancp source NOT found" 2
	
		# abort if tarball can not be obtained
        sancp_tarball_download
        if [ ${?} -ne 0 ]
        then
            return 1
        fi
		
		# extract the source tarball as required
        sancp_source_exists
    	if [ ${?} -ne 0 ]
        then
            create_dir "${GENERAL_SOURCE_DIR}"
            if [ ${?} -ne 0 ]
            then
                return 1
            fi
		fi

		CMD="tar -xzf ${GENERAL_DOWNLOAD_DIR}/${SANCP_TARBALL} -C ${GENERAL_SOURCE_DIR}"
		print_all "Extracting sancp source with: ${CMD}" 3
		$CMD

		if [ ${?} -ne 0 ]
        then
			print_all "sancp source could NOT be obtained" 2
			return 10
		fi
	else
		print_all "sancp source found" 2
	fi

	# compile and install
    OLD_DIR="$(pwd)"
	print_all "Changing to sancp source directory: ${GENERAL_SOURCE_DIR}/${SANCP_SRC_DIR}" 3
	cd "${GENERAL_SOURCE_DIR}/${SANCP_SRC_DIR}"

	CMD="make linux"
	print_all "Compiling with: ${CMD}" 1
	system_log "${CMD}"
    if [ ${?} -ne 0 ]
    then 
        return 1
    fi
	
	# install binary file
	print_all "Installing binary", 1
    copy_and_cache_files "./" "sancp" "${GENERAL_BIN_DIR}" "" "0755" "sancp"
    if [ ${?} -ne 0 ]
    then
        return 1
    fi

	# restore old working directory
	cd "${OLD_DIR}"

    is_binary_installed "sancp"
	if [ ${?} -ne 0 ]
    then
		print_all "sancp is NOT installed" 2
		return 1
	fi
	
	print_all "sancp is installed" 2
	return 0
}

nsm_package_sancp_uninstall()
{
    cache_group_remove "sancp"
}

nsm_package_sancp_upgrade()
{
	print_all "sancp has no upgrade options enabled" 2
}

#
# LOCAL FUNCTIONS
#
sancp_source_exists()
{
	if [ -d "${GENERAL_SOURCE_DIR}/${SANCP_SRC_DIR}" ]
    then
        return 0
    fi

	return 1;
}

sancp_tarball_exists()
{
	if [ -r "${GENERAL_DOWNLOAD_DIR}/${SANCP_TARBALL}" ]
    then
        return 0
    fi

	return 1
}

sancp_tarball_download()
{
	print_all "Checking sancp tarball presence: ${GENERAL_DOWNLOAD_DIR}/${SANCP_TARBALL}" 2
	
	# check if we already have the file
    sancp_tarball_exists
	if [ ${?} -ne 0 ]
    then
		print_all "sancp tarball NOT found" 2
   	    prompt_user_yesno "" "Download sancp tarball?" "Y"

       	if [ ${?} -ne 0 ] 
        then
			print_all "skipping download" 3
            return 1
        fi

		print_all "Downloading sancp tarball: ${SANCP_SRC_URL}" 3
		download_file "${SANCP_SRC_URL}" "${GENERAL_DOWNLOAD_DIR}/${SANCP_TARBALL}"
	else
		print_all "sancp tarball found" 2
	fi

	# confirm we got the file
	sancp_tarball_exists
	if [ ${?} -ne 0 ]
    then
		print_all "sancp could NOT be downloaded" 2
		return 1
	fi

	return 0
}

