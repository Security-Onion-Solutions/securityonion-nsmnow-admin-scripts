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
# Tcl/tk and its dependencies. Tcl/tk is a dependency of sguil.
#

nsm_package_tcl_required_options()
{
	print_all "tcl/tk has no required options to be configured" 2
}

nsm_package_tcl_download()
{
   	prompt_user_yesno "" "Download tcl/tk packages(s)?" "Y"
   	[ ${?} -ne 0 ] && return 1

	# check if we are a ubuntu or debian system
	is_ubuntu || is_debian
    if [ ${?} -eq 0 ]
    then

        # use native package manager apt-get
		CMD="apt-get -y -d install tcl8.3 itcl3 mysqltcl tcltls tcllib tcl8.3-dev iwidgets4 tclx8.4 itk3 tcl8.4 tk8.4"
		print_all "Downloading with: ${CMD}" 2
		system_log "${CMD}"
        return $?
	fi

    # check if we are a redhat'ish system
	is_fedora || is_rhel || is_centos
    if [ ${?} -eq 0 ]
    then

        # use native package manager yum
		CMD="yum --downloadonly -y install tcl itcl tcltls tcllib tcl-devel iwidgets tclx itk tk mysqltcl"
		print_all "Downloading with: ${CMD}" 2
		system_log "${CMD}"
		#TODO: yum's "--downloadonly" returns exit code 1 regardless of successful download
        return 0
	fi
        
	print_all "Not sure how to download tcl/tk on this system." 1
	return 1
}

nsm_package_tcl_reconfigure()
{
    tcl_is_configured
    if [ ${?} -eq 0 ]
    then
		print_all "tcl/tk is already configured" 2
        return 0
    fi

	# check if we are a ubuntu or debian system
	is_ubuntu || is_debian
    if [ ${?} -eq 0 ]
    then

        # Debian and Ubuntu's installed version of tcl8.4+ is compiled with
        # multithreading enabled, which Sguil doesn't like. We need to force
        # version tcl8.3
		print_all "Correcting Tcl/tk symlinks to run unthreaded version tcl8.3" 2

   		update-alternatives --install /usr/bin/tclsh tclsh /usr/bin/tclsh8.3 10000
		if [ ${?} -ne 0 ]
		then
	        return $?
		fi

        is_ubuntu "9.10+"
        if [ ${?} -eq 0 ]
        then
            # the alternative points to /usr/bin/tclsh-default which appears to
            # be an alternative itself. So we'll deal with it instead. 
            ln -fs "/usr/bin/tclsh8.3" "/usr/bin/tclsh-default"
		    if [ ${?} -ne 0 ]
    		then
                print_all "Unable to modify tclsh-default" 3
    		    return $?
    		fi

            # tclx8.4 needs to be patched as of Karmic do undo the fix for Debian 
            # bug #422469 (may cause instabilities in other applications)
            sed -i '/vcompare/ s/^/#/g' /usr/lib/tclx8.4/pkgIndex.tcl
    		if [ ${?} -ne 0 ]
	    	then
		        return $?
		    fi
        fi

		update-alternatives --auto tclsh
		if [ ${?} -ne 0 ]
		then
		    return $?
		fi
	fi

    # check if we are a redhat'ish system
	is_fedora || is_rhel || is_centos
    if [ ${?} -eq 0 ]
    then

        # As of Fedora 9, Tcl is compiled without the directory "/usr/lib"
        # appearing in auto_load. This doesn't help as mysqltcl is located in
        # "/usr/lib". Create a symlink of mysqltcl to the Tcl library path
        TCL_VERSION=$(echo "puts \$tcl_version" | tclsh)
        TCL_AUTOPATH=$(echo "puts \$auto_path" | tclsh)
        TCLLIB_PATH="/usr/lib/tcl${TCL_VERSION}"
        MYSQLTCL_PATH=$(rpm -ql mysqltcl | grep pkgIndex.tcl | xargs dirname)
        MYSQLTCL_NAME=$(basename $MYSQLTCL_PATH)
        MYSQLTCL_SYMLINK_PATH="${TCLLIB_PATH}/${MYSQLTCL_NAME}"

        # check if the link already exists
        if [ ! -L "${MYSQLTCL_SYMLINK_PATH}" ]
        then
    		print_all "Symlinking mysqltcl to be visible by tcl/tk" 2
    		print_all "   original: ${MYSQLTCL_PATH}" 3
    		print_all "   symlink:  ${MYSQLTCL_SYMLINK_PATH}" 3

            CMD="ln -s ${MYSQLTCL_PATH} ${MYSQLTCL_SYMLINK_PATH}"
            system_log "${CMD}"
            return $?
        fi
    fi

    tcl_is_configured
    if [ ${?} -eq 0 ]
    then
		print_all "tcl/tk is configured" 2
        return 0
    fi

	print_all "tcl/tk is NOT configured" 2
	return 1
}

nsm_package_tcl_fix()
{
	print_all "tcl/tk has no fix options enabled" 2
}

nsm_package_tcl_install()
{
	# always install (there is NO harm in this)
	print_all "Installing tck/tk" 2

	# check if we are an ubuntu or debian system
    is_ubuntu || is_debian
    if [ ${?} -eq 0 ]
    then

        # use native package manager apt-get
		CMD="apt-get -y install tcl8.3 itcl3 mysqltcl tcltls tcllib tcl8.3-dev iwidgets4 tclx8.4 itk3 tcl8.4 tk8.4"
		print_all "Installing with: ${CMD}" 2
        system_log "${CMD}"
        return $?
    fi

    # check if we are a redhat'ish system
	is_fedora || is_rhel || is_centos
    if [ ${?} -eq 0 ]
    then

        # use native package manager yum
		CMD="yum -y install tcl itcl tcltls tcllib tcl-devel iwidgets tclx itk tk mysqltcl"
		print_all "Installing with: ${CMD}" 2
		system_log "${CMD}"
        return $?
	fi
        
	print_all "Not sure how to install tcl/tk on this system." 1
	return 1
}

nsm_package_tcl_uninstall()
{
   	prompt_user_yesno "" "Uninstall tcl/tk packages(s)?" "Y"
   	[ ${?} -ne 0 ] && return 1

	# check it's presence and remove if required
	print_all "Uninstalling tcl/tk" 2

	# check if we are an ubuntu or debian system
    is_ubuntu || is_debian
    if [ ${?} -eq 0 ]
    then

        # use native package manager apt-get
		CMD="apt-get -y --purge --auto-remove remove tcl8.3 itcl3 mysqltcl tcltls tcllib tcl8.3-dev iwidgets4 tclx8.3 itk3 tcl8.4 tk8.4";
		print_all "Uninstalling with: ${CMD}" 2
        return $?
    fi


    # check if we are a redhat'ish system
	is_fedora || is_rhel || is_centos
    if [ ${?} -eq 0 ]
    then

        # use native package manager yum
		CMD="yum -y remove tcl itcl tcltls tcllib tcl-devel iwidgets tclx itk tk mysqltcl"
		print_all "Uninstalling with: ${CMD}" 2
        return $?
	fi
        
	print_all "Not sure how to install tcl/tk on this system." 1
	return 1
}

nsm_package_tcl_upgrade()
{
	print_all "tcl/tk has no upgrade options enabled" 2
}

#
# LOCAL FUNCTIONS
#
tcl_is_configured()
{
	print_all "Testing if tcl/tk is installed and configured correctly" 2

#	echo "set ERROR 0\n" \
#         "catch {package require Tclx} tclxVersion\n" \
#	     "catch {package require mysqltcl} mysqltclVersion\n" \
#	     "catch {package require tls} tlsVersion\n" \
#	     "catch {info exists ::tcl_platform(threaded)} threadedVersion\n" \
#	     "if { \\\$tclxVersion < 8.3 } {\n" \
#	     "  puts \"Need at least version 8.3 of Tclx.\"\n" \
#	     "  exit 1\n" \
#	     "}\n" \
#	     "if { [ string is double \\\$mysqltclVersion ] == 0 } {\n" \
#	     "  puts \"Unable to find mysqltcl in auto_path directories.\"\n" \
#	     "  exit 1\n" \
#	     "}\n" \
#	     "if { \\\$mysqltclVersion < 3.02 } {\n" \
#	     "  puts \"Need at least version 3.02 of mysqltcl.\"\n" \
#	     "  exit 1\n" \
#	     "}\n" \
#	     "if { \\\$tlsVersion < 1.5 } {\n" \
#	     "  puts \"Need at least version 1.5 of tls.\"\n" \
#	     "  exit 1\n" \
#	     "}\n" \
#	     "if { \\\$threadedVersion != 0 } {\n" \
#	     "  puts \"Version of tclsh is threaded. SGUILD will not run.\"\n" \
#	     "  exit 1\n" \
#	     "}\n" \
#	     "exit 0" | tclsh

echo | tclsh << EOF_TCL_TEST
set ERROR 0
set LOG [open $LOG_PATH a]
catch {package require Tclx} tclxVersion
catch {package require mysqltcl} mysqltclVersion
catch {package require tls} tlsVersion
catch {info exists ::tcl_platform(threaded)} threadedVersion
if { \$tclxVersion < 8.3 } {
  puts \$LOG "TCL Compatability Test: Need at least version 8.3 of Tclx."
  set ERROR 1
}
if { [ string is double \$mysqltclVersion ] == 0 } {
  puts \$LOG "TCL Compatability Test: Unable to find mysqltcl in auto_path directories."
  set ERROR 1
}
if { \$mysqltclVersion < 3.02 } {
  puts \$LOG "TCL Compatability Test: Need at least version 3.02 of mysqltcl."
  set ERROR 1
}
if { \$tlsVersion < 1.5 } {
  puts \$LOG "TCL Compatability Test: Need at least version 1.5 of tls."
  set ERROR 1
}
if { \$threadedVersion != 0 } {
  puts \$LOG "TCL Compatability Test: Version of tclsh is threaded. SGUILD will not run."
  set ERROR 1
}
if { \$ERROR == 0 } {
  puts \$LOG "TCL Compatability Test: OK"
}
close \$LOG
exit \$ERROR
EOF_TCL_TEST

    # execute
	if [ ${?} -ne 0 ]
    then
    	print_all "tcl/tk has encountered some errors" 2
		return 1
	fi
   
    print_all "tcl/tk is installed and configured correctly" 2
	return 0
}

