# LineageOS Build Scripts

Build scripts for LineageOS.

## Prerequsites

> **NOTICE:** The build script requires commands that may not be available on other operating systems. This includes `whiptail`, which isn't installed on a Windows PC or macOS by default. Thus, it is advisble to use Ubuntu or any Linux OS which should have such commands installed.

---

## Getting started

1. Follow the official [LineageOS guides](https://wiki.lineageos.org/devices/) to setting up LineageOS locally.
2. Clone the source code for this repository on the parent directory of your LineageOS Source. (Should be `~/android`, where `~/android/lineage` is where the LineageOS Source is located at.)
3. Ensure that the permissions for the files `build.sh` and `functions.sh` are set to `755`. You can verify this by running `ls -l`.
4. Execute the script by typing `./build.sh` in your Terminal and pressing enter.

That's it!

---

## Variables

This script accepts the following environment variables:

### FTP

Environmental Variable | Description | Accepted values
---|---|---
`FTP_PASSWORD` | The password of your username of the FTP seerver that you're uploading to | A string
`FTP_SERVER` | The FTP server that you're uploading builds to. (Note: Please add a `ftp://` prefix to the variable if you're using FTP) | A string
`FTP_UPLOAD_OPTIONS` / `FTP_UPLOAD_OPTS` | The build types that you would like to upload. | See [`FTP_UPLOAD_OPTS` accepted values](#ftp_upload_opts-accepted-values)
`FTP_USERNAME` | The username of the FTP server that you're uploading the builds to. | A string

#### `FTP_UPLOAD_OPTS` accepted values

A string with spaces to indicates an option.

The accepted values are listed below:

- `ROM_MD5SUM`: `md5sum` file used for verification of the build
- `ROM`: The build `zip` file
- `ROM_OTA`: The OTA of the build
- `ROM_IMAGES`: All files with a `img` extension

---

### Other

Environmental Variable | Description | Accepted values
---|---|---
`SHOW_FILEPATH` / `SHOW_FILE_PATH` | Whether to show a file's path | `true` / `false`
`DEBUG_MODE` / `SHOW_DEBUG` / `SHOW_DEBUG_MSGS` | Whether to show debug messages | `true` / `false`
