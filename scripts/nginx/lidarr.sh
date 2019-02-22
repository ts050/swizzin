
MASTER=$(cat /root/.master.info | cut -d: -f1)
isactive=$(systemctl is-active lidarr)

if [[ $isactive == "active" ]]; then
  systemctl stop lidarr
fi
if [[ ! -f /etc/nginx/apps/lidarr.conf ]]; then
  cat > /etc/nginx/apps/lidarr.conf <<LIDARR
location /lidarr {
  proxy_pass        http://127.0.0.1:8686/lidarr;
  proxy_set_header Host \$proxy_host;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_redirect off;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
LIDARR

fi
if [[ ! -d /home/${MASTER}/.config/Lidarr/ ]]; then mkdir -p /home/${MASTER}/.config/Lidarr/; fi
cat > /home/${MASTER}/.config/Lidarr/config.xml <<LIDARR
<Config>
  <Port>8686</Port>
  <UrlBase>lidarr</UrlBase>
  <BindAddress>127.0.0.1</BindAddress>
  <SslPort>9898</SslPort>
  <EnableSsl>False</EnableSsl>
  <LogLevel>Info</LogLevel>
  <Branch>master</Branch>
  <LaunchBrowser>False</LaunchBrowser>
  <UpdateMechanism>BuiltIn</UpdateMechanism>
  <AnalyticsEnabled>False</AnalyticsEnabled>
</Config>
LIDARR
chown -R ${MASTER}: /home/${MASTER}/.config/Lidarr
if [[ $isactive == "active" ]]; then
  systemctl start lidarr
fi
