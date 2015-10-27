#!/bin/bash

# cleanup any bad state we left behind if the user exited while flash was running
# set defaults for all related parameters

set_enabled()
{
  gsettings set org.gnome.desktop.session idle-delay 90
  gsettings set org.gnome.desktop.screensaver idle-activation-enabled true
  gsettings set org.gnome.desktop.screensaver lock-enabled true
  gsettings set org.gnome.settings-daemon.plugins.power idle-dim true
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 300
}

set_disabled()
{
  gsettings set org.gnome.desktop.session idle-delay 0
  gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
  gsettings set org.gnome.desktop.screensaver lock-enabled false
  gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0
}

set_enabled
ss_disabled=0

while true; do
  sleep 45
  needs_be_disabled=0

  # get information about the foreground application
  current_window_id=`xprop -root | grep "_NET_ACTIVE_WINDOW(WINDOW)" | cut -d" " -f5`
  current_window_pid=`xprop -id $current_window_id | grep "_NET_WM_PID" | cut -d" " -f3`

  # check to see if flashplayer is being used either by iceweasel or by firefox
  flash_pid=`pgrep plugin-cont`
  if [ [ `pgrep iceweasel` ] || [ `pgrep firefox` ] ] && [ $flash_pid ]; then
    is_fullscreen=`xprop -id $current_window_id | grep "_NET_WM_STATE_FULLSCREEN"`
    # check if the foreground app is flashplayer and it's in fullscreen mode
    if [ "$is_fullscreen" ] && [ $current_window_pid = $flash_pid ]; then
      needs_be_disabled=1
      echo "Flash is in fullscreen mode"
    fi
  fi

  # check whether mozilla is the foreground app
  # then handle individual cases with several website titles
  if [ "`pgrep firefox`" = "$current_window_pid" ]; then
    regexp="^WM_NAME\(STRING\) = \"(.*)\"$"
    current_window_title=`xprop -id $current_window_id | grep "WM_NAME(STRING)"`
    [[ $current_window_title =~ $regexp ]]
    current_window_title=${BASH_REMATCH[1]}
    regexp="^.*(WAMAP).*$"
    [[ $current_window_title =~ $regexp ]]
    res=${BASH_REMATCH[1]}
    if [ "$res" != "" ]; then
      needs_be_disabled=1
      echo "WAMAP detected"
    fi
  fi

  # check whether skype is the foreground app
  if [ "`pgrep skype`" = "$current_window_pid" ]; then
    needs_be_disabled=1
    echo "Skype is the foreground app"
  fi

  # check if kindle reader is the foreground app
  if [ "`pgrep Kindle.exe`" = "$current_window_pid" ]; then
    needs_be_disabled=1
    echo "Kindle is the foreground app"
  fi

  # read current state of screensaver
  ss_state=`gsettings get org.gnome.desktop.screensaver idle-activation-enabled`

  # change state of screensaver as necessary
  if [ "$needs_be_disabled" = "1" ] && [ "$ss_state" = "true" ]; then
    set_disabled
    echo "Turning SS off"
    ss_disabled=1
  elif [ "$needs_be_disabled" = "0" ] && [ "$ss_state" = "false" ] && [ "$ss_disabled" = "1" ]; then
    set_enabled
    echo "Turning SS on"
    ss_disabled=0
  fi

done
