#----------------------------------------------------------------------------
#   INSTALACAO AUTOMATIZADA GLPI 10 NO ORACLE LINUX 8 + BASE DE HOMOLOGACAO
#   
#   Download da ISO (INSTALACAO EM MINIMAL INSTALL): 
#   https://yum.oracle.com/ISOS/OracleLinux/OL8/u5/x86_64/OracleLinux-R8-U5-x86_64-dvd.iso
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
#              Blog: https://servicetic.com.br/glpi-10-instalacao-automatizada-no-oracle-linux-8
#           YouTube: https://www.youtube.com/watch?v=G-NSQNW7GyU&list=PLwXxs1htu2adKC2f9mH1mx0HZ0qKJgnqw&index
#           
#-------------------------------------------------
#
clear
echo "#-----------------------------------------#"
echo      "INSTALANDO REPOSITORIO/PACOTES"
echo "#-----------------------------------------#"
dnf -y install epel-release 
dnf install -y dnf-utils yum-utils nano telnet traceroute net-tools unzip bzip2 tar wget dnf-plugins-core &&
dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm &&
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm &&
dnf install 'dnf-command(config-manager)' &&
dnf -y module install php:remi-8.0 &&
dnf -y install yum-plugin-copr && dnf -y copr enable ligenix/enterprise-glpi &&
dnf -y install glpi &&
dnf -y install httpd &&
dnf -y install php-pecl-apcu php-soap php-xmlrpc php-pecl-zendopcache php-snmp php-opcache &&
dnf -y install php-sodium php-pear* &&
dnf -y install certbot python3-certbot-apache
#
clear
echo "#-----------------------------------------#"
echo  "BAIXANDO O GLPI 10 E COPIANDO ARQUIVO DOWNSTREAM"
echo "#-----------------------------------------#"
cd /tmp
mv /usr/share/glpi /usr/share/glpi95
wget https://github.com/glpi-project/glpi/releases/download/10.0.2/glpi-10.0.2.tgz
tar -zxvf glpi-10.0.2.tgz
mv glpi /usr/share/
cp -Rfp /usr/share/glpi95/inc/downstream.php /usr/share/glpi/inc/
#
clear
echo "#-----------------------------------------#"
echo   "HABILITANDO INICIO DO SERVIÇO NO BOOT"
echo "#-----------------------------------------#"
#
systemctl enable --now httpd &&
systemctl enable --now firewalld &&
#
clear
echo "#-----------------------------------------#"
echo "ATIVANDO E LIBERANDO A PORTA 80-443/TCP NO FIREWALL"
echo "#-----------------------------------------#"
firewall-cmd --permanent --add-port=80/tcp &&
firewall-cmd --permanent --add-port=443/tcp &&
firewall-cmd --reload &&
systemctl restart firewalld &&
#
clear
echo "#-----------------------------------------#"
echo           "AJUSTANDO O TIMEZONE"
echo "#-----------------------------------------#"
rm -f /etc/localtime
ln -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
sed -i 924i'date.timezone = America/Sao_Paulo' /etc/php.ini
#
clear
echo "#-----------------------------------------#"
echo        "AJUSTANDO PHP.INI E GLPI.CONF"
echo "#-----------------------------------------#"
sed -i '846s/^/#/' /etc/php.ini
sed -i 847i'upload_max_filesize = 25M' /etc/php.ini
sed -i '28s/^/#/' /etc/httpd/conf.d/glpi.conf
sed -i '34s/^/#/' /etc/httpd/conf.d/glpi.conf
#
clear
echo "#-----------------------------------------#"
echo          "CRIANDO BASE DE TESTE"
echo "#-----------------------------------------#"
cp -Rfp /usr/share/glpi /usr/share/glpiteste
cp -Rfp /etc/glpi /etc/glpiteste
cp -Rfp /var/lib/glpi /var/lib/glpiteste
cp -Rfp /var/log/glpi /var/log/glpiteste
cp -Rfp /etc/httpd/conf.d/glpi.conf /etc/httpd/conf.d/glpiteste.conf
sed -i 's/glpi/glpiteste/' /etc/httpd/conf.d/glpiteste.conf
sed -i '1s/^/#/' /etc/httpd/conf.d/glpiteste.conf
sed -i 2i'Alias /glpiteste /usr/share/glpiteste' /etc/httpd/conf.d/glpiteste.conf
rm -Rf /etc/glpiteste/config_db.php
sed -i 's/glpi/glpiteste/' /usr/share/glpiteste/inc/downstream.php
#
clear
echo "#-----------------------------------------#"
echo          "APLICANDO PERMISSÕES"
echo "#-----------------------------------------#"
chown -Rf apache:apache /usr/share/glpi
chown -Rf apache:apache /etc/glpi
chown -Rf apache:apache /var/log/glpi
chown -Rf apache:apache /var/lib/glpi/files
chown -Rf apache:apache /usr/share/glpiteste
chown -Rf apache:apache /etc/glpiteste
chown -Rf apache:apache /var/log/glpiteste
chown -Rf apache:apache /var/lib/glpi/filesteste
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
echo           "REINICIANDO APACHE"
echo "#-----------------------------------------#"
systemctl restart httpd &&
#
clear
echo "#-----------------------------------------#"
echo          "INSTALANDO O GLPI-AGENT"
echo "#-----------------------------------------#"
#
echo "PARA INSTALAR O GLPI-AGENT SIGA OS PASSOS ABAIXO"
#
echo "wget https://github.com/glpi-project/glpi-agent/releases/download/1.4/glpi-agent-1.4-linux-installer.pl"
echo "perl glpi-agent-1.4-linux-installer.pl --install --type=all --runnow --service"
#
echo "PERGUNTA 1: Provide an url to configure GLPI server:"
echo "RESPOSTA 1: http://127.0.0.1/front/inventory.php OU http://GLPI.SEUDOMINIO.COM/front/inventory.php"
#
echo "PERGUNTA 2: Provide a path to configure local inventory run or leave it empty:"
echo "RESPOSTA 2: /tmp"
#
echo "PERGUNTA 3: Provide a tag to configure or leave it empty:"
echo "RESPOSTA 3: OPCIONAL OU DEIXA EM BRANCO"
#
echo "curl http://127.0.0.1:62354/status"
echo "systemctl enable glpi-agent"
echo "systemctl restart glpi-agent"
echo "systemctl status glpi-agent"
#
#
echo "#-----------------------------------------#"
echo     "INSTALE O SGDB DA SUA PREFERENCIA"
echo "#-----------------------------------------#"
echo "ACESSE O GLPI PELO NAVEGADOR E CONCLUA A INSTALACAO"
echo "#-----------------------------------------#" 
echo "RODE O COMANDO ABAIXO APOS CONCLUIR A INSTALAÇÃO PELO NAVEGADOR"
echo "mv /usr/share/glpi/install/ /usr/share/glpi/install_old"
echo "mv /usr/share/glpiteste/install/ /usr/share/glpiteste/install_old"
echo "#-----------------------------------------#"
echo "DESCOMENTE A LINHA 28 E 34 DO ARQUIVO /etc/httpd/conf.d/glpi.conf E REINICIE O HTTPD"
echo "#-----------------------------------------#"
echo "ALTERE A SENHA E REMOVA OS 3 USUARIOS ABAIXO"
echo "normal"
echo "post-only"
echo "tech"
echo "#-----------------------------------------#"
echo    "REINICIE O SERVIDOR NO FINAL DE TUDO"
echo "#-----------------------------------------#"
echo                  "FIM"
echo "#-----------------------------------------#"
