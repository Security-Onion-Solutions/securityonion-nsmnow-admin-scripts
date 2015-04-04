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
# the snort package and dependancies. 
#
#   snort is used on the Sensor component and is the mechanism by which alert
# and full content data are captured. Full content data is captured by snort
# running in a tcpdump manner and alert data is captured using snort's feature
# rich signatures and rules.
#
# Dependencies:
#   <= libpcap
#

SNORT_SRC_URL[0]="http://dl.snort.org/snort-current/snort-2.8.5.2.tar.gz"
SNORT_TARBALL[0]="snort-2.8.5.2.tar.gz"
SNORT_SRC_DIR[0]="snort-2.8.5.2"
SNORT_SRC_URL[1]="http://dl.snort.org/snort285/snort-2.8.5.2.tar.gz"
SNORT_TARBALL[1]="snort-2.8.5.2.tar.gz"
SNORT_SRC_DIR[1]="snort-2.8.5.2"
SNORT_SRC_URL[2]="http://dl.snort.org/snort285/snort-2.8.5.1.tar.gz"
SNORT_TARBALL[2]="snort-2.8.5.1.tar.gz"
SNORT_SRC_DIR[2]="snort-2.8.5.1"
SNORT_SRC_URL[3]="http://dl.snort.org/snort285/snort-2.8.5.tar.gz"
SNORT_TARBALL[3]="snort-2.8.5.tar.gz"
SNORT_SRC_DIR[3]="snort-2.8.5"
SNORT_SRC_URL[4]="http://dl.snort.org/snort284/snort-2.8.4.1.tar.gz"
SNORT_TARBALL[4]="snort-2.8.4.1.tar.gz"
SNORT_SRC_DIR[4]="snort-2.8.4.1"
SNORT_IDX=-1

nsm_package_snort_required_options()
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
		required_option_set "SENSOR_CONF_PATH"
		required_option_set "SENSOR_SNORT_CONF_NAME"
		required_option_set "SENSOR_DATA_PATH"
		required_option_set "SENSOR_INTERFACE"
    fi

	return 0
}

nsm_package_snort_download()
{
	snort_tarball_download
}

nsm_package_snort_reconfigure()
{
    # check if snort has been installed
    is_binary_installed "snort"
	if [ ${?} -ne 0 ]
    then
		print_all "snort is NOT installed"
		return 1
	fi

	return 0
}

nsm_package_snort_fix()
{
	print_all "snort has no fix options enabled" 2
}

nsm_package_snort_install()
{
    # check it's presence and install if required
	print_all "Checking if snort is installed" 2
    is_binary_installed "snort"
    if [ ${?} -eq 0 ]
    then
		print_all "snort already installed" 2
		return 0
	fi

	# check if the source is present and download if necessary
	print_all "Checking snort source presence" 2
    snort_source_exists
    if [ ${?} -ne 0 ]
    then
		print_all "snort source NOT found" 3
	
		# abort if tarball can not be obtained
        snort_tarball_download
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

		CMD="tar -xzf ${GENERAL_DOWNLOAD_DIR}/${SNORT_TARBALL[$SNORT_IDX]} -C ${GENERAL_SOURCE_DIR}"
		print_all "Extracting snort source with: ${CMD}" 2
		$CMD
		if [ ${?} -ne 0 ]
        then
			print_all "snort source could NOT be obtained" 3
			return 1
		fi
	else
		print_all "snort source found" 3
	fi

    # switch to source directory
    OLD_DIR="$(pwd)"
	print_all "Changing to snort source directory: ${GENERAL_SOURCE_DIR}/${SNORT_SRC_DIR[$SNORT_IDX]}" 3
	cd "${GENERAL_SOURCE_DIR}/${SNORT_SRC_DIR[$SNORT_IDX]}"

    # configure
	CMD="./configure --enable-perfprofiling --bindir=${GENERAL_BIN_DIR} --exec-prefix=${GENERAL_LIB_DIR%%/lib}"
	print_all "Configuring with: ${CMD}" 1
	system_log "$CMD"
    if [ ${?} -ne 0 ]
    then 
        return 1
    fi
	
    # compile
	CMD="make";
	print_all "Compiling with: ${CMD}" 1
	system_log "$CMD"
    if [ ${?} -ne 0 ]
    then 
        return 1
    fi  

    # install
	CMD="make install";
	print_all "Installing with: ${CMD}" 1
	system_log "$CMD"
    if [ ${?} -ne 0 ]
    then 
        return 1
    fi  

#   # install library files
#	utils::print_all("  Installing dynamic-preprocessors", 1);
#	return 0 unless ( utils::batch_copy({
#		source => "./src/dynamic-preprocessors/build/usr/local/lib/snort_dynamicpreprocessor",
#		destination => $CONF->{"GENERAL_LIB_DIR"} . "/snort_dynamicpreprocessor",
#		files => ["libsf_dcerpc_preproc.a", "libsf_dcerpc_preproc.la", "libsf_dcerpc_preproc.so.0.0.0", "libsf_dcerpc_preproc.so.0", "libsf_dcerpc_preproc.so",
#		           "libsf_dns_preproc.a", "libsf_dns_preproc.la", "libsf_dns_preproc.so.0.0.0", "libsf_dns_preproc.so.0", "libsf_dns_preproc.so",
#		           "libsf_ftptelnet_preproc.a", "libsf_ftptelnet_preproc.la", "libsf_ftptelnet_preproc.so.0.0.0", "libsf_ftptelnet_preproc.so.0", "libsf_ftptelnet_preproc.so",
#		           "libsf_smtp_preproc.a", "libsf_smtp_preproc.la", "libsf_smtp_preproc.so.0.0.0", "libsf_smtp_preproc.so.0", "libsf_smtp_preproc.so",
#		           "libsf_ssh_preproc.a", "libsf_ssh_preproc.la", "libsf_ssh_preproc.so.0.0.0", "libsf_ssh_preproc.so.0", "libsf_ssh_preproc.so",
#		           "libsf_ssl_preproc.a", "libsf_ssl_preproc.la", "libsf_ssl_preproc.so.0.0.0", "libsf_ssl_preproc.so.0", "libsf_ssl_preproc.so"],
#		group => "snort"
#	}) );
#	
#	utils::print_all("  Installing dynamic-engine", 1);
#	return 0 unless ( utils::batch_copy({
#		source => "./src/dynamic-plugins/sf_engine/.libs",
#		destination => $CONF->{"GENERAL_LIB_DIR"} . "/snort_dynamicengine",
#		files => ["libsf_engine.a", "libsf_engine.la+", "libsf_engine.so.0.0.0", "libsf_engine.so.0", "libsf_engine.so"],
#		group => "snort"
#	}) );

#   # install library files
#	utils::print_all("  Installing dynamic-rules", 1);
#	return 0 unless ( utils::batch_copy({
#		source => "./src/dynamic-examples/dynamic-rule/.libs",
#		destination => $CONF->{"GENERAL_LIB_DIR"} . "/snort_dynamicrules",
#		files => ["lib_sfdynamic_example_rule.a", "lib_sfdynamic_example_rule.la+", "lib_sfdynamic_example_rule.so.0.0.0", "lib_sfdynamic_example_rule.so.0", "lib_sfdynamic_example_rule.so"],
#		group => "snort"
#	}) );

#	# install binary file
#	utils::print_all("  Installing binary", 1);
#	return 0 unless ( utils::batch_copy({
#		source => "./src/",
#		destination => $CONF->{"GENERAL_BIN_DIR"},
#		files => ["snort"],
#		permissions => "0755",
#		group => "snort"
#	}) );

	# copy files to templates directory for future sensor creation
	print_all "Copying essential file(s) to templates" 2

    create_dir "/usr/share/nsmnow/templates/snort"
    if [ ${?} -ne 0 ]
    then 
        return 1
    fi

	copy_and_cache_files "./etc" "classification.config sid-msg.map gen-msg.map threshold.conf reference.config unicode.map" "/usr/share/nsmnow/templates/snort" "" "" "snort"
    if [ ${?} -ne 0 ]
    then 
        return 1
    fi

#TODO: This needs to be reworked. I don't think rules are supplied with snort
#	print_all "Copying rules file(s) to templates" 2
#    create_dir "/usr/share/nsmnow/templates/snort/rules"
#    if [ ${?} -ne 0 ]
#    then 
#        return 1
#    fi

#	copy_and_cache_files "./templates/rules" "*" "/usr/share/nsmnow/templates/snort/rules" "" "" "snort"
#    if [ ${?} -ne 0 ]
#    then 
#        return 1
#    fi

	# restore old working directory
	cd $OLD_DIR

    is_binary_installed "snort"
	if [ ${?} -ne 0 ]
    then
		print_all "snort is NOT installed" 2
		return 1
	fi
	
	print_all "snort is installed" 2
	return 0
}

nsm_package_snort_uninstall()
{
    return 1
}

nsm_package_snort_upgrade()
{
	print_all "snort has no upgrade options enabled" 2
}

#
# LOCAL FUNCTIONS
#
snort_tarball_download()
{
	print_all "Checking snort tarball presence" 2
	
    snort_tarball_exists
    if [ ${?} -ne 0 ]
    then
		print_all "snort tarball(s) NOT found" 2
   	    prompt_user_yesno "" "Download snort tarball?" "Y"

       	if [ ${?} -ne 0 ] 
        then
			print_all "skipping download" 3
            return 1
        fi

		print_all "Downloading snort tarball: ${BY2_SRC_URL}" 3
        for SNORT_IDX in $(seq 0 $((${#SNORT_SRC_URL[@]} - 1)))
        do
            download_file "${SNORT_SRC_URL[$SNORT_IDX]}" "${GENERAL_DOWNLOAD_DIR}/${SNORT_TARBALL[$SNORT_IDX]}"
            if [ ${?} -eq 0 ]
            then
                return 0
            fi
        done
    else
		print_all "snort tarball found" 2
		return 0
	fi

	# confirm we got the file
    snort_tarball_exists
	if [ ${?} -ne 0 ]
    then
		print_all "snort could NOT be downloaded" 2
		return 1
	fi

	return 0
}

snort_source_exists()
{
    # check if an index is already been defined and use it
	if [ ${SNORT_IDX} -ne -1 ]
    then

        if [ -d "${GENERAL_DOWNLOAD_DIR}/${SNORT_SRC_DIR[$SNORT_IDX]}" ]
        then
            return 0
        fi
	else

        print_all "Searching for any available snort source" 3
        for SNORT_IDX in $(seq 0 $((${#SNORT_SRC_URL[@]} - 1)))
        do
            if [ -d "${GENERAL_DOWNLOAD_DIR}/${SNORT_SRC_DIR[$SNORT_IDX]}" ]
            then
                return 0
            fi
        done
    fi

    # reset index
    SNORT_IDX=-1

    # couldn't find any source directories
    return 1
}

snort_tarball_exists()
{
    # check if an index is already been defined and use it
	if [ ${SNORT_IDX} -ne -1 ]
    then

        if [ -d "${GENERAL_DOWNLOAD_DIR}/${SNORT_TARBALL[$SNORT_IDX]}" ]
        then
            return 0
        fi
	else

        print_all "Searching for any available snort tarball" 3
        for SNORT_IDX in $(seq 0 $((${#SNORT_SRC_URL[@]} - 1)))
        do
            if [ -r "${GENERAL_DOWNLOAD_DIR}/${SNORT_TARBALL[$SNORT_IDX]}" ]
            then
                return 0
            fi
        done
    fi

    # reset index
    SNORT_IDX=-1

    # couldn't find any source directories
    return 1
}

