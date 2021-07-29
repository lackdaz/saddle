# saddle

Import files into raspbian images

## Compatible platforms

1. Ubuntu 18.04, 20.04

## Checklist

1. Name a folder within your repo _-saddle or_\_saddle (.e.g. foo-saddle)

## Steps to setup

1. Create a files_to_add folder
1. git clone your 'saddle-like' repo into files_to_add
1. run saddle.sh

## Known Issues

1. If an issue occurs during the mount, the emulated parition will not unmount and cause issues for subsequent re-runs of saddle. Re-running the script will yield errors of something related to `/dev/loopsp2` (has not occurred recently so I cannot document the error exactly). The solution is to reboot instead of forcing an unmount. If someone faces this issue, please file an issue with the exact error logs.

Also do check out [raspberian-firstboot](https://github.com/nmcclain/raspberian-firstboot). It looks like we are doing a lot of things similar but they are doing it way better.
