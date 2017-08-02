#!/bin/bash
# Created by Jared Bernard
# 
#
# Script designed to attempt various methods of reconnecting to wireless
# network. 
# I originally designed this for wifi connections that were once connected
# but for one reason or another were disconnected. 
#
# Still have tons to work on and clean up. 
# To-do
# Clean up output to stdout. 
# Check for other networking issues
## dns, net config, ping gw, test other site besides google.com, etc
# Add comments.
#
# Still a work in progress.

#  Pinging google.com to test connectivity.
gp() {
	echo "Verifying connectivity."
	echo "Please be patient. "
	echo "Pinging google.com..."
	echo
	ping -c 3 google.com > /dev/null
}


good () {
	echo
	echo "You are good to go!"
	echo 
	exit
}	
fail () {
	echo
	echo "Pinging outside your network FAILED"
	echo "Initiating attempts to reconnect you network."
}

tconn () {
	gp
	if [[ $? != 0 ]]
	then
		fail
	else
		good
	fi
}

radio () {
	echo
	echo "Disabling Wireless Connection."
	nmcli radio wifi off
	echo "Enabling Wireless Connection."
	nmcli radio wifi on
	echo "Wireless connection re-enabled."
	gp
	if [[ $? != 0 ]]
	then
		fail
	else
		good
	fi
}

net () {
	sleep 3
	gp
	if [[ $? != 0 ]]
	then
		fail
		echo "Restarting the network."
		echo "You will be required to enter sudo password."
		sudo systemctl restart networking
		echo "Restarting network-manager."
		sudo systemctl restart network-manager
		echo "Network and device restarted."
	else
		good
	fi
}

drive () {
	sleep 3
	gp
	if [[ $? != 0 ]]
	then
		fail
		echo "Reloading wireless driver."
		# My HP Probook should be rtl8723be
		# Wireless device name
		wifi=$(nmcli dev status | grep wifi | cut -d' ' -f1)
		# hardlink to device wlan, may need to make more dynamic.
		d=$(basename $( readlink /sys/class/net/$wifi/device/driver ))
		# Remove and re-insert driver
		sudo rmmod "$d" && sudo modprobe -v "$d"
		echo "Wireless driver reloaded."
	else
		good
	fi
}

nconn () {
	sleep 3
	gp	
	if [[ $? != 0 ]]
	then
		fail
		echo "You are currently connected to the following network."
		echo 
		# List Current wireless network with info
		nmcli device wifi list | grep -E '^\*'
		echo
		read -p "Would you like to connect to another network? (y|n): " i
		if [[ "$i" = [Yy] ]]
		then
			# Network currently connected to, SSID only.
			w=$(nmcli device wifi list | grep -E '^\*' | awk 'NR==2' | cut -d' ' -f3)
			echo "Deleting your current connection: $w"
			nmcli connection delete id $w
			echo 
			echo "-----Avaiable Connections.-----"
			nmcli device wifi list
			echo 
			read -p "Enter the name of the SSID you would like to connect to: " s
			read -p "Enter the passphrase of "$s" : " p
			nmcli device wifi connect "$s" password $p
			echo 
			echo "You should be connected"
			echo "Test connection or attempt other networking solutions."
		else
			echo "Attempt other networking solutions."
		fi
	else
		good
	fi
}

tconn
radio
net
drive
nconn

# -----------------------------------------------------------------
# reference 
		# nmcli connection down id bernards
		# nmcli connection up id bernards
		# Scan, connect or add new network
		# nmcli device wifi list
		# nmcli device wifi rescan
		# nmcli device wifi connect <SSiD>
		# nmcli device wifi connect <SSID|BSSID> password <password>
#--------------------------------------------------------------------------		
