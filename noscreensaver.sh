#!/bin/bash

# cleanup any bad state we left behind if the user exited while flash was running
# set defaults for all related parameters

set_enable()
{
  gsettings set org.gnome.desktop.session idle-delay 90
  gsettings set org.gnome.desktop.screensaver idle-activation-enabled true
  gsettings set org.gnome.desktop.screensaver lock-enabled true
  gsettings set org.gnome.settings-daemon.plugins.power idle-dim-ac true
  gsettings set org.gnome.settings-daemon.plugins.power idle-dim-battery true
  gsettings set org.gnome.settings-daemon.plugins.power sleep-display-ac 300
  gsettings set org.gnome.settings-daemon.plugins.power sleep-display-battery 120
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 300
}

set_disable()
{
  gsettings set org.gnome.desktop.session idle-delay 0
  gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
  gsettings set org.gnome.desktop.screensaver lock-enabled false
  gsettings set org.gnome.settings-daemon.plugins.power idle-dim-ac false
  gsettings set org.gnome.settings-daemon.plugins.power idle-dim-battery false
  gsettings set org.gnome.settings-daemon.plugins.power sleep-display-ac 0
  gsettings set org.gnome.settings-daemon.plugins.power sleep-display-battery 0
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0
}

set_enable
ss_disabled=0

while true; do
  sleep 50
  flash_fullscreen=0

  # check to see if flashplayer is being used by iceweasel
  flash_pid=`pgrep plugin`
  if [ `pgrep iceweasel` ] && [ $flash_pid ]; then
    # get information about the foreground application
    current_window_id=`xprop -root | grep "_NET_ACTIVE_WINDOW(WINDOW)" | cut -d" " -f5`
    current_window_props=`xprop -id $current_window_id` 
    is_fullscreen=`$current_window_props | grep "_NET_WM_STATE_FULLSCREEN"`
    current_window_pid=`$current_window_props | grep "_NET_WM_PID" | cut -d" " -f3`
    # check if the foreground app is flashplayer and it's in fullscreen mode
    if [ "$is_fullscreen" ] && [ $current_window_pid = $flash_pid ]; then
      flash_fullscreen=1
    fi
  fi

  # read current state of screensaver
  ss_state=`gsettings get org.gnome.desktop.screensaver idle-activation-enabled`
                                             
  # change state of screensaver as necessary
  if [ "$flash_fullscreen" = "1" ] && [ "$ss_state" = "true" ]; then
    set_disable
    ss_disabled=1
  elif [ "$flash_fullscreen" = "0" ] && [ "$ss_state" = "false" ] && [ "$ss_disabled" = "1" ]; then
    set_enable
   ss_disabled=0
  fi

done
