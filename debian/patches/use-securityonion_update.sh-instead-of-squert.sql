Description: <short summary of the patch>
 TODO: Put a short summary on the line above and replace this paragraph
 with a longer explanation of this change. Complete the meta-information
 with other relevant fields (see below for details). To make it easier, the
 information below has been extracted from the changelog. Adjust it or drop
 it.
 .
 securityonion-nsmnow-admin-scripts (20120724-0ubuntu0securityonion86) precise; urgency=low
 .
   * use securityonion_update.sh instead of squert.sql
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

--- securityonion-nsmnow-admin-scripts-20120724.orig/usr/lib/nsmnow/lib-nsm-server-utils
+++ securityonion-nsmnow-admin-scripts-20120724/usr/lib/nsmnow/lib-nsm-server-utils
@@ -595,7 +595,8 @@ EOF_SGUIL_DB
 	RET=$?
 
 	# MOVED FROM /usr/bin/sosetup
-	cat /var/www/squert/.scripts/squert.sql | mysql -uroot -U securityonion_db
+	#cat /var/www/squert/.scripts/squert.sql | mysql -uroot -U securityonion_db
+	bash /var/www/squert/.scripts/securityonion_update.sh
 	mysql -N -B --user=root -e "GRANT SELECT ON securityonion_db.* TO 'readonly'@'localhost' IDENTIFIED BY 'securityonion';"
 	mysql -N -B --user=root -e "GRANT ALL PRIVILEGES ON securityonion_db.mappings TO 'readonly'@'localhost' IDENTIFIED BY 'securityonion';"
 	mysql -N -B --user=root -e "GRANT ALL PRIVILEGES ON securityonion_db.ip2c TO 'readonly'@'localhost';"
@@ -845,7 +846,8 @@ EOF_SGUIL_DB
 	RET=$?
 
         # COPIED FROM ABOVE
-        cat /var/www/squert/.scripts/squert.sql | mysql -uroot -U securityonion_db
+        #cat /var/www/squert/.scripts/squert.sql | mysql -uroot -U securityonion_db
+	bash /var/www/squert/.scripts/securityonion_update.sh
         mysql -N -B --user=root -e "GRANT SELECT ON securityonion_db.* TO 'readonly'@'localhost' IDENTIFIED BY 'securityonion';"
         mysql -N -B --user=root -e "GRANT ALL PRIVILEGES ON securityonion_db.mappings TO 'readonly'@'localhost' IDENTIFIED BY 'securityonion';"
         mysql -N -B --user=root -e "GRANT ALL PRIVILEGES ON securityonion_db.ip2c TO 'readonly'@'localhost';"
