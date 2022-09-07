#------------------------------------------------
#   INSTALACAO GLPI DEBIAN 11 BULLSEYE - PADRAO REMI (GLPI 9.4.6) CENTOS 7
#
#   DOWNLOAD: https://saimei.ftp.acc.umu.se/debian-cd/current/amd64/iso-cd/debian-11.0.0-amd64-netinst.iso
#------------------------------------------------
#
#  Desenvolvido por: Service TIC Solucoes Tecnologicas
#            E-mail: contato@servicetic.com.br
#              Site: www.servicetic.com.br
#          Linkedin: https://www.linkedin.com/company/serviceticst
#          Intagram: https://www.instagram.com/serviceticst
#          Facebook: https://www.facebook.com/serviceticst
#           Twitter: https://twitter.com/serviceticst
#           YouTube: https://youtube.com/c/serviceticst
#
#              Blog: https://servicetic.com.br/intalacao-automatizada-do-glpi-9-5-6-no-debian-11
#           YouTube: https://www.youtube.com/watch?v=UZ7ndo45gic&list=PLwXxs1htu2adKC2f9mH1mx0HZ0qKJgnqw
#-------------------------------------------------
#
clear
echo "#------------------------------------------#"
echo           "INSTALANDO DEPENDENCIAS" 
echo "#------------------------------------------#"
#
apt -y install apache2 php libapache2-mod-php php-soap php-cas php-apcu php-cli php-common php-curl php-gd php-imap php-ldap php-mysql php-snmp php-xmlrpc php-xml php-intl php-zip php-bz2 php-mbstring php-bcmath libarchive-tools
apt -y install bzip2 curl mycli wget ntp
#
clear
echo "#------------------------------------------#"
echo             "BAIXANDO GLPI 9.5.8" 
echo "#------------------------------------------#"
#
wget -4 https://github.com/glpi-project/glpi/releases/download/9.5.8/glpi-9.5.8.tgz
tar xvf  glpi-9.5.8.tgz -C /usr/share
chown  www-data. -Rf /usr/share/glpi/
#
clear
echo "#------------------------------------------#"
echo          "CRIANDO ARQUIVO DOWNSTREAM" 
echo "#------------------------------------------#"
#
mkdir /etc/glpi &&  cp -Rfp /usr/share/glpi/config/* /etc/glpi
mkdir /var/log/glpi
mkdir /var/lib/glpi && cp -Rfp /usr/share/glpi/files /var/lib/glpi
chown  www-data. -Rf /etc/glpi
chown  www-data. -Rf /var/lib/glpi/files && chmod 777 -Rf /var/lib/glpi/files/_log
chown  www-data. -Rf /var/log/glpi
touch /usr/share/glpi/inc/downstream.php
cat <<EOF | tee /usr/share/glpi/inc/downstream.php
<?php
/**
 * RPM default configuration
 *
 * Modifying this file in-place is not recommended, because
 * changes will be overwritten during package upgrades.
 *
 * If you want to customize the behaviour, the best way is to
 * create and use the /etc/glpi/local_define.php file.
 *
**/


// Config
define('GLPI_CONFIG_DIR',     (getenv('GLPI_CONFIG_DIR') ?: '/etc/glpi'));

if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
   require_once GLPI_CONFIG_DIR . '/local_define.php';
}

// Runtime Data
defined('GLPI_VAR_DIR')        or define('GLPI_VAR_DIR',        '/var/lib/glpi/files');

// Log
defined('GLPI_LOG_DIR')        or define('GLPI_LOG_DIR',        '/var/log/glpi');

// System libraries
define('GLPI_HTMLAWED',       '/usr/share/php/htmLawed/htmLawed.php');

// Fonts
define('GLPI_FONT_FREESANS',  '/usr/share/fonts/gnu-free/FreeSans.ttf');

// Use system cron
define('GLPI_SYSTEM_CRON', true);

// Packaging
define('GLPI_INSTALL_MODE', 'RPM');
EOF
#
clear
echo "#------------------------------------------#"
echo          "CRIANDO ARQUIVO APACHE-VHOST" 
echo "#------------------------------------------#"
#
touch /etc/apache2/conf-available/glpi.conf
cat <<EOF | tee /etc/apache2/conf-available/glpi.conf
Alias /glpi /usr/share/glpi

# Redirect configuration for multi-glpi installation
# You can set this value in each vhost configuration
#SetEnv GLPI_CONFIG_DIR /etc/glpi

<Directory /usr/share/glpi>
    Options None
    AllowOverride Limit Options FileInfo

    <IfModule mod_authz_core.c>
        Require all granted
    </IfModule>
    <IfModule !mod_authz_core.c>
        Order deny,allow
        Allow from all
    </IfModule>
</Directory>

<Directory /usr/share/glpi/install>

    # Install is only allowed via local access (from the GLPI server).
    # Add your IP address if you need it for remote installation,
    # but remember to remove it after installation for security.

    <IfModule mod_authz_core.c>
        # Apache 2.4
#        Require local
        # Require ip ##.##.##.##
    </IfModule>
    <IfModule !mod_authz_core.c>
        # Apache 2.2
        Order Deny,Allow
#        Deny from All
        Allow from 127.0.0.1
        Allow from ::1
    </IfModule>

    ErrorDocument 403 "<p><b>Restricted area.</b><br />Only local access allowed.<br />Check your configuration or contact your administrator.</p>"

    <IfModule mod_php5.c>
        # migration could be very long
        php_value max_execution_time 0
        php_value memory_limit -1
    </IfModule>
    <IfModule mod_php7.c>
        # migration could be very long
        php_value max_execution_time 0
        php_value memory_limit -1
    </IfModule>
</Directory>

<Directory /usr/share/glpi/config>
    Order Allow,Deny
    Deny from all
</Directory>

<Directory /usr/share/glpi/locales>
    Order Allow,Deny
    Deny from all
</Directory>

<Directory /usr/share/glpi/install/mysql>
    Order Allow,Deny
    Deny from all
</Directory>

<Directory /usr/share/glpi/scripts>
    Order Allow,Deny
    Deny from all
</Directory>

# some people prefer a simple URL like http://glpi.example.com

<VirtualHost *:80>

  DocumentRoot /usr/share/glpi
  ServerName glpi.dominio.com.br
  ServerAlias www.glpi.dominio.com.br
  ServerAdmin email@dominio.com.br

</VirtualHost>
EOF
a2enconf glpi.conf
systemctl reload apache2
#
clear
echo "#-----------------------------------------#"
echo            "AJUSTE PHP.INI"
echo "#-----------------------------------------#"
#
sed -i '964s/^/#/' /etc/php/7.4/apache2/php.ini
sed -i 965i'date.timezone = America/Sao_Paulo' /etc/php/7.4/apache2/php.ini
sed -i '846s/^/#/' /etc/php/7.4/apache2/php.ini
sed -i 847i'upload_max_filesize = 100M' /etc/php/7.4/apache2/php.ini
sed -i '409s/^/#/' /etc/php/7.4/apache2/php.ini
sed -i 410i'memory_limit = 512M' /etc/php/7.4/apache2/php.ini
systemctl restart apache2
systemctl enable apache2
#
echo "#-----------------------------------------#"
echo      "INSTALANDO E CONFIGURANDO O NTP"
echo "#-----------------------------------------#"
#
apt install -y ntp
sed -i '23,26s/^/#/' /etc/ntp.conf 
sed -i 27i'b.st1.ntp.br' /etc/ntp.conf
sed -i 28i'c.st1.ntp.br' /etc/ntp.conf
sed -i 29i'd.st1.ntp.br' /etc/ntp.conf
sed -i 30i'a.ntp.br' /etc/ntp.conf
sed -i 31i'b.ntp.br' /etc/ntp.conf
sed -i 32i'c.ntp.br' /etc/ntp.conf
sed -i 33i'gps.ntp.br' /etc/ntp.conf
systemctl restart ntp 
systemctl enable ntp
#
echo "#-----------------------------------------#"
echo        "INSTALANDO E FUSIOINVENTORY"
echo "#-----------------------------------------#"
#
apt -y install dmidecode hwdata ucf hdparm
apt -y install perl libuniversal-require-perl libwww-perl libparse-edid-perl
apt -y install libproc-daemon-perl libfile-which-perl libhttp-daemon-perl
apt -y install libxml-treepp-perl libyaml-perl libnet-cups-perl libnet-ip-perl
apt -y install libdigest-sha-perl libsocket-getaddrinfo-perl libtext-template-perl
apt -y install libxml-xpath-perl libyaml-tiny-perl
apt -y install libnet-snmp-perl libcrypt-des-perl libnet-nbname-perl
apt -y install libdigest-hmac-perl
apt -y install libfile-copy-recursive-perl libparallel-forkmanager-perl
apt -y install libwrite-net-perl
cd /tmp
wget https://github.com/fusioninventory/fusioninventory-agent/releases/download/2.5.2/fusioninventory-agent_2.5.2-1_all.deb
wget https://github.com/fusioninventory/fusioninventory-agent/releases/download/2.5.2/fusioninventory-agent-task-collect_2.5.2-1_all.deb
wget https://github.com/fusioninventory/fusioninventory-agent/releases/download/2.5.2/fusioninventory-agent-task-network_2.5.2-1_all.deb
wget https://github.com/fusioninventory/fusioninventory-agent/releases/download/2.5.2/fusioninventory-agent-task-deploy_2.5.2-1_all.deb
wget https://github.com/fusioninventory/fusioninventory-agent/releases/download/2.5.2/fusioninventory-agent-task-esx_2.5.2-1_all.deb
dpkg -i fusioninventory-agent_2.5.2-1_all.deb
dpkg -i fusioninventory-agent-task-collect_2.5.2-1_all.deb
dpkg -i fusioninventory-agent-task-network_2.5.2-1_all.deb
dpkg -i fusioninventory-agent-task-deploy_2.5.2-1_all.deb
dpkg -i fusioninventory-agent-task-esx_2.5.2-1_all.deb
systemctl restart fusioninventory-agent
systemctl reload fusioninventory-agent
pkill -USR1 -f -P 1 fusioninventory-agent
wget https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.5%2B3.0/fusioninventory-9.5+3.0.tar.bz2
bunzip2 fusioninventory-9.5+3.0.tar.bz2
tar -xvf  fusioninventory-9.5+3.0.tar -C /usr/share/glpi/plugins 
#
clear
echo "#-----------------------------------------#"
echo           "CRIANDO BASE DE TESTE"
echo "#-----------------------------------------#"
#
cp -Rfp /usr/share/glpi /usr/share/teste
cp -Rfp /etc/glpi /etc/teste
cp -Rfp /var/lib/glpi /var/lib/teste
cp -Rfp /var/log/glpi /var/log/teste
cp -Rfp /etc/apache2/conf-available/glpi.conf /etc/apache2/conf-available/teste.conf
rm -Rf /etc/teste/config_db.php
sed -i 's/glpi/teste/' /etc/apache2/conf-available/teste.conf
sed -i 's/glpi/teste/' /etc/apache2/conf-available/teste.conf
sed -i 's/glpi/teste/' /usr/share/teste/inc/downstream.php
a2enconf teste.conf
systemctl reload apache2
systemctl restart apache2
#
clear
echo "#-----------------------------------------#"
echo     "INSTALE O SGDB DA SUA PREFERENCIA"
echo "#-----------------------------------------#"
echo "ACESSE O GLPI PELO NAVEGADOR E CONCLUA A INSTALACAO"
echo "#-----------------------------------------#" 
echo "RODE O COMANDO ABAIXO APOS CONCLUIR A INSTALAÇÃO PELO NAVEGADOR"
echo "mv /usr/share/glpi/install/ /usr/share/glpi/install_old"
echo "mv /usr/share/teste/install/ /usr/share/teste/install_old"
echo "#-----------------------------------------#"
echo "DESCOMENTE A LINHA 33 E 39 DO ARQUIVO /etc/apache2/conf-available/glpi.conf E REINICIE O APACHE"
echo "DESCOMENTE A LINHA 33 E 39 DO ARQUIVO /etc/apache2/conf-available/teste.conf E REINICIE O APACHE"
echo "#-----------------------------------------#"
echo "ALTERE A SENHA E REMOVA OS 3 "USUARIOS" ABAIXO"
echo "normal"
echo "post-only"
echo "tech"
echo "#-----------------------------------------#"
echo                  "FIM"
echo "#-----------------------------------------#"



