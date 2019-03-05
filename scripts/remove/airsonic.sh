systemctl stop airsonic
systemctl disable airsonic
rm -rf /etc/systemd/system/airsonic.service
rm -rf /opt/airsonic
rm -rf /etc/nginx/apps/airsonic.conf
rm -rf /install/.airsonic.lock
echo "Airsonic uninstalled!"
