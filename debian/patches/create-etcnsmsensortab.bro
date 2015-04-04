Description: <short summary of the patch>
 TODO: Put a short summary on the line above and replace this paragraph
 with a longer explanation of this change. Complete the meta-information
 with other relevant fields (see below for details). To make it easier, the
 information below has been extracted from the changelog. Adjust it or drop
 it.
 .
 securityonion-nsmnow-admin-scripts (20120724-0ubuntu0securityonion78) precise; urgency=low
 .
   * create /etc/nsm/sensortab.bro
Author: Doug Burks <doug.burks@gmail.com>

---
The information above should follow the Patch Tagging Guidelines, please
checkout http://dep.debian.net/deps/dep3/ to learn about the format. Here
are templates for supplementary fields that you might want to add:

Origin: <vendor|upstream|other>, <url of original patch>
Bug: <url in upstream bugtracker>
Bug-Debian: http://bugs.debian.org/<bugnumber>
Bug-Ubuntu: https://launchpad.net/bugs/<bugnumber>
Forwarded: <no|not-needed|url proving that it has been forwarded>
Reviewed-By: <name and email of someone who approved the patch>
Last-Update: <YYYY-MM-DD>

--- securityonion-nsmnow-admin-scripts-20120724.orig/usr/sbin/nsm_sensor_ps-start
+++ securityonion-nsmnow-admin-scripts-20120724/usr/sbin/nsm_sensor_ps-start
@@ -335,12 +335,21 @@ fi
 
 if [ "$BRO_ENABLED" == "yes" ] && [ -z "$SKIP_BRO" ] && grep -v "^#" /etc/nsm/sensortab>/dev/null ; then
 	echo_msg 0 "Starting: Bro"
+
 	# Update IP if necessary
 	if grep "^type=manager$" /opt/bro/etc/node.cfg >/dev/null 2>&1; then
 		IP=`ifconfig |grep "inet addr" | awk '{print $2}' |cut -d\: -f2 |grep -v "127.0.0.1" |head -1`
 		sed -i "s|^host=.*$|host=$IP|g" /opt/bro/etc/node.cfg
 	fi
+
+	# Update /etc/nsm/sensortab.bro
+	echo -e "#fields\tinterface\tsensorname" > /etc/nsm/sensortab.bro
+	grep -v "^#" /etc/nsm/sensortab | while read SENSORNAME FIELD2 FIELD3 INTERFACE; do echo -e "$INTERFACE\t$SENSORNAME" >> /etc/nsm/sensortab.bro; done
+		
+	# Update Bro config
 	/opt/bro/bin/broctl install
+
+	# Start Bro
 	/opt/bro/bin/broctl start
 fi
 
--- securityonion-nsmnow-admin-scripts-20120724.orig/usr/sbin/nsm_sensor_ps-restart
+++ securityonion-nsmnow-admin-scripts-20120724/usr/sbin/nsm_sensor_ps-restart
@@ -339,13 +339,24 @@ fi
 
 if [ "$BRO_ENABLED" == "yes" ] && [ -z "$SKIP_BRO" ] && [ "$ACTION" == "process_restart" ] && grep -v "^#" /etc/nsm/sensortab>/dev/null ; then
         echo_msg 0 "Restarting: Bro"
+
         # Update IP if necessary
         if grep "^type=manager$" /opt/bro/etc/node.cfg >/dev/null 2>&1; then
                 IP=`ifconfig |grep "inet addr" | awk '{print $2}' |cut -d\: -f2 |grep -v "127.0.0.1" |head -1`
                 sed -i "s|^host=.*$|host=$IP|g" /opt/bro/etc/node.cfg
         fi
+	
+        # Update /etc/nsm/sensortab.bro
+        echo -e "#fields\tinterface\tsensorname" > /etc/nsm/sensortab.bro
+        grep -v "^#" /etc/nsm/sensortab | while read SENSORNAME FIELD2 FIELD3 INTERFACE; do echo -e "$INTERFACE\t$SENSORNAME" >> /etc/nsm/sensortab.bro; done
+
+	# Stop Bro
         /opt/bro/bin/broctl stop
+
+        # Update Bro config
         /opt/bro/bin/broctl install
+
+	# Start Bro
         /opt/bro/bin/broctl start
 fi
 
