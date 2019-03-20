
### Quick Start:

wget
```
bash <(wget -O- -q  https://raw.githubusercontent.com/ts050/swizzin/master/setup.sh)
```

curl
```
bash <(curl -s  https://raw.githubusercontent.com/ts050/swizzin/master/setup.sh)
```

Please note that if you are running Ubuntu and choose to run the initial setup though `sudo` you should include the `-H` argument to ensure that your home directory is modified to /root when you sudo up. The installer will take care of this for you, and this should be the only time you need to specify `sudo -H` before running a swizzin command.

Example:

```
sudo -H su -c 'bash <(wget -O- -q https://raw.githubusercontent.com/ts050/swizzin/master/setup.sh)'
```
#### Replace 'liaralabs' in the above urls with 'ts050' to have a go at the changes I made


#### Supported:
* Debian 8/9
* Ubuntu 16.04 and above

Changes in fork
#### 21/2/19 - Added scripts for integrating Lidarr - DONE
#### 4/3/19 - Added scripts for makemkv(needs testing)
#### 14/3/19 - Updated dashboard code to include lidarr and Tautulli
TODO 
* ~~Lidarr~~
* ~~Makemkv~~
* Makemkv - add cronjob to update scripts for license, Handle file permissions
* Airsonic
* Mylar
* Pydio
