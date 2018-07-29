#!/bin/bash
source ./functions.sh

buildDialog() {
  devices=$(whiptail --title "Device build dialog" --inputbox "Enter a list of device codenames. Separate each device codename by a space." 10 40 3>&1 1>&2 2>&3)
  build $devices
}
doneExec() {
  whiptail --title "Confirm dialog" --yesno "Go back to main menu?" 10 25
  if [[ $? -eq 0 ]]; then
    mainMenu
  else
    infoBold "Exiting..."
    exit 0
  fi
}

confirmExit() {
  whiptail --title "Confirm dialog" --yesno "Are you sure you want to exit?" 10 25
  if [[ $? -eq 0 ]]; then
    infoBold "Exiting..."
    exit 0
  else
    mainMenu
  fi
}

mainMenuHandler() {
  # echo "$1"
  menuResult="$1"
  if [[ "$menuResult" = "Exit" ]]; then
    confirmExit
  elif [[ "$menuResult" = "Sync" ]]; then
    # Change working directory to the Android Source directory
    candroid
    # Sync changes
    sync
    # Show a "Go back to main menu" dialog
    doneExec
  elif [[ "$menuResult" = "Build" ]]; then
    buildDialog
    doneExec
  elif [[ "$menuResult" = "Help" ]]; then
    whiptail --title "Notice" --msgbox "The help guide is coming soon! Stay tuned." 10 25
    mainMenu
  fi
}

mainMenu() {
  choices=("Exit" "Quit the script." "Sync" "Sync the Android Source." "Build" "Build for a device(s)." "Help" "Show help.")
  results=$(whiptail --title "Utilities" --menu "Choose one of the options below:" 25 78 16  "${choices[@]}" 3>&1 1>&2 2>&3)
  mainMenuHandler "$results"
}

mainMenu

# listItems=("Wow" "XD" "Meh")
# testWow=("hlte" "hltekor")
# build "${testWow[@]}"
# devices=$(whiptail --inputbox "Enter a list of device codenames. Separate each device codename by a space." 8 50 --title "Build devices prompt" 3>&1 1>&2 2>&3)
# A trick to swap stdout and stderr.
# Again, you can pack this inside if, but it seems really long for some 80-col terminal users.
# exitstatus=$?
# if [ $exitstatus = 0 ]; then
#     echo "User selected Ok and entered" $devices
# else
#     echo "User selected Cancel."
# fi

# echo "(Exit status was $exitstatus)"

# {
#     for ((i = 0 ; i <= 100 ; i+=1)); do
#         sleep 1
#         echo $i
#     done
# } | whiptail --gauge "Please wait while installing" 6 60 0
