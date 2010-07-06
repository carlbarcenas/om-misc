#!/bin/sh
# click to start, click to stop
 
if pidof conky | grep [0-9] > /dev/null
then
	exec killall conky
else
	sleep 45  # sleep not required for xfce on startup - 30 or more for others
	conky &
	exit
fi
