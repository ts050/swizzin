
MASTER=$(cat /root/.master.info | cut -d: -f1)
isactive=$(systemctl is-active airsonic)

if [[ $isactive == "active" ]]; then
  systemctl stop airsonic
fi
if [[ ! -f /etc/nginx/apps/airsonic.conf ]]; then
  cat > /etc/nginx/apps/airsonic.conf <<airsonic
location /airsonic {
  proxy_pass        http://127.0.0.1:8686/airsonic;
  proxy_set_header Host \$proxy_host;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_redirect off;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
airsonic

fi
if [[ ! -d /home/${MASTER}/.config/airsonic/ ]]; then mkdir -p /home/${MASTER}/.config/airsonic/; fi
cat > /home/${MASTER}/.config/airsonic/config.xml <<AIRSONIC
<Config>
  <Port>8686</Port>
  <UrlBase>airsonic</UrlBase>
  <BindAddress>127.0.0.1</BindAddress>
  <SslPort>9898</SslPort>
  <EnableSsl>False</EnableSsl>
  <LogLevel>Info</LogLevel>
  <Branch>master</Branch>
  <LaunchBrowser>False</LaunchBrowser>
  <UpdateMechanism>BuiltIn</UpdateMechanism>
  <AnalyticsEnabled>False</AnalyticsEnabled>
</Config>
AIRSONIC
chown -R ${MASTER}: /home/${MASTER}/.config/airsonic
if [[ $isactive == "active" ]]; then
  systemctl start airsonic
fi
