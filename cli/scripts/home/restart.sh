#!/bin/bash
source /home/boomi/.profile
restart_log="restart${ATOM_LOCALHOSTID}.log"

date >> "${restart_log}" 2>&1
echo "Using systemd in docker container for restart. Check journalctl in container for logs." >> "${restart_log}" 2>&1
sudo systemctl restart atom
