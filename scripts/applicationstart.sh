#!/bin/bash
exec 2> /tmp/applicationStart.log

# Restart apache
sudo /opt/bitnami/ctlscript.sh start
