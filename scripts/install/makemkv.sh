#!/bin/bash

if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  OUTTO="/srv/panel/db/output.log"
else
  OUTTO="/dev/null"
fi

function _updateMakemkvLicenseKey() {
  key=$(wget -q "https://www.makemkv.com/forum/viewtopic.php?f=5&t=1053" -O - | grep code | sed -n 's:.*<code>\(.*\)</code>.*:\1:p')
  if [[ ! -f ~/.MakeMKV/settings.conf ]]; then
    touch ~/.MakeMKV/settings.conf
  fi
  echo "app_Key = "$key"" >~/.MakeMKV/settings.conf
}

function _installMakemkvDependencies() {
  apt-get install build-essential pkg-config libc6-dev libssl-dev libexpat1-dev libavcodec-dev libgl1-mesa-dev
}

url=$(wget -q "https://www.makemkv.com/forum/viewtopic.php?f=3&t=224" -O - | grep -E "\/download\/" | sed -n 's/.*href="\([^"]*\).*/\1/p')

if [[ ! -d /opt ]]; then mkdir /opt; fi
cd /opt
wget $(echo $url | awk '{print $1}')
wget $(echo $url | awk '{print $2}')
find . -mindepth 1 -maxdepth 1 -name "make*.gz" -exec tar xzf {} \; 2>/dev/null
rm -f makemkv*.gz

_installMakemkvDependencies
# makemkv-oss install
cd makemkv-oss-*
./configure
make
sudo make install

# makemkv-bin install
cd ../makemkv-bin-*
# Skipping accept license step
sed -i 's/all: tmp\/eula_accepted/all:/g' Makefile
sudo make install
rm -rf makemkv-*
# TODO - Add option to build using ffmpeg
if [[ ! -f /install/.ffmpeg.lock ]]; then
  echo "ERROR: no ffmpeg installation. Please install ffmpeg if you want to configure your installation."
  exit 1
fi

_updateMakemkvLicenseKey

touch /install/.makemkv.lock
