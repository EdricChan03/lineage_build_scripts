#!/bin/bash

# Enable colour
CLICOLOR=1

devices=()
outdirs=()

# Logs a statement with a red colour and exits the Terminal
# @param $1 The statement to log
error() {
  # Check if argument is non-empty
  if [[ -n $1 ]]; then
    echo -e "\e[31mERROR: $1\e[0m"
  else
    error "Please specify an argument. Exiting..."
  fi
  exit 1
}

# Logs a statement with a red colour (bolded) and exits the Terminal
# @param $1 The statement to log
errorBold() {
  # Check if argument is non-empty
  if [[ -n $1 ]]; then
    echo -e "\e[31m\e[1mERROR: $1\e[0m"
  else
    error "Please specify an argument. Exiting..."
  fi
}

# Logs a statement with a cyan colour
# @param $1 The statement to log
info() {
  # Check if argument is non-empty
  if [[ -n $1 ]]; then
    echo -e "\e[36mINFO: $1\e[0m"
  else
    error "Please specify an argument. Exiting..."
  fi
}

# Logs a statement with a cyan colour and bolded
# @param $1 The statement to log
infoBold() {
  # Check if argument is non-empty
  if [[ -n $1 ]]; then
    echo -e "\e[36m\e[1mINFO: $1\e[0m"
  else
    error "Please specify an argument. Exiting..."
  fi
}

# Logs a statement with a green colour
# @param $1 The statement to log
success() {
  # Check if argument is non-empty
  if [[ -n $1 ]]; then
    echo -e "\e[32mINFO: $1\e[0m"
  else
    error "Please specify an argument. Exiting..."
  fi
}

# Logs a statement with a green colour and bolded
# @param $1 The statement to log
successBold() {
  # Check if argument is non-empty
  if [[ -n $1 ]]; then
    echo -e "\e[32m\e[1mINFO: $1\e[0m"
  else
    error "Please specify an argument. Exiting..."
  fi
}

# Logs a statement with a yellow colour
# @param $1 The statement to log
warn() {
  # Check if argument is non-empty
  if [[ -n $1 ]]; then
    echo -e "\e[33mWARN: $1\e[0m"
  else
    error "Please specify an argument. Exiting..."
  fi
}

# Logs a statement with a yellow colour and bolded
# @param $1 The statement to log
warnBold() {
  if [[ -n $1 ]]; then
    echo -e "\e[33m\e[1mWARN: $1\e[0m"
  else
    error "Please specify an argument. Exiting..."
  fi
}

# Uploads a file to the FTP server
# @param $1 The FTP server URL. (Example: uploads.androidfilehost.com)
# @param $2 The file to upload. (A relative or absolute path to the file)
# @param $3 The folder to upload the file to.
# @param $4 The username
# @param $5 The password
# @note If parmaeters 4 and 5 are not specified, the function will use the variables
#       $FTP_USENAME for the username and $FTP_PASSWORD for the password
ftpUpload() {
  if [ $# -ne 5 ]; then
    errorBold "Please enter exactly 5 parameters"
  else
    ftpServer="${1:-uploads.androidfilehost.com}"
    fileToUpload="$2"
    ftpUploadFolder="$3"
    ftpUsername="${4:-$FTP_USERNAME}"
    ftpPassword="${5:-$FTP_PASSWORD}"
    curl $ftpServer/$ftpUploadFolder/ --user $ftpUsername:$ftpPassword
    infoBold "Uploading..."
    curl -T $fileToUpload $ftpServer/$ftpUploadFolder/ --user $ftpUsername:$ftpPassword
    if [ $? -eq 0 ]; then
      # File was successfully uploaded
      successBold "Successfully uploaded build to $ftpServer!"
    else
      errorBold "An error occured while attempting to upload to $ftpServer. Error code: $?"
    fi
  fi
}

# Checks if a function specified currently exists
# @param $1 The function to check
# @return 1 if the function exists, 0 if it doesn't
checkFunction() {
  if [[ -n "$(type -t $1)" ]]; then
    return 1
  else
    return 0
  fi
}

# Function to sync
sync() {
  infoBold "Syncing the latest changes..."
  if [[ ! $(checkFunction repo) ]]; then
    repo sync --force-sync --no-clone-bundle
  else
    errorBold "The repo command doesn't exist. Exiting..."
  fi
}

# Changes directory to the AOSP build directory if the function can find one
# Otherwise, bail
candroid() {
  if [[ -d "$HOME/android/lineage" ]]; then
    if [[ ! -d "$HOME/android/lineage/.repo" ]]; then
      warnBold "The current AOSP build directory either:\n1. doesn't have repo initialised yet,\n2. or is not a valid AOSP build directory."
    else
      infoBold "Changing working directory to the AOSP build directory..."
      cd $HOME/android/lineage
    fi
  elif [[ -d "$HOME/android" ]]; then
    if [[ ! -d "$HOME/android/.repo" ]]; then
      warnBold "The current AOSP build directory either:\n1. doesn't have repo initialised yet,\n2. or is not a valid AOSP build directory."
    else
      cd $HOME/android
      echo $(pwd)
    fi
  fi
}

# Sources AOSP's build tools
sourceAOSP() {
  echo $(pwd)
  source build/envsetup.sh
  successBold "Done sourcing!"
}

# Builds for devices specified in the devices array
buildDevices() {
  sourceAOSP
  if [[ ${#devices[@]} -ne 0 ]]; then
    # Check if functions breakfast and brunch from the LineageOS build tools exists
    if [[ ! $(checkFunction breakfast) ]] && [[ ! $(checkFunction brunch) ]]; then
      for i in "${devices[@]}";
        do
          infoBold "Building for $i..."
          breakfast "$i"
          brunch "$i"
          # This line gets the latest LineageOS build available in the out directory.
          result=$(ls -tr $OUT/lineage-*.zip | tail -1)
          outdirs+=(result)
      done
    else
      errorBold "The functions breakfast and/or brunch do not exist. Have you sourced the AOSP and LineageOS build tools?"
    fi
  else
    errorBold "There are no devices currently in the build queue. Exiting..."
  fi
}
# Builds an array of device codenames, or just one using breakfast and brunch.
build() {
  devices=("$@")
  buildDevices
  # Code adapted from https://stackoverflow.com/a/27254437
  # if [[ "$(declare -p $1)" =~ "declare -a" ]]; then
  #   echo array
  # else
  #   echo no array
  # fi
}
