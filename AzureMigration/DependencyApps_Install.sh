#!/bin/bash
# Date: 30/06/2021
# Version: 0.0.1
# Author: Mawanda Hlophoyi
# Title:  This script install Azure Log Analytics agent, more on log WP @ "https://docs.microsoft.com/en-us/azure/azure-monitor/agents/gateway"
#         Installs service map, more on service map @ "https://docs.microsoft.com/en-us/azure/azure-monitor/vm/service-map
#
# Assumption:   Prepare the script to be executable by chmod +X DependencyApps_Install.sh
#
#Compile a list of the Linux servers IPs and upload to repository that you can reference below.
wget "https://sbgsanimagegallery.blob.core.windows.net/customscriptextension/AzureCloudLinux.zip?si=rl&spr=https&sv=2022-11-02&sr=b&sig=2DsRHKEOzGccG1soZXAr8hQJX%2FQoRXWSZ9%2BJidqZGWg%3D" -O /tmp/LinuxMigrationIps.txt
ips='/tmp/LinuxMigrationIps.txt'
for ip in ips
do
#Provide the workspaceID and key
wget https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh && sh onboard_agent.sh -w <WorkspaceID> -s <WorkspaceKey> -d opinsights.azure.com
#The GDB (Debugger), used to analyze code execution and is necessary for the proper operation of the OMS agent
sudo apt install gdb -y
wget "https://aka.ms/dependencyagentlinux" -O /tmp/InstallDependencyAgent-Linux64.bin
#Grant execute permission for the agent below.
sudo chmod +X /tmp/InstallDependencyAgent-Linux64.bin
sudo sh /tmp/InstallDependencyAgent-Linux64.bin -s
done