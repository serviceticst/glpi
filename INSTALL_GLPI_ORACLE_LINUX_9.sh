#----------------------------------------------------------------------------
#   INSTALACAO AUTOMATIZADA DO GLPI NA ULTIMA VERSAO ESTAVEL COM ORACLE LINUX 9
#   
#   Download da ISO (INSTALACAO EM MINIMAL INSTALL): 
#   https://yum.oracle.com/ISOS/OracleLinux/OL9/u2/x86_64/OracleLinux-R9-U2-x86_64-dvd.iso
#----------------------------------------------------------------------------
#
#  Desenvolvido por: Service TIC Solucoes Tecnologicas
#            E-mail: contato@servicetic.com.br
#              Site: www.servicetic.com.br
#          Linkedin: https://www.linkedin.com/company/serviceticst
#          Intagram: https://www.instagram.com/serviceticst
#          Facebook: https://www.facebook.com/serviceticst
#           Twitter: https://twitter.com/serviceticst
#           YouTube: https://youtube.com/c/serviceticst
#            GitHub: https://github.com/serviceticst
#
#           YouTube: https://youtu.be/La4qbZfhO5Y
#           
#-------------------------------------------------
#
clear
echo "#-----------------------------------------#"
echo      "INSTALANDO REPOSITORIO/PACOTES"
echo "#-----------------------------------------#"
dnf -y install epel-release 
dnf install -y dnf-utils yum-utils nano telnet traceroute net-tools unzip bzip2 tar wget dnf-plugins-core 
dnf -y install https://rpms.remirepo.net/enterprise/remi-release-9.rpm 
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm 
dnf install 'dnf-command(config-manager)' 
dnf -y module install php:remi-8.0 
dnf -y install yum-plugin-copr && dnf -y copr enable ligenix/enterprise-glpi
dnf -y install glpi 
dnf -y install httpd && systemctl enable httpd 
dnf -y install php-soap php-snmp php-pear*
dnf -y install certbot python3-certbot-apache
#
clear
echo "#------------------------------------------#"
echo  "BAIXANDO GLPI UTIMA VERSAO ESTAVEL DO GLPI" 
echo "#------------------------------------------#"
rm -Rf /usr/share/glpi
url=$(wget -qO- https://github.com/glpi-project/glpi/releases/latest | grep -o 'https://github.com/glpi-project/glpi/releases/download/[^"]*' | head -1)
file_name=$(basename "$url")
wget "$url"
tar xvf "$file_name" -C /usr/share
rm -Rf "$file_name"
#
clear
echo "#------------------------------------------#"
echo        "CRIANDO ARQUIVO APACHE-VHOST" 
echo "#------------------------------------------#"
rm -Rf /etc/httpd/conf.d/glpi.conf
touch /etc/httpd/conf.d/glpi.conf
cat <<EOF | tee /etc/httpd/conf.d/glpi.conf
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
#
clear
echo "#-----------------------------------------#"
echo "ATIVANDO E LIBERANDO A PORTA 80-443/TCP NO FIREWALL"
echo "#-----------------------------------------#"
firewall-cmd --permanent --add-port=80/tcp 
firewall-cmd --permanent --add-port=443/tcp 
firewall-cmd --reload 
systemctl restart firewalld 
systemctl enable firewalld
#
clear
echo "#-----------------------------------------#"
echo               "AJUSTE PHP.INI"
echo "#-----------------------------------------#"
sed -i 's/;date.timezone =/date.timezone = America\/Sao_Paulo/' /etc/php.ini
sed -i 's/^upload_max_filesize = 2M/upload_max_filesize = 100M/' /etc/php.ini
sed -i 's/^memory_limit = 128M/memory_limit = 512M/' /etc/php.ini
sed -i 's/;*session.cookie_httponly =.*/session.cookie_httponly = on/' /etc/php.ini
#
clear
echo "#------------------------------------------#"
echo        "CRIANDO ARQUIVO DOWNSTREAM" 
echo "#------------------------------------------#"
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
echo    "CRIANDO DIRETORIOS E DANDO PERMISSAO" 
echo "#------------------------------------------#"
mkdir -p /var/lib/glpi/files/_documents 
chown apache:apache -Rf /etc/glpi
chown apache:apache -Rf /var/lib/glpi/files 
chown apache:apache -Rf /var/log/glpi
chown apache:apache -Rf /usr/share/glpi/marketplace
#
clear
echo "#-----------------------------------------#"
echo         "CONFIGURANDO SELINUX"
echo "#-----------------------------------------#"
setsebool -P httpd_can_sendmail 1
setsebool -P httpd_can_network_connect 1
setsebool -P httpd_can_network_connect_db 1
setsebool -P httpd_mod_auth_ntlm_winbind  1
setsebool -P allow_httpd_mod_auth_ntlm_winbind 1
setenforce 0 
#
clear
echo "#-----------------------------------------#"
echo        "REINICIANDO APACHE E PHP-FPM"
echo "#-----------------------------------------#"
systemctl restart httpd
systemctl restart php-fpm 
#
clear
echo "#-----------------------------------------#"
echo     "INSTALE O SGDB DA SUA PREFERENCIA"
echo "#-----------------------------------------#"
echo "ACESSE O GLPI PELO NAVEGADOR E CONCLUA A INSTALACAO"
echo "#-----------------------------------------#" 
echo "RODE O COMANDO ABAIXO APOS CONCLUIR A INSTALACAO PELO NAVEGADOR"
echo "mv /usr/share/glpi/install/ /usr/share/glpi/install_ori"
echo "mv /usr/share/teste/install/ /usr/share/teste/install_ori"
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
