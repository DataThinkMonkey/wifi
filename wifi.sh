#!/bin/bash
# Created by Jared Bernard
# 
#
# Script designed to attempt various methods of reconnecting to wireless
# network. 
# I originally designed this for wifi connections that were once connected
# but for one reason or another was disconnected and attempting to 
# reconnect. 
#
# Still have tons to work on and clean up. 
# To-do
# Write function for ping test. 
# Clean up output to stdout. 
# Check for other networking issues
## dns, net config, ping gw, test other site besides google.com, etc
# Add comments.
#
# Still a work in progress.

# Check connectivity outside gateway. 
echo "Checking your connection."
echo "Pinging google.com to verify connectivity."
echo
ping -c 3 google.com 

if [[ $? = 0  ]]
then
	echo
	echo "Networking is functioning as expected."
	echo
	echo "No need to attempt and recover wireless network."
	echo
	echo "Wireless check complete."

else
	echo 
	echo "Pinging outside your network FAILED."
	echo 
	echo "Engaging wireless recovery..."
	echo 
	echo "-----WIRELESS DETAIL-----"
	echo
	echo "wlan0 is status: $(nmcli radio wifi)"
	echo
	nmcli general status
	echo 
	nmcli connection show --active
	echo
	echo "Disabling Wireless Connection."
	echo 
	nmcli radio wifi off
	echo "Enabling Wireless Connection."
	nmcli radio wifi on
	echo "Pinging outside your network."
	echo
	echo "Checking your connection."
	sleep 3
	echo "Pinging google.com to verify connectivity."
	ping -c 3 google.com 

	if [[ $? != 0  ]]
	then
		echo "Pinging outside your network FAILED."
		echo "Re-enabling Wireless Connection Failed. "
		echo "Restarting the network."
		echo
		sudo systemctl restart networking
		echo "Restarting network-manager."
		sudo systemctl restart network-manager
		echo "Network and device restarted."
		echo "Pinging outside your network."
		echo
		echo "Checking your connection."
		echo "Pinging google.com to verify connectivity."
		sleep 3
		ping -c 3 google.com 
		if [[ $? != 0  ]]
		then
			echo "Pinging outside your network FAILED."
			echo "Reloading wireless driver."
			# My HP Probook should be rtl8723be
			d=$(basename $( readlink /sys/class/net/wlan0/device/driver ))
			sudo rmmod "$d" && sudo modprobe -v "$d"
			echo
			echo "Wireless driver reloaded."
			echo "Checking your connection."
			sleep 3
			ping -c 3 google.com
			if [[ $? != 0  ]]
			then
				w=$(nmcli device wifi list | grep -E '^\*' | awk 'NR==2' | cut -d' ' -f3)
				echo "Pinging outside your network FAILED."
				echo "However you are connected to the following network."
				nmcli device wifi list | grep -E '^\*'
				read -p "Would you like to connect to another network? (y|n): " i
				if [[ "$i" = [Yy] ]]
				then
					echo "Deleting connection $w"
					nmcli connection delete id $w
					echo 
					echo "-----Avaiable Connections.-----"
					nmcli device wifi list
					echo 
					read -p "Enter the name of the SSID you would like to connect to:  " s
					read -p "Enter the passphrase of $s : " p
					nmcli device wifi connect $s password $p
					echo 
					echo "You should be connected"
					echo "Test connection or attempt other networking solutions."
				else
					echo "Attempt other networking solutions."
				fi	
									
				else
				echo "All troubleshooting attempts completed."
				# To-do check physical device, dns, net, etc 
				echo "Attempt other networking solutions."
			fi
		else
			echo "You are connected."
		fi
	else
		echo "You are connected."
	fi
fi
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

