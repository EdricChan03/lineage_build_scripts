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

# Whether to show the file path
showFilePath=true

# Whether to show debug messages
showDebug=false

if [[ "$SHOW_FILE_PATH" ]]; then
  showFilePath="$SHOW_FILE_PATH"
elif [[ "$SHOW_FILEPATH" ]]; then
  showFilePath="$SHOW_FILEPATH"
fi

if [[ "$DEBUG_MODE" ]]; then
  showDebug="$DEBUG_MODE"
elif [[ "$SHOW_DEBUG" ]]; then
  showDebug="$SHOW_DEBUG"
elif [[ "$SHOW_DEBUG_MSGS" ]]; then
  showDebug="$SHOW_DEBUG_MSGS"
fi
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
      "ROM_MD5SUM" "The verification files for the build" ON \
      "ROM_OTA" "The OTA (over-the-air) build" ON \
      "ROM_IMAGE" "Images (all files that have an img extension)" OFF \
      3>&1 1>&2 2>&3))
    fi
    if [[ "$FTP_SERVER" ]]; then
      ftpServer="$FTP_SERVER"
    else
      ftpServer=$(whiptail --inputbox "Enter the FTP server:" 0 0 "ftp://uploads.androidfilehost.com" 3>&1 1>&2 2>&3)
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
  devices=$(whiptail --inputbox "Enter a list of device codenames.\nSeparate each device codename by a space." 0 0 3>&1 1>&2 2>&3)
  # Check if user pressed the Okay button
  if [[ $? -eq 0 ]] && [[ "$devices" ]]; then
    build $devices
    ftpConfigDialog
    outdirsLength="${#outdirs[@]}"
    for (( i=1; i<${outdirsLength}+1; i++ ));
    do
      # infoBold "Device ${devices[$i-1]} built at ${outdirs[$i-1]}."
      if [[ "$ftpServer" ]] && [[ "$ftpUsername" ]] && [[ "$ftpPassword" ]] && [[ "$ftpUploadOptions" ]]; then
        # echo "${ftpUploadOptions[@]}"
        for optionsI in "${ftpUploadOptions[@]}";
        do
          # Removes the quotation marks from the variable
          optionsI="${optionsI%\"}"
          optionsI="${optionsI#\"}"
          if [[ "$optionsI" = "ROM" ]]; then
            rom=$(ls -tr ${outdirs[$i-1]}/lineage-*.zip | tail -1)
            ftpLocation=$(whiptail --inputbox "Enter the folder path of where the build for device ${devices[$i-1]} will be uploaded to." 0 0 3>&1 1>&2 2>&3)
            if [[ "$showFilePath" = true ]]; then
              infoBold "Uploading $(basename $rom) ($rom)..."
            else
              infoBold "Uploading $(basename $rom)..."
            fi
            ftpUpload "$ftpServer" $rom "$ftpLocation" "$ftpUsername" "$ftpPassword"
            if [[ $? -eq 0 ]]; then
              # Don't show dialogs for now as this can be quite repetitive to keep showing alerts
              # just to show that a file has been uploaded.
              # whiptail --msgbox "Successfully uploaded $rom to \n$ftpServer/$ftpLocation!" 0 0
              successBold "Successfully uploaded $rom to \n$ftpServer/$ftpLocation!"
            else
              whiptail --msgbox "An error occured while uploading. Error code: $?\nSee https://ec.haxx.se/usingcurl-returns.html#available-exit-codes for more info" 0 0
            fi
          elif [[ "$optionsI" = "ROM_MD5SUM" ]]; then
            infoBold "Uploading md5sum file..."
            romMD5SUM=$(ls -tr ${outdirs[$i-1]}/lineage-*.zip.md5sum | tail -1)
            ftpLocation=$(whiptail --inputbox "Enter the folder path of where the md5sum for device ${devices[$i-1]} will be uploaded to." 0 0 3>&1 1>&2 2>&3)
            ftpUpload "$ftpServer" $romMD5SUM "$ftpLocation" "$ftpUsername" "$ftpPassword"
            if [[ $? -eq 0 ]]; then
              # Don't show dialogs for now as this can be quite repetitive to keep showing alerts
              # just to show that a file has been uploaded.
              # whiptail --msgbox "Successfully uploaded $rom to \n$ftpServer/$ftpLocation!" 0 0
              successBold "Successfully uploaded $romMD5SUM to \n$ftpServer/$ftpLocation!"
            else
              whiptail --msgbox "An error occured while uploading. Error code: $?\nSee https://ec.haxx.se/usingcurl-returns.html#available-exit-codes for more info" 0 0
            fi
          elif [[ "$optionsI" = "ROM_OTA" ]]; then
            romOTA=$(ls -tr ${outdirs[$i-1]}/lineage_*-ota-*.zip | tail -1)
            ftpLocation=$(whiptail --inputbox "Enter the folder path of where the OTAs for device ${devices[$i-1]} will be uploaded to." 0 0 3>&1 1>&2 2>&3)
            if [[ "$showFilePath" = true ]]; 
              infoBold "Uploading $(basename $romOTA) ($romOTA)..."
            else
              infoBold "Uploading $(basename $romOTA)..."
            fi
            ftpUpload "$ftpServer" $romOTA "$ftpLocation" "$ftpUsername" "$ftpPassword"
            if [[ $? -eq 0 ]]; then
              # Don't show dialogs for now as this can be quite repetitive to keep showing alerts
              # just to show that a file has been uploaded.
              # whiptail --msgbox "Successfully uploaded $romOTA to \n$ftpServer/$ftpLocation!" 0 0
              successBold "Successfully uploaded $romOTA to \n$ftpServer/$ftpLocation!"
            else
              whiptail --msgbox "An error occured while uploading. Error code: $?\nSee https://ec.haxx.se/usingcurl-returns.html#available-exit-codes for more info"
            fi
          elif [[ "$optionsI" = "ROM_IMAGE" ]]; then
            infoBold "Uploading images..."
            romImage=($(ls ${outdirs[$i-1]}/*.img))
            ftpLocation=$(whiptail --inputbox "Enter the folder path of where the images for device ${devices[$i-1]} will be uploaded to." 0 0 3>&1 1>&2 2>&3)
            for imageI in "${romImage[@]}";
            do
              if [[ "$showFilePath" = true ]]; then
                infoBold "Uploading $(basename $imageI) ($imageI)..."
              else
                infoBold "Uploading $(basename $imageI)..."
              fi
              ftpUpload "$ftpServer" $imageI "$ftpLocation" "$ftpUsername" "$ftpPassword"
              if [[ $? -eq 0 ]]; then
                # Don't show dialogs for now as this can be quite repetitive to keep showing alerts
                # just to show that a file has been uploaded.
                # whiptail --msgbox "Successfully uploaded $imageI to \n$ftpServer/$ftpLocation!" 0 0
                successBold "Successfully uploaded $imageI to \n$ftpServer/$ftpLocation!"
              else
                whiptail --msgbox "An error occured while uploading. Error code: $?\nSee https://ec.haxx.se/usingcurl-returns.html#available-exit-codes for more info" 0 0
              fi
            done
          fi
        done
      fi
    done
  else
    # User didn't input anything or pressed the escape key (which exits with status code 255)
    # Head back to the main menu
    mainMenu
  fi
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
  if [[ $? -eq 0 ]]; then
    mainMenuHandler "$results"
  else
    # User pressed escape or on the Cancel button
    # Exit the menu in this case
    exit 0
  fi
}

mainMenu
