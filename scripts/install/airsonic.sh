if [[ -f /tmp/.install.lock ]]; then
    OUTTO="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
    OUTTO="/srv/panel/db/output.log"
else
    OUTTO="/dev/null"
fi

ip=$(curl -s http://whatismyip.akamai.com)
distribution=$(lsb_release -is)
version=$(lsb_release -cs)
username=$(cat /root/.master.info | cut -d: -f1)
airsonicver=$(wget -q https://github.com/airsonic/airsonic/releases -O - | grep -E \/tag\/ | awk -F "[><]" '{print $3}' | awk 'NR==1{print $2}')

function _installAirsonicIntro() {
    echo "Airsonic will now be installed." >>"${OUTTO}" 2>&1
    echo "This process may take up to 2 minutes." >>"${OUTTO}" 2>&1
    echo "Please wait until install is completed." >>"${OUTTO}" 2>&1
    # output to box
    echo "Airsonic will now be installed."
    echo "This process may take up to 2 minutes."
    echo "Please wait until install is completed."
    echo
    sleep 5
}

function _installJava() {
    if ! type -p java; then
        if [[ $distribution == "jessie" ]]; then
            echo "deb http://ftp.fr.debian.org/debian/ jessie-backports main contrib" >>/etc/apt/source.list
            apt update
            apt-get install -t jessie-backports openjdk-8-jre
        else
            apt install openjdk-8-jre
        fi
        openjdk8_install_path=$(dpkg --listfiles openjdk-8-jre | grep jre/bin$)
        update-alternatives --set java $openjdk8_install_path/java
    fi
}

function _installTomcat() {
    groupadd tomcat
    useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
    cd /tmp
    tomcat8ver=$(wget -q https://tomcat.apache.org/download-80.cgi -O - | grep h3 | sed -n 's/.*id="\([^"]*\).*/\1/p' | tail -1)
    wget http://mirrors.estointernet.in/apache/tomcat/tomcat-8/v$tomcat8ver/bin/apache-tomcat-$tomcat8ver.tar.gz
    mkdir /opt/tomcat
    tar xzf apache-tomcat-8*tar.gz -C /opt/tomcat --strip-components=1
    cd /opt/tomcat
    chgrp -R tomcat /opt/tomcat
    chmod -R g+r conf
    chmod g+x conf
    chown -R tomcat webapps/ work/ temp/ logs/

    if [[ ! -f /etc/default/tomcat8 ]]; then
        touch /etc/default/tomcat8
    else
        sed -i '/JAVA_HOME/d' /etc/default/tomcat8
    fi
    echo "JAVA_HOME=${openjdk8_install_path%"/bin"}" >>/etc/default/tomcat8

    cat >/etc/systemd/system/tomcat.service <<TOMCAT
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
TOMCAT

    sed "[Service]/a Environment=JAVA_HOME=${openjdk8_install_path%"/bin"}" /etc/systemd/system/tomcat.service

    systemctl daemon-reload
    systemctl start tomcat.service
    ufw allow 8080
    systemctl enable tomcat.service >/dev/null 2>&1

}

function _installAirsonicDependencies() {
    _installJava
    _installTomcat
}

function _installAirsonicCode() {
    if [[ ! -d /opt ]]; then mkdir /opt; fi
    cd /opt
    wget https://github.com/airsonic/airsonic/releases/download/$airsonicver/airsonic.war
    touch /install/.airsonic.lock
}

function _installAirsonicConfigure() {
    echo "Setiing up nginx reverse proxy"
    cat >/etc/systemd/system/airsonic.service <<AIRSONIC
[Unit]
Description=Airsonic Daemon
After=syslog.target network.target

[Service]
User=${username}
Group=${username}
Type=simple
ExecStart=/opt/airsoic.war
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
AIRSONIC
    mkdir -p /home/${username}/.config
    chown -R ${username}:${username} /home/${username}/.config
    chmod 775 /home/${username}/.config
    chown -R ${username}:${username} /opt/airsonic/
    systemctl daemon-reload
    systemctl enable airsonic.service >/dev/null 2>&1
    systemctl start airsonic.service

    if [[ -f /install/.nginx.lock ]]; then
        sleep 10
        bash /usr/local/bin/swizzin/nginx/airsonic.sh
        service nginx reload
    fi
}

function _installAirsonicFinish() {
    # output to box
    echo "Airsonic Install Complete!"
    echo "You can access it at  : http://$ip/airsonic"
    echo
    echo "Close this dialog box to refresh your browser"
}

function _installAirsonicExit() {
    exit 0
}

_installAirsonicIntro
echo "Installing dependencies ... " >>"${OUTTO}" 2>&1
_installAirsonicDependencies
echo "Installing Airsonic ... " >>"${OUTTO}" 2>&1
_installAirsonicCode
echo "Configuring Airsonic ... " >>"${OUTTO}" 2>&1
_installAirsonicConfigure
echo "Starting Airsonic ... " >>"${OUTTO}" 2>&1
_installAirsonicFinish
_installAirsonicExit
