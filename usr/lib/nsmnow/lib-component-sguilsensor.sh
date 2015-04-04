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
# the sguil-sensor package and dependancies. 
#
#   sguil-sensor components are used on the Sensor component and is used to
# collect all sensor specific information from snort, barnyard, and sancp
# before communicating it to the Sensor component.
#
# Dependencies:
#   <= tcl
#   <= snort
#   <= barnyard
#   <= sancp
#

SGUIL_SRC_DIR="sguil-0.7.0"
SGUIL_TARBALL="sguil-0.7.0.tar.gz"
SGUIL_SRC_URL="http://downloads.sourceforge.net/sguil/sguil-0.7.0.tar.gz?modtime=1206487221&big_mirror=0"

nsm_package_sguilsensor_required_options()
{
	# grab input variables with sane defaulting
    OPTIONS=${1:-1}
	
    for OPT in "GENERAL_DOWNLOAD_DIR" "GENERAL_SOURCE_DIR"
    do
	    required_option_set "$OPT"
    done
	
	if [ ${OPTIONS} -eq 1 ]
    then
		required_option_set "SENSOR_NAME"
		required_option_set "SENSOR_INTERFACE"
		required_option_set "SENSOR_CONF_PATH"
		required_option_set "SENSOR_SRV_HOST"
		required_option_set "SENSOR_DATA_PATH"
    fi

	return 0
}

nsm_package_sguilsensor_download()
{
   	prompt_user_yesno "" "Download sguilclient packages(s)?" "Y"
   	[ ${?} -ne 0 ] && return 1

	# check if we are an ubuntu or debian system
    is_ubuntu || is_debian
    if [ ${?} -eq 0 ]
    then

        # use native package manager apt-get
		CMD="apt-get -y -d install wireshark"
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
		CMD="yum --downloadonly -y install wireshark wireshark-gnome"
		print_all "Downloading with: ${CMD}" 2
		system_log "${CMD}"
		#FIXME: yum's "--downloadonly" returns exit code 1 regardless of download success
  
        sguil_tarball_download
        return $?
	fi

	print_all "Not sure how to download build-essential on this UNKNOWN system." 1
	return 1
}

nsm_package_sguilsensor_reconfigure()
{
	# check if sguilserver (sguil) has been installed
#    is_binary_installed "sguild"
#	if [ ${?} -ne 0 ]
#    then
#		print_all "sguilserver (sguil) is NOT installed"
#		return 1
#	fi

	# configure sensor via the NSM adminsitration scripts
	print_all "Generating sguilsensor config file(s)" 1
	nsm_sensor_add -y --sensor-name="${SENSOR_NAME}" --sensor-interface="${SENSOR_INTERFACE}" --sensor-server-host="${SENSOR_SRV_HOST}" --sensor-auto=yes
	return $?
}

nsm_package_sguilsensor_fix()
{
	print_all "sguilsensor has no fix options enabled" 2
}

nsm_package_sguilsensor_install()
{
	# check it's presence and install if required
	print_all "Checking if sguilsensor is installed" 2
    is_binary_installed "pcap_agent.tcl sancp_agent.tcl snort_agent.tcl"
	if [ ${?} -eq 0 ]
    then
        print_all "sguilsensor already installed" 2
		return 0
	fi

	# check if the source is present and download if necessary
	print_all "Checking sguilsensor (sguil) source presence: ${GENERAL_SOURCE_DIR}/${SGUIL_SRC_DIR}" 2
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
		print_all "Extracting sguilsensor source with: ${CMD}" 3
		$CMD
		if [ ${?} -ne 0 ]
        then
			print_all "sguilsensor source could NOT be obtained" 2
			return 1
		fi
	else
		print_all "sguilsensor source found" 2
	fi

	# copy the binary
	print_all "Installing sguilsensor binary file(s)" 1
    copy_and_cache_files "${GENERAL_SOURCE_DIR}/${SGUIL_SRC_DIR}/sensor" "snort_agent.tcl sancp_agent.tcl pcap_agent.tcl" "${GENERAL_BIN_DIR}" "" "755" "sguilsensor"
    if [ ${?} -ne 0 ]
    then
        return 1
    fi

	# ensure the sguild user/groups are available
	if [ -z "$(cat /etc/group | grep ^sguil: )" ]
	then
		CMD="groupadd sguil"
		print_all "Creating sguil group with: ${CMD}" 3
        $CMD
        if [ ${?} -ne 0 ]
        then
            return 1
        fi
	fi

	if [ -z "$(cat /etc/passwd | grep ^sguil: )" ]
	then
		CMD="useradd -g sguil sguil"
		print_all "Creating sguil user with: ${CMD}" 3
        $CMD
        if [ ${?} -ne 0 ]
        then
            return 1
        fi
	fi

	# add cronjob for logging restart each day
	print_all "Adding daily cron job" 2
    copy_and_cache_files "./templates/cron" "sensor-newday" "/etc/cron.d" "" "644" "sguilsensor"
    if [ ${?} -ne 0 ]
    then
        return 1
    fi


	print_all "sguilsensor is installed" 2
	return 0
}

nsm_package_sguilsensor_uninstall()
{
    cache_group_remove "sguilsensor"
    return $?
}

nsm_package_sguilsensor_upgrade()
{
	print_all "sguilsensor has no upgrade options enabled" 2
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
	print_all "Checking sguilsensor tarball presence: ${GENERAL_DOWNLOAD_DIR}/${SGUIL_TARBALL}" 2
	
	# check if we already have the file
    sguil_tarball_exists
	if [ ${?} -ne 0 ]
    then
		print_all "sguilsensor tarball NOT found" 2

		print_all "Downloading sguilsensor tarball: ${SGUIL_SRC_URL}" 3
		download_file "${SGUIL_SRC_URL}" "${GENERAL_DOWNLOAD_DIR}/${SGUIL_TARBALL}"
	else
		print_all "sguilsensor tarball found" 2
	fi

	# confirm we got the file
    sguilserver_tarball_exists
	if [ ${?} -ne 0 ]
    then
		print_all "sguilsensor could NOT be downloaded" 2
		return 1
	fi

	return 0
}

