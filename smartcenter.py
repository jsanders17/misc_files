#!/usr/bin/python
#
# to install pexpect on ubuntu systems, you can run:
# sudo apt-get install python-pexpect
#
# joshua smith - 2012.05.24

import pexpect
import datetime

# get date/time variables for file name
now = datetime.datetime.now()
day = int(now.day)
month = int(now.month)
year = int(now.year)

# filename variable
filename = '/var/tmp/%i.%02i.%02i_10.0.195.11_cp_upgrade_export' % (now.year, now.month, now.day)

# log into smartcenter, cpstop, upgrade_export, cpstart, scp to backup, exit
print
print 'upgrade export going to ' + filename + '.tgz'
print
print '[*] logging into smartcenter'
child = pexpect.spawn ('ssh admin@10.0.195.11', timeout=30000)
child.expect ('Expert@smartcenter')
print '[*] logged into smartcenter, sending cpstop'
child.sendline ('export TMOUT=60000')
child.expect ('Expert@smartcenter')
child.sendline ('cpstop')
child.expect ('Expert@smartcenter', timeout=30000)
print '[*] cpstop finished, about to start upgrade_export'
print '    this can take 15+ min, please be patient'
child.sendline ('/opt/CPsuite-R77/fw1/bin/upgrade_tools/upgrade_export -n %s' % filename)
child.expect ('Expert@smartcenter', timeout=30000)
print '[*] upgrade_export finished, about to do a cpstart'
child.sendline ('cpstart')
child.expect ('Expert@smartcenter', timeout=30000)
print '[*] about to scp the upgrade export over to the backup server'
child.sendline ('scp %s.tgz user@10.0.195.181:/home/user/cron/10.0.195.11_cp_smartcenter_01' % filename)
child.expect ('Expert@smartcenter', timeout=30000)
print '[*] upgrade_export sent to backup server, removing the upgrade_export file from cp'
child.sendline ('rm %s.tgz' % filename)
child.expect ('Expert@smartcenter', timeout=30000)
child.sendline ('exit')
print '[*] finished'
