#!/bin/sh

#################################################################################
# Description:                                                                  #
#                                                                               #
# This script is intended to execute post installation activities for newly     #
# deployed firewalls.  The script adjusts several firewall parameters, which    #
# are explained in each section of the script.                                  #
#                                                                               #
# Last Modified:     12-19-2007                                                 # 
# Modified By:       Mayur Pathak                                               #
#                                                                               #
# Modifications:     Consolidate postinstall scripts for IPSO 3.x and 4.x.      #
#                    Put in checks for updating user roles based on UID (4.x).  #
#                    Added chown to bckadmin .ssh directory. 
#    01-07-2008      Added postinstall for disk-based system (M. Pathak)        #
#    02-25-2007:     Fixed typo in 4.x bckadmin commands (B.Porter) 
#    10-10-2006      Added postinstall for diskbase systems ( Scott Winningham) #
#################################################################################

#################################################################################
# Variable declarations and DNS check.
#################################################################################

var1=`hostname`
nslookup $var1

osvera="3.7"
osverb="3.8.1"

rawipso=`echo show image current | clish`
ipsobuild=`echo $rawipso | awk -F"-" '{print $2}'`

if [ $ipsobuild = $osvera -o $ipsobuild = $osverb ]; then

    #############################################################################
    # IPSO 3.7 and 3.8.1 Post Install Procedures.   
    # Create target directories and firewall static info files.
    #############################################################################

    if [ ! -d /var/BAS ] ; then /bin/mkdir -p /var/BAS ; fi
    if [ ! -d /var/support ] ; then /bin/mkdir -p /var/support ; fi
    if [ ! -d /var/data/NHM ] ; then /bin/mkdir -p /var/data/NHM ; fi

    /bin/echo $var1 > /var/data/NHM/$var1-pair
    /bin/cat /dev/null > /var/data/NHM/$var1
    /bin/cat /dev/null > /var/data/NHM/$var1-site
    /bin/cat /dev/null > /var/data/NHM/$var1-rack
    /bin/cat /dev/null > /var/data/NHM/$var1-console

    #############################################################################
    # Reads account.txt and creates user account.
    # (The source file account.txt is generated from an existing 3.x firewall).
    #############################################################################

    if [ -f /var/data/NHM/account.txt ]; then
      /bin/cat /var/data/NHM/account.txt | while read a b c
        do {
            /bin/clish -c "add user $a uid $b homedir $c"
            sleep 1
           }
        done
    else
        echo "File /var/data/NHM/account.txt not found!"
        echo "User accounts not created!"
        exit 0
    fi

    #############################################################################
    # Creates "silent" (key-based) SSH access necessary for the bckadmin account.
    #############################################################################

    /bin/clish -c "add user bckadmin uid 22706 homedir /var/bckadmin"
    /bin/mkdir /var/bckadmin/.ssh
    /bin/chmod 700 /var/bckadmin/.ssh
    /usr/sbin/chown bckadmin /var/bckadmin/.ssh

    ### Push the authorized_keys file from the ARC server after postinstall to the
    ### /var/bckadmin/.ssh directory. Permissions should be 600 and owned by bckadmin.

    #############################################################################
    # Creates privileged access needed for nhmact1.
    #############################################################################

    /sbin/mount -uw /
    /bin/chmod 744 /usr/lib/cli/lib/cli.acl

    echo " " >> /usr/lib/cli/lib/cli.acl
    echo "# Allow everything to 'nhmact1' user." >> /usr/lib/cli/lib/cli.acl
    echo "AclName := nhmact1" >> /usr/lib/cli/lib/cli.acl
    echo "AclType := CliUser" >> /usr/lib/cli/lib/cli.acl
    echo "AclPerm := NotAllowed" >> /usr/lib/cli/lib/cli.acl

    /bin/chmod 444 /usr/lib/cli/lib/cli.acl

    /sbin/mount -o ro /

else

    #############################################################################
    # IPSO 4.0.1 and 4.1 Post Install Procedures.
    # Create target directories and firewall static info files.
    # Also add permanent soft links to appropriate directories in the rc.flash file.
    #############################################################################
    
diskstat="0"

rawdisk=`ipsctl -a | /usr/bin/grep kern:diskless`
diskchk=`echo $rawdisk | awk -F "" '{print $3}'`
if [ $diskchk = $diskstat ]; then

     	if [ ! -d /var/emhome/admin ] ; then /bin/mkdir -p /var/emhome/admin ; fi
    	if [ ! -d /var/emhome/bckadmin ] ; then /bin/mkdir -p /var/emhome/bckadmin ; fi
    
   
    	/bin/echo $var1 > /var/data/NHM/$var1-pair
   	 /bin/cat /dev/null > /var/data/NHM/$var1
    	/bin/cat /dev/null > /var/data/NHM/$var1-site
    	/bin/cat /dev/null > /var/data/NHM/$var1-rack
    	/bin/cat /dev/null > /var/data/NHM/$var1-console
    
    #############################################################################
    # Reads /var/data/NHM/account1.txt file and creates user accounts and
    # assigns default shell. Also sets the role permissions for UIDs greater than
    # "0" so that those accounts may utilize Voyager. (The source file account1.txt
    # is generated from an existing IPSO 4.x firewall.)
    #############################################################################

    		if [ -f /var/data/NHM/account1.txt ]; then
     		 /bin/cat /var/data/NHM/account1.txt | while read a b c
     	  	do {
           		 if [ $b -gt 200 ]; then
              	/bin/clish -c "add user $a uid $b homedir $c"
              	/bin/clish -c "set user $a shell /bin/csh"
              	/bin/clish -c "add rba user $a roles monitorRole"
              	sleep 1
            	else
              	/bin/clish -c "add user $a uid $b homedir $c"
              	/bin/clish -c "set user $a shell /bin/csh"
              	sleep 1
           		 fi
           		}
      	 	done
    		else
      		echo "File /var/data/NHM/account1.txt not found!"
      		echo "User accounts not created!"
      		exit 0
    		fi
   
    #############################################################################
    # Creates "silent" (key-based) SSH access necessary for the bckadmin account
    #############################################################################

   	 /usr/sbin/chown bckadmin /var/emhome/bckadmin
    	/bin/chmod 700 /var/emhome/bckadmin 
    	/bin/mkdir /var/emhome/bckadmin/.ssh
    	/bin/chmod 700 /var/emhome/bckadmin/.ssh
    	/usr/sbin/chown bckadmin /var/emhome/bckadmin/.ssh

    ### Push the authorized_keys file from the ARC server after postinstall to the 
    ### /var/emhome/bckadmin/.ssh directory. Permissions should be 600 and owned by bckadmin
    
else
    
   	 /sbin/mount -uw /
    	/bin/chmod 744 /etc/rc.flash
	
 echo "ln -s /preserve/var/emhome/bckadmin /var/emhome/bckadmin > /dev/null 2>&1;" >> /etc/rc.flash
    	echo "ln -s /preserve/var/data /var/data > /dev/null 2>&1;" >> /etc/rc.flash

    	/bin/chmod 544 /etc/rc.flash

    	/sbin/mount -o ro /
    	if [ ! -d /var/emhome/admin ] ; then /bin/mkdir -p /var/emhome/admin ; fi
    	if [ ! -d /preserve/var/emhome/bckadmin ] ; then /bin/mkdir -p /preserve/var/emhome/bckadmin ; fi

    	/bin/echo $var1 > /var/data/NHM/$var1-pair
    	/bin/cat /dev/null > /var/data/NHM/$var1
    	/bin/cat /dev/null > /var/data/NHM/$var1-site
    	/bin/cat /dev/null > /var/data/NHM/$var1-rack
    	/bin/cat /dev/null > /var/data/NHM/$var1-console 

    #############################################################################
    # Reads /var/data/NHM/account1.txt file and creates user accounts and
    # assigns default shell. Also sets the role permissions for UIDs greater than
    # "0" so that those accounts may utilize Voyager. (The source file account1.txt
    # is generated from an existing IPSO 4.x firewall.)
    #############################################################################

    	if [ -f /var/data/NHM/account1.txt ]; then
      	/bin/cat /var/data/NHM/account1.txt | while read a b c
       	do {
            if [ $b -gt 200 ]; then
              /bin/clish -c "add user $a uid $b homedir $c"
              /bin/clish -c "set user $a shell /bin/csh"
              /bin/clish -c "add rba user $a roles monitorRole"
              sleep 1
            else
              /bin/clish -c "add user $a uid $b homedir $c"
              /bin/clish -c "set user $a shell /bin/csh"
              sleep 1
            fi
           }
       	done
    	else
      	echo "File /var/data/NHM/account1.txt not found!"
      	echo "User accounts not created!"
      	exit 0
   	fi

    #############################################################################
    # Creates "silent" (key-based) SSH access necessary for the bckadmin account
    #############################################################################

    	/bin/rm -r /var/emhome/bckadmin
   	/bin/ln -s /preserve/var/emhome/bckadmin /var/emhome/bckadmin
    	/usr/sbin/chown bckadmin /preserve/var/emhome/bckadmin
    	/bin/chmod 700 /preserve/var/emhome/bckadmin 
    	/bin/mkdir /var/emhome/bckadmin/.ssh
    	/bin/chmod 700 /var/emhome/bckadmin/.ssh
    	/usr/sbin/chown bckadmin /var/emhome/bckadmin/.ssh

    ### Push the authorized_keys file from the ARC server after postinstall to the 
    ### /var/emhome/bckadmin/.ssh directory. Permissions should be 600 and owned by bckadmin.
fi
 
#################################################################################
# AAA access is needed for production authentication and is setup in this section
#################################################################################

/bin/clish -c "add aaa authprofile Radius_authprofile authtype RADIUS authcontrol sufficient"
/bin/clish -c "add aaa radius-servers authprofile Radius_authprofile priority 10 host 162.111.68.236 port 1645 secret encrypted timeout 3 maxtries 3"
/bin/clish -c "add aaa radius-servers authprofile Radius_authprofile priority 20 host 167.143.48.121 port 1645 secret encrypted timeout 3 maxtries 3"
/bin/clish -c "add aaa radius-servers authprofile Radius_authprofile priority 30 host 167.143.160.100 port 1645 secret encrypted timeout 3 maxtries 3"
/bin/clish -c "add aaa profile base_prof_sshd authprofile Radius_authprofile acctprofile base_sshd_acctprofile sessprofile base_sshd_sessprofile"
/bin/clish -c "set aaa profile base_prof_sshd authprofile Radius_authprofile auth-priority 1"
/bin/clish -c "set aaa profile base_prof_sshd authprofile base_sshd_authprofile auth-priority 2"
/bin/clish -c "add aaa profile base_prof_httpd authprofile Radius_authprofile acctprofile base_httpd_acctprofile sessprofile base_httpd_sessprofile"
/bin/clish -c "set aaa profile base_prof_httpd authprofile Radius_authprofile auth-priority 1"
/bin/clish -c "set aaa profile base_prof_httpd authprofile base_httpd_authprofile auth-priority 2" 
/bin/clish -c "save config"
fi
#################################################################################
# End of Script                                                                 #
#################################################################################
