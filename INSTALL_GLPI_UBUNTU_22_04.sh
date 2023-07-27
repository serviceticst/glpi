
#------------------------------------------------
#  INSTALACAO DO GLPI NA ULTIMA VERSAO ESTAVEL NO UBUNTU 22.04 JAMMY  (PADRAO REMI REDHAT)
#
#   DOWNLOAD: https://mirror.pop-sc.rnp.br/ubuntu-releases/22.04.2/ubuntu-22.04.2-live-server-amd64.iso
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
#           YouTube: 
#-------------------------------------------------
#
#
echo "#------------------------------------------#"
echo           "INSTALANDO APACHE" 
echo "#------------------------------------------#"
#
export DEBIAN_FRONTEND=noninteractive && apt -y install apache2 && a2enmod rewrite
#
clear
echo "#------------------------------------------#"
echo           "HABILITANDO PHP 8.0" 
echo "#------------------------------------------#"
#
apt install -y apt-transport-https lsb-release software-properties-common ca-certificates
echo | add-apt-repository ppa:ondrej/php
apt install php8.0 -y  
#
clear
echo "#------------------------------------------#"
echo           "INSTALANDO DEPENDENCIAS" 
echo "#------------------------------------------#"
#
apt -y install php8.0 php8.0-soap php8.0-apcu php8.0-cli php8.0-common php8.0-curl php8.0-gd php8.0-imap php8.0-ldap php8.0-mysql php8.0-snmp php8.0-xmlrpc php8.0-xml php8.0-intl php8.0-zip php8.0-bz2 php8.0-mbstring php8.0-bcmath 
apt -y install php8.0-fpm && systemctl enable php8.0-fpm
apt -y install bzip2 curl mycli wget ntp libarchive-tools
service apache2 restart
service php8.0-fpm restart
#
clear
echo "#------------------------------------------#"
echo  "BAIXANDO GLPI UTIMA VERSAO ESTAVEL DO GLPI" 
echo "#------------------------------------------#"
#
url=$(wget -qO- https://github.com/glpi-project/glpi/releases/latest | grep -o 'https://github.com/glpi-project/glpi/releases/download/[^"]*' | head -1)
file_name=$(basename "$url")
wget "$url"
tar xvf "$file_name" -C /usr/share
rm "$file_name"
#
clear
echo "#------------------------------------------#"
echo    "CRIANDO DIRETORIOS E DANDO PERMISSAO" 
echo "#------------------------------------------#"
#
mkdir /etc/glpi 
mkdir /var/log/glpi
mkdir /var/lib/glpi/
cp -Rfp /usr/share/glpi/files /var/lib/glpi
mkdir -p /var/lib/glpi/files/_documents 
chown www-data:www-data -Rf /etc/glpi
chown www-data:www-data -Rf /var/lib/glpi/files 
chown www-data:www-data -Rf /var/log/glpi
chown www-data:www-data -Rf /usr/share/glpi/marketplace
clear
echo "#------------------------------------------#"
echo        "CRIANDO ARQUIVO DOWNSTREAM" 
echo "#------------------------------------------#"
#
touch /usr/share/glpi/inc/downstream.php
cat <<EOF | tee /usr/share/glpi/inc/downstream.php
<?php

// config
defined('GLPI_CONFIG_DIR') or define('GLPI_CONFIG_DIR',     (getenv('GLPI_CONFIG_DIR') ?: '/etc/glpi'));

if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
   require_once GLPI_CONFIG_DIR . '/local_define.php';
}

// marketplace plugins
defined('GLPI_MARKETPLACE_ALLOW_OVERRIDE') or define('GLPI_MARKETPLACE_ALLOW_OVERRIDE', false);

// runtime data
defined('GLPI_VAR_DIR')         or define('GLPI_VAR_DIR',         '/var/lib/glpi/files');

define('GLPI_DOC_DIR',        GLPI_VAR_DIR . '/_documents');
define('GLPI_CRON_DIR',       GLPI_VAR_DIR . '/_cron');
define('GLPI_DUMP_DIR',       GLPI_VAR_DIR . '/_dumps');
define('GLPI_GRAPH_DIR',      GLPI_VAR_DIR . '/_graphs');
define('GLPI_LOCK_DIR',       GLPI_VAR_DIR . '/_lock');
define('GLPI_PICTURE_DIR',    GLPI_VAR_DIR . '/_pictures');
define('GLPI_PLUGIN_DOC_DIR', GLPI_VAR_DIR . '/_plugins');
define('GLPI_RSS_DIR',        GLPI_VAR_DIR . '/_rss');
define('GLPI_SESSION_DIR',    GLPI_VAR_DIR . '/_sessions');
define('GLPI_TMP_DIR',        GLPI_VAR_DIR . '/_tmp');
define('GLPI_UPLOAD_DIR',     GLPI_VAR_DIR . '/_uploads');
define('GLPI_CACHE_DIR',      GLPI_VAR_DIR . '/_cache');

// log
defined('GLPI_LOG_DIR')         or define('GLPI_LOG_DIR',         '/var/log/glpi');

// use system cron
define('GLPI_SYSTEM_CRON', true);
EOF
#
clear
echo "#------------------------------------------#"
echo        "CRIANDO ARQUIVO APACHE-VHOST" 
echo "#------------------------------------------#"
#
touch /etc/apache2/conf-available/glpi.conf
cat <<EOF | tee /etc/apache2/conf-available/glpi.conf
Alias /glpi /usr/share/glpi/public

# Redirect configuration for multi-glpicanalteste install_oriation
# You can set this value in each vhost configuration
#SetEnv glpicanalteste_CONFIG_DIR /etc/glpi

<Directory /usr/share/glpi/public>
    Require all granted

    RewriteEngine On

    # Redirect all requests to GLPI router, unless file exists.
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^(.*)$ index.php [QSA,L]
    
 </Directory>

#<Directory /usr/share/glpi>
#    Options None
#    AllowOverride Limit Options FileInfo
#
#    <IfModule mod_authz_core.c>
#        Require all granted
#    </IfModule>
#    <IfModule !mod_authz_core.c>
#        Order deny,allow
#        Allow from all
#    </IfModule>
#</Directory>

<Directory /usr/share/glpi/install_ori>

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

  DocumentRoot /usr/share/glpi/public
  ServerName glpi.dominio.com.br
  ServerAlias www.glpi.dominio.com.br
  ServerAdmin email@dominio.com.br

</VirtualHost>
EOF
service apache2 restart
a2enconf glpi.conf
systemctl reload apache2
#
clear
echo "#-----------------------------------------#"
echo               "AJUSTE PHP.INI"
echo "#-----------------------------------------#"
#
sed -i 's/;date.timezone =/date.timezone = America\/Sao_Paulo/' /etc/php/8.0/apache2/php.ini
sed -i 's/^upload_max_filesize = 2M/upload_max_filesize = 100M/' /etc/php/8.0/apache2/php.ini
sed -i 's/^memory_limit = 128M/memory_limit = 512M/' /etc/php/8.0/apache2/php.ini
sed -i 's/;*session.cookie_httponly =.*/session.cookie_httponly = on/' /etc/php/8.0/apache2/php.ini
systemctl restart apache2
service php8.0-fpm restart
systemctl enable apache2
#
clear
echo "#-----------------------------------------#"
echo          "CRIANDO BASE DE TESTE"
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
chown www-data:www-data -Rf /usr/share/teste/marketplace
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
echo "RODE O COMANDO ABAIXO APOS CONCLUIR A INSTALACAO PELO NAVEGADOR"
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



