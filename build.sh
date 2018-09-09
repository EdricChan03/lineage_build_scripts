#!/bin/bash

# TODOS:
# 1. Use a consistent way of declaring variables.
#    For example, consider using an environment variable instead
#    of having to declare an extra variable for that environment
#    variable.
# 2. Add options for supplying flags to a command.
# 3. Add more menu items.

# When Ctrl+C is pressed, the whole program will exit
# See https://stackoverflow.com/a/32146079 for more info
trap "exit" INT

# Source common functions
source ./functions.sh

# The version of the script
scriptVersion="1.0.3"

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

# Function for showing a dialog for phone options
phoneOptsDialog() {
  choices=("Flash latest build" "Flashes the latest LineageOS build to your phone" \
  "Logcat" "Gets the logcat of your device" \
  "Location of adb" "Outputs where ADB is installed on your computer" \
  "Exit and return" "Exits this dialog and returns to the main menu." \
  "Quit" "Quits the script.")
  results=$(whiptail --title "Phone options" --menu "Choose one of the options below:" 0 0 0 "${choices[@]}" 3>&1 1>&2 2>&3)
  if [[ $? -eq 0 ]]; then
    if [[ "$results" = "Exit and return" ]]; then
      mainMenu
    elif [[ "$results" = "Quit" ]]; then
      exit 0
    elif [[ "$results" = "Location of adb" ]]; then
      # Check if the adb command actually exists
      if command -v adb 2>/dev/null; then
        whiptail --msgbox "Location of adb: $(which adb)" 0 0
      else
        whiptail --msgbox "adb either doesn't exist or isn't installed!" 0 0
      fi
      phoneOptsDialog
    elif [[ "$results" = "Logcat" ]]; then
      logcatOutput=$(whiptail --inputbox "Specify the location that you would like to save the logcat to:\n(Leave blank to output to the console)" 0 0 3>&1 1>&2 2>&3)
      if command -v adb 2>/dev/null; then
        # Code adapted from https://github.com/LineageOS/android_vendor_lineage/blob/a03c0edd0c118fff893ca41ad944d4bbba27aa15/build/envsetup.sh#L110-L118
        adb start-server # Prevent unexpected starting server message from adb get-state in the next line
        if [ $(adb get-state) != device -a $(adb shell 'test -e /sbin/recovery 2> /dev/null; echo $?') != 0 ]; then
          infoBold "No device is online. Waiting for one..."
          infoBold "Please connect USB and/or enable USB debugging"
          until [ $(adb get-state) = device -o $(adb shell 'test -e /sbin/recovery 2> /dev/null; echo $?') = 0 ]; do
            sleep 1
          done
          successBold "Device found!"
        fi
        if [[ -n "$logcatOutput" ]]; then
          logcatOutput="${logcatOutput/#\~/$HOME}"
          adb logcat > $logcatOutput
        else
          whiptail --msgbox "TIP: Press Ctrl+C to terminate the logcat!" 0 0
          adb logcat
        fi
      else
        whiptail --msgbox "adb either doesn't exist or isn't installed!" 0 0
      fi
    elif [[ "$results" = "Flash latest build" ]]; then
      OUT=$(whiptail --inputbox "Specify the out directory of the LineageOS build:" 0 0 3>&1 1>&2 2>&3)
      OUT="${OUT/#\~/$HOME}"
      if [[ "$OUT" ]]; then
        candroid
        sourceAOSP
        # A little known fact:
        # I found this not very well documented command that automatically
        # flashes the latest LineageOS build to your phone connected via
        # ADB.
        # See this code: https://github.com/LineageOS/android_vendor_lineage/blob/a03c0edd0c118fff893ca41ad944d4bbba27aa15/build/envsetup.sh#L102-L142
        # P.S. For some reason, all of the AOSP functions are food-themed
        if [[ ! $(checkFunction eat) ]]; then
          eat
        else
          errorBold "The eat command doesn't exist. Aborting.."
          exit 1
        fi
      else
        phoneOptsDialog
      fi
    fi
  else
    # User has either pressed the escape key or has clicked on cancel
    doneExec
  fi
}
# Function for saving storage
manageStorageDialog() {
  choices=("Clear previous builds" "Clears all previous builds" \
  "Clear previous target files" "Clear previous target files used for OTA packages."\
  "Exit and return" "Exits this dialog and returns to the main menu." \
  "Quit" "Quits the script.")
  results=$(whiptail --title "Manage storage" --menu "Choose one of the options below:" 0 0 0 "${choices[@]}" 3>&1 1>&2 2>&3)
  if [[ $? -eq 0 ]]; then
    if [[ "$results" = "Exit and return" ]]; then
      mainMenu
    elif [[ "$results" = "Quit" ]]; then
      exit 0
    else
      outDirectory=$(whiptail --inputbox "Enter the out directory:" 0 0 3>&1 1>&2 2>&3)
      if [[ "$results" = "Clear previous builds" ]]; then
        clearPrevBuilds $outDirectory
        if [[ $? -eq 0 ]]; then
          whiptail --yesno "Done clearing! Return back to the dialog?" 0 0
          if [[ $? -eq 0 ]]; then
            manageStorageDialog
          else
            exit 0
          fi
        else
          whiptail --msgbox "An error occured while clearing. See the log for more info."
          exit 1
        fi
      elif [[ "$results" = "Clear previous target files" ]]; then
        clearPrevTargetFiles $outDirectory
        if [[ $? -eq 0 ]]; then
          whiptail --yesno "Done clearing! Return back to the dialog?" 0 0
          if [[ $? -eq 0 ]]; then
            manageStorageDialog
          else
            exit 0
          fi
        else
          whiptail --msgbox "An error occured while clearing. See the log for more info."
          exit 1
        fi
      fi
    fi
  else
    # User pressed escape or on the Cancel button
    # Exit the menu in this case
    doneExec
  fi
}
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
              infoBold "Uploading $(basename $rom) ($rom) to $ftpLocation..."
            else
              infoBold "Uploading $(basename $rom) to $ftpLocation..."
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
            romMD5SUM=$(ls -tr ${outdirs[$i-1]}/lineage-*.zip.md5sum | tail -1)
            ftpLocation=$(whiptail --inputbox "Enter the folder path of where the md5sum for device ${devices[$i-1]} will be uploaded to." 0 0 3>&1 1>&2 2>&3)
            if [[ "$showFilePath" = true ]]; then
              infoBold "Uploading $(basename $romMD5SUM) ($romMD5SUM) to $ftpLocation..."
            else
              infoBold "Uploading $(basename $romMD5SUM) to $ftpLocation..."
            fi
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
            if [[ "$showFilePath" = true ]]; then
              infoBold "Uploading $(basename $romOTA) ($romOTA) to $ftpLocation..."
            else
              infoBold "Uploading $(basename $romOTA) to $ftpLocation..."
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
                infoBold "Uploading $(basename $imageI) ($imageI) to $ftpLocation..."
              else
                infoBold "Uploading $(basename $imageI) to $ftpLocation..."
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
  elif [[ "$menuResult" = "Manage storage" ]]; then
    manageStorageDialog
  elif [[ "$menuResult" = "Phone options" ]]; then
    phoneOptsDialog
  elif [[ "$menuResult" = "About" ]]; then
    whiptail --title "About" --msgbox "build.sh: Version $scriptVersion" 0 0
    mainMenu
  fi
}

# Function for showing a menu when the program has been executed
mainMenu() {
  choices=("Exit" "Quit the script." \
  "Sync" "Sync the Android Source." \
  "Build" "Build for a device(s)." \
  "Phone options" "Options for your phone (plugged in via ADB)" \
  "Manage storage" "Manage your computer's storage." \
  "About" "Show information about this script.")
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
