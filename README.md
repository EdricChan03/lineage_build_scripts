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