#!/bin/sh

# Set the display we are looking for here.
# I am interested in a CRT monitor being attached, but this could be TV-0 or something

DISPLAY_TARGET="TV-0"

# Ensure that desired display is attached by probing the currently connected displays
# and seeing if GREP has failed or not

nv-control-dpy --probe-dpys | grep $DISPLAY_TARGET > /dev/null 2>&1
if [ $? -gt 0 ] ; then
  echo 1>&2 'Error: Could not discover the display "'$DISPLAY_TARGET'"'
  exit 1
fi

# Since display exists, we need to build the modepool for all displays, if this has not been done already

nv-control-dpy --build-modepool > /dev/null 2>&1
if [ $? -gt 0 ] ; then
  echo 1>&2 'Error: Could not build modepools'
  exit 1
fi

# See if device is currently enabled
# nv-control-dpy basically returns a list of the associated displays as bitwise values
# Then outputs a final device mask which indicates which of those displays are being used
# So if my CRT-0 has a value of 0x00000001 and internal display DFP-0 is 0x00010000
# then a device mask of 0x00010000 would indicate the CRT is not enabled, but 0x00010001
# means they're both enabled.
 
NVOUTPUT=`nv-control-dpy --get-associated-dpys`
DISPLAY_TARGET_BITMASK=`expr "$NVOUTPUT" : ".*$DISPLAY_TARGET (\(..........\)"`
DISPLAY_ALLOLD_BITMASK=`expr "$NVOUTPUT" : ".*device mask: \(..........\)"`
DISPLAY_ALLNEW_BITMASK=$(($DISPLAY_ALLOLD_BITMASK | $DISPLAY_TARGET_BITMASK))

if [ $DISPLAY_ALLNEW_BITMASK = $(($DISPLAY_ALLOLD_BITMASK)) ] ; then
  echo 1>&2 'Error: The display is already enabled'
  #exit 1
fi

nv-control-dpy --set-associated-dpys $DISPLAY_ALLNEW_BITMASK > /dev/null 2>&1

if [ $? -gt 0 ] ; then
  echo 1>&2 'Error: There was a problem enabling the display'
  exit 1
fi

# I have my laptop display (DFP-0) on the left, and I want it to be the 'primary' display
# then CRT, then TV. This way, when I enable the screen, the gnome panel won't jump over to the CRT
# as a new primary monitor
nv-control-dpy --assign-twinview-xinerama-info-order 'DFP-0,DFP-1,TV-0' > /dev/null 2>&1

# The way we can enable the screen is to add the display as a metamode and get xrandr to switch to it
# Any display with a value of 'nvidia-auto-select' means it is part of the mode
# Any display set to NULL means it is not part of the mode
# This line needs to be modified for every user's particular needs,
# especially the coordinates.
NVOUTPUT=`nv-control-dpy --add-metamode "TV-0: nvidia-auto-select +0+0,DFP-0: nvidia-auto-select +1024+0"`

if [ $? -gt 0 ] ; then
  echo 1>&2 'Error: Could not add metamode'
  #exit 1
fi

# The output from nv-control-dpy includes the refresh rate of the new mode.
# This acts as a kind of unique id for the entry
MODES=`xrandr`
ACTIVE=`expr "$MODES" : ".* \([0-9]*x[0-9]*\)[ ]*50.0\*.*"`

if [ -n "$ACTIVE" ] ; then
  echo "Switching to TV-OUT"
  xrandr -s 2944x1080@51.0
else
  echo "Switching to DELL2005FPW"
  xrandr -s 3600x1080@50.0
fi
