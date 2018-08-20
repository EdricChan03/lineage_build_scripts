#!/bin/bash

# When Ctrl+C is pressed, the whole program will exit
# See https://stackoverflow.com/a/32146079 for more info
trap "exit" INT

# Source common functions
source ./functions.sh

ftpServer=""
ftpUsername=""
ftpPassword=""
# Upload options for FTP
ftpUploadOptions=()
# If a command exits with a non-zero status code, exit this program immediately
# See `set --help` for more info
# set -e

# Function for setting the configuration of FTP
ftpConfigDialog() {
  whiptail --yesno "Would you like to upload the builds via FTP?" 0 0
  if [[ $? -eq 0 ]]; then
    if [[ "$FTP_UPLOAD_OPTIONS" ]]; then
      ftpUploadOptions=($FTP_UPLOAD_OPTIONS)
    elif [[ "$FTP_UPLOAD_OPTS" ]]; then
      ftpUploadOptions=($FTP_UPLOAD_OPTS)
    else
      ftpUploadOptions=($(whiptail --checklist "Choose the types of files to upload:" 0 0 0 \
      "ROM" "The resultant of the building process" ON \
      "ROM_OTA" "The OTA (over-the-air) build" ON \
      "ROM_IMAGE" "Images (all files that have an img extension)" OFF \
      3>&1 1>&2 2>&3))
    fi
    if [[ "$FTP_SERVER" ]]; then
      ftpServer="$FTP_SERVER"
    else
      ftpServer=$(whiptail --inputbox "Enter the FTP server:" 0 0 "uploads.androidfilehost.com" 3>&1 1>&2 2>&3)
    fi
    if [[ "$FTP_USERNAME" ]]; then
      ftpUsername="$FTP_USERNAME"
    else
      ftpUsername=$(whiptail --inputbox "Enter your username for the FTP server:" 0 0 3>&1 1>&2 2>&3)
    fi
    if [[ "$FTP_PASSWORD" ]]; then
      ftpPassword="$FTP_PASSWORD"
    else
      ftpPassword=$(whiptail --passwordbox "Enter your password for the FTP server:" 0 0 3>&1 1>&2 2>&3)
    fi
  else
    doneExec
  fi
}

# Function for showing an input dialog on what device codenames to build
buildDialog() {
  devices=$(whiptail --inputbox "Enter a list of device codenames. Separate each device codename by a space." 0 0 3>&1 1>&2 2>&3)
  build $devices
  ftpConfigDialog
  outdirsLength="${#outdirs[@]}"
  for (( i=0; i<${outdirsLength}+1; i++ ));
  do
    echo "Device ${devices[i]} built at ${outdirs[i]}."
    if [[ -n $ftpServer ]] && [[ -n $ftpUsername ]] && [[ -n $ftpPassword ]]; then
      for optionsI in "${ftpUploadOptions[@]}";
      do
        if [[ optionsI == "ROM" ]]; then
          rom=$(ls -tr ${outdirs[i]/lineage-*.zip} | tail -1)
          ftpLocation=$(whiptail --inputbox "Enter the folder path of where the build for device ${devices[i]} will be uploaded to." 0 0 3>&1 1>&2 2>&3)
          ftpUpload $ftpServer $rom $ftpLocation $ftpUsername $ftpPassword
        elif [[ optionsI == "ROM_OTA" ]]; then
          romOTA=$(ls -tr ${outdirs[i]/lineage_*-ota-*.zip} | tail -1)
          ftpLocation=$(whiptail --inputbox "Enter the folder path of where the OTAs for device ${devices[i]} will be uploaded to." 0 0 3>&1 1>&2 2>&3)
          ftpUpload $ftpServer romOTA $ftpLocation $ftpUsername $ftpPassword
        elif [[ optionsI == "ROM_IMAGE" ]]; then
          romImage=($(ls ${outdirs[i]/*.img}))
          ftpLocation=$(whiptail --inputbox "Enter the folder path of where the images for device ${devices[i]} will be uploaded to." 0 0 3>&1 1>&2 2>&3)
          for imageI in "${romImage[@]}";
          do
            ftpUpload $ftpServer $imageI $ftpLocation $ftpUsername $ftpPassword
          done
        fi
      done
    fi
  done
}

# Function for showing a confirmation dialog when a command has finished executing
doneExec() {
  whiptail --yesno "Go back to main menu?" 0 0
  if [[ $? -eq 0 ]]; then
    mainMenu
  else
    infoBold "Exiting..."
    exit 0
  fi
}

# Function for showing a confirmation dialog on whether to exit the program
confirmExit() {
  whiptail --yesno "Are you sure you want to exit?" 0 0
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
  elif [[ "$menuResult" = "Upload" ]]; then
    whiptail --title "Notice" --msgbox "The upload section is coming soon! Stay tuned." 0 0
  elif [[ "$menuResult" = "Help" ]]; then
    whiptail --title "Notice" --msgbox "The help guide is coming soon! Stay tuned." 0 0
    mainMenu
  fi
}

# Function for showing a menu when the program has been executed
mainMenu() {
  choices=("Exit" "Quit the script." "Sync" "Sync the Android Source." "Build" "Build for a device(s)." "Help" "Show help.")
  results=$(whiptail --title "Utilities" --menu "Choose one of the options below:" 0 0 0  "${choices[@]}" 3>&1 1>&2 2>&3)
  mainMenuHandler "$results"
}

mainMenu
