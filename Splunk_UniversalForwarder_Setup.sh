#!/bin/bash

### Variables section
SPLUNK_UF_VERSION_RPM="splunkforwarder-9.1.1-64e843ea36b1.x86_64.rpm"
SPLUNK_UF_VERSION_DEB="splunkforwarder-9.1.1-64e843ea36b1-linux-2.6-amd64.deb"
DEPLOYMENT_SERVER=10.1.1.103 #Replace with the name/ip of your deployment server
DEPLOYMENT_PORT=8089 
INSTALL_DIR='/opt' 
SPLUNK_TEMPADMINPASS=changeme 

### End variables

# Check if you use root permissions 
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi


# Check if splunk forwarder is already installed
if [ -d "$INSTALL_DIR/splunkforwarder" ]
then
	echo "Host already has Splunk Forwarder installed. Exiting."; exit 1;
fi


# Install based on target OS
echo "Starting installation of Splunk Forwarder"
if command -v dpkg > /dev/null 2>&1; then
    dpkg -i $SPLUNK_UF_VERSION_DEB
	if [ $? -ne 0 ]; then
        echo "Installation failed"
        exit 1
    fi
elif command -v rpm > /dev/null 2>&1; then
   rpm -ivh $SPLUNK_UF_VERSION_RPM
   if [ $? -ne 0 ]; then
        echo "Installation failed"
        exit 1
    fi
else
    echo "Unsupported OS"
    exit 1
fi


# Configure the deployment server
echo "Configuring deployment server"
cat <<EOF >$INSTALL_DIR/splunkforwarder/etc/system/local/deploymentclient.conf
[target-broker:deploymentServer]
targetUri = ${DEPLOYMENT_SERVER}:${DEPLOYMENT_PORT}
EOF

# Set a default admin password
echo "Configuring Splunk Forwarder admin account"
cat <<EOF >$INSTALL_DIR/splunkforwarder/etc/system/local/user-seed.conf
[user_info]
USERNAME=admin
PASSWORD=${SPLUNK_TEMPADMINPASS}
EOF


# Change ownership to root
echo "Changing the root ownership on /opt/splunforwarder"
chown -R root:root $INSTALL_DIR/splunkforwarder


# Start the UF
echo "Starting Splunk Forwarder"
$INSTALL_DIR/splunkforwarder/bin/splunk start --no-prompt --accept-license --answer-yes


# Enable boot-start
echo "Enabling boot-start"
$INSTALL_DIR/splunkforwarder/bin/splunk enable boot-start -systemd-managed 0


# Check if the Splunk UF service is running properly
echo "Validating Splunk UF installation..."
$INSTALL_DIR/splunkforwarder/bin/splunk status
if [ $? -eq 0 ]; then
    echo "Splunk UF is running successfully."
else
    echo "There was a problem starting Splunk UF."
    exit 1
fi
