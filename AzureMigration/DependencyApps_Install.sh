#!/bin/bash
# Date: 30/06/2021
# Version: 0.0.1
# Author: Mawanda Hlophoyi
# Title:  This script install Azure Log Analytics agent, more on log WP @ "https://docs.microsoft.com/en-us/azure/azure-monitor/agents/gateway"
#         Installs service map, more on service map @ "https://docs.microsoft.com/en-us/azure/azure-monitor/vm/service-map
#
# Assumption:   Prepare the script to be executable by chmod +X DependencyApps_Install.sh
wget "https://developmentupload.blob.core.windows.net/client-dev/LinuxMigrationIps.txt?sv=2020-08-04&si=RL-2021-Policy&sr=b&sig=bE1V7kaLJZRetEi2wGHZ8hBY8ICNK5liuE30rwz73MU%3D" -O /tmp/LinuxMigrationIps.txt
ips='/tmp/LinuxMigrationIps.txt'
for ip in ips
do
wget https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh && sh onboard_agent.sh -w <WorkspaceID> -s <WorkspaceKey> -d opinsights.azure.com
sudo apt install gdb -y
wget "https://aka.ms/dependencyagentlinux" -O /tmp/InstallDependencyAgent-Linux64.bin
sudo chmod +X /tmp/InstallDependencyAgent-Linux64.bin
sudo sh /tmp/InstallDependencyAgent-Linux64.bin -s
done