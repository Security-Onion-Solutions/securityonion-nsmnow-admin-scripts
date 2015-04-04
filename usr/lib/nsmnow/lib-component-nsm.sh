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
# Dependencies:
#

NSMNOW_PATH="."

nsm_package_nsm_required_options()
{
	# grab input variables with sane defaulting
    OPTIONS=${1:-1}
	
	if [ ${OPTIONS} -eq 1 ]
    then
		required_option_set "GENERAL_SOURCE_DIR"
		required_option_set "GENERAL_BIN_DIR"
		required_option_set "GENERAL_SBIN_DIR"
		required_option_set "GENERAL_LIB_DIR"
		required_option_set "GENERAL_ETC_DIR"
		required_option_set "GENERAL_INIT_DIR"
		required_option_set "GENERAL_CRON_DIR"
    fi

	return 0
}

nsm_package_nsm_download()
{
	print_all "nsm has no download options enabled" 2
}

nsm_package_nsm_reconfigure()
{
	print_all "nsm has no reconfigure options enabled" 2
}

nsm_package_nsm_fix()
{
	print_all "nsm has no fix options enabled" 2
}

nsm_package_nsm_install()
{
	# always install (there is NO harm in this)
	print_all "Installing nsm" 2

    #
    # NSMnow
    #

	# install NSMnow library file(s)
    print_all "Copying library file(s)" 3
    copy_and_cache_files "${NSMNOW_PATH}/lib" "*" "${GENERAL_LIB_DIR}/nsmnow" "" "" "nsmnow"
    if [ ${?} -ne 0 ]
    then 
        return 1
    fi

	# install NSMnow binary file(s)
    print_all "Copying binary file(s)" 3
    copy_and_cache_files "${NSMNOW_PATH}" "NSMnow" "${GENERAL_SBIN_DIR}" "" "" "nsmnow"
    if [ ${?} -ne 0 ]
    then 
        return 1
    fi

    #
    # NSM Administration
    #

    create_dir "/usr/share/nsmnow/templates/snort/rules"
    if [ ${?} -ne 0 ]
    then 
        return 1
    fi

	# copy (old) Snort rules to templates directory
	print_all "Copying rules file(s) to templates" 3
	copy_and_cache_files "${NSMNOW_PATH}/templates/rules" "*" "/usr/share/nsmnow/templates/snort/rules" "" "" "snort"
    if [ ${?} -ne 0 ]
    then 
        return 1
    fi

	# install NSM administration library file(s)
    print_all "Copying library file(s)" 3
    copy_and_cache_files "${NSMNOW_PATH}/templates/lib" "*" "${GENERAL_LIB_DIR}/nsmnow" "" "" "nsmnow"
    if [ ${?} -ne 0 ]
    then 
        return 1
    fi

	# install NSM administration binary file(s)
    print_all "Copying binary file(s)" 3
    copy_and_cache_files "${NSMNOW_PATH}/templates/sbin" "*" "${GENERAL_SBIN_DIR}" "" "" "nsmnow"
    if [ ${?} -ne 0 ]
    then 
        return 1
    fi

	# install NSM administration init file(s)
    print_all "Copying init file(s)" 3
    copy_and_cache_files "${NSMNOW_PATH}/templates/init" "nsm nsm-server nsm-sensor" "/etc/init.d" "" "755" "nsmnow"
    if [ ${?} -ne 0 ]
    then 
        return 1
    fi

    # install NSM administration configuration file
    print_all "Creating configuration file" 3
    create_dir "/etc/nsm"
    if [ ${?} -ne 0 ]
    then 
        return 1
    fi

    if [ ! -f "/etc/nsm/administration.conf" ]
    then
		echo -e "NSM_LIB_DIR=\"${GENERAL_LIB_DIR}/nsmnow\"" > /etc/nsm/administration.conf
		echo -e "NSM_GENERAL_LIB_DIR=\"${GENERAL_LIB_DIR}\"" >> /etc/nsm/administration.conf
		echo -e "NSM_GENERAL_BIN_DIR=\"${GENERAL_BIN_DIR}\"" >> /etc/nsm/administration.conf
		echo -e "NSM_GENERAL_SBIN_DIR=\"${GENERAL_SBIN_DIR}\"" >> /etc/nsm/administration.conf
		echo -e "NSM_GENERAL_ETC_DIR=\"${GENERAL_ETC_DIR}\"" >> /etc/nsm/administration.conf
		echo -e "NSM_GENERAL_INIT_DIR=\"${GENERAL_INIT_DIR}\"" >> /etc/nsm/administration.conf
		echo -e "NSM_GENERAL_CRON_DIR=\"${GENERAL_CRON_DIR}\"" >> /etc/nsm/administration.conf
        echo -e "SNORT_LIB_DIR=\"${GENERAL_LIB_DIR}\"" >> /etc/nsm/administration.conf
        if [ ${?} -ne 0 ]
        then 
            return 1
        fi

        cache_file_add "/etc/nsm/administration.conf" "nsmnow"
    fi

	return 0
}

nsm_package_nsm_uninstall()
{
    cache_group_remove "nsmnow"
}

nsm_package_nsm_upgrade()
{
	print_all "nsm has no upgrade options enabled" 2
}

