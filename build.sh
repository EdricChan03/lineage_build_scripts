#!/bin/bash

# When Ctrl+C is pressed, the whole program will exit
# See https://stackoverflow.com/a/32146079 for more info
trap "exit" INT

# Source common functions
source ./functions.sh

# If a command exits with a non-zero status code, exit this program immediately
# See `set --help` for more info
# set -e

# Function for showing an input dialog on what device codenames to build
buildDialog() {
  devices=$(whiptail --title "Device build dialog" --inputbox "Enter a list of device codenames. Separate each device codename by a space." 10 40 3>&1 1>&2 2>&3)
  build $devices
  for i in "${#outdirs[@]}";
  do
    echo "Device ${devices[i]} built at ${outdirs[i]}."
  done
}

# Function for showing a confirmation dialog when a command has finished executing
doneExec() {
  whiptail --title "Confirm dialog" --yesno "Go back to main menu?" 10 25
  if [[ $? -eq 0 ]]; then
    mainMenu
  else
    infoBold "Exiting..."
    exit 0
  fi
}

# Function for showing a confirmation dialog on whether to exit the program
confirmExit() {
  whiptail --title "Confirm dialog" --yesno "Are you sure you want to exit?" 10 25
  if [[ $? -eq 0 ]]; then
    infoBold "Exiting..."
    exit 0
  else
    mainMenu
  fi
}

# Function for handling menu items
# @param $1 The menu item that has been entered
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
    candroid
    buildDialog
    doneExec
  elif [[ "$menuResult" = "Help" ]]; then
    whiptail --title "Notice" --msgbox "The help guide is coming soon! Stay tuned." 10 25
    mainMenu
  fi
}

# Function for showing a menu when the program has been executed
mainMenu() {
  choices=("Exit" "Quit the script." "Sync" "Sync the Android Source." "Build" "Build for a device(s)." "Help" "Show help.")
  results=$(whiptail --title "Utilities" --menu "Choose one of the options below:" 15 50 0  "${choices[@]}" 3>&1 1>&2 2>&3)
  mainMenuHandler "$results"
}

mainMenu
