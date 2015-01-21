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
we_did_it=0

while true; do
  sleep 50
  do_turn_off=0

  # check to see if flashplayer is being used by iceweasel
  flash_pid=`pgrep plugin`
  if [ `pgrep iceweasel` ] && [ $flash_pid ]; then
    # check to see if current application is fullscreen
    current_window_id=`xprop -root | grep "_NET_ACTIVE_WINDOW(WINDOW)" | cut -d" " -f5`
    is_fullscreen=`xprop -id $current_window_id | grep "_NET_WM_STATE_FULLSCREEN"`
    current_window_pid=`xprop -id $current_window_id | grep "_NET_WM_PID" | cut -d" " -f3`
    if [ "$is_fullscreen" ] && [ $current_window_pid = $flash_pid ]; then
      do_turn_off=1
    fi
  fi

  # read current state of screensaver
  is_ss_on=`gsettings get org.gnome.desktop.screensaver idle-activation-enabled`
                                             
  # change state of screensaver as necessary
  if [ "$do_turn_off" = "1" ] && [ "$is_ss_on" = "true" ]; then
    set_disable
    we_did_it=1
  elif [ "$do_turn_off" = "0" ] && [ "$is_ss_on" = "false" ] && [ "$we_did_it" = "1" ]; then
    set_enable
    we_did_it=0
  fi

done
