#----------------------------------------------------------------------------
# SCRIPT DE BACKUP DA BASE DE PRODUCAO E RESTAURACAO NA BASE DE TESTE DO GLPI 
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
#----------------------------------------
#  USUARIO E SENHA DOS BANCOS DE DADOS
#----------------------------------------
USER1='glpi'
PASS1='123@Mudar'
DB1='glpiprod'
#
USER2='glpiteste'
PASS2='123@Mudar'
DB2='glpiteste'
#
#----------------------------------------
#  DIRETORIO ONDE SERA SALVO O BACKUP
#----------------------------------------
DIR_BK=/etc/backup/restaure-base-teste
#
#----------------------------------------
#      DUMP DO BANCO DE PRODUCAO
#----------------------------------------
mysqldump -u$USER1 -p$PASS1 $DB1 > $DIR_BK/glpi-bkp.sql
#
#----------------------------------------
# RESTAURE DO BANCO DE PRODUCAO NO TESTE
#----------------------------------------
mysql -u$USER2 -p$PASS2 $DB2 < $DIR_BK/glpi-bkp.sql
#
#----------------------------------------
#            REMOVENDO DUMP
#----------------------------------------
rm -Rf /etc/backup/restaure-base-teste/glpi-bkp.sql
#
#----------------------------------------
# COPIANDO PASTA FILES PRODUCAO PARA TESTE GERANDO LOG
#----------------------------------------
cp -Rfuvp /var/lib/glpi/files/* /var/lib/glpiteste/files/  > /etc/backup/restaure-base-teste/log-files-teste.log
ls -lht /var/lib/glpiteste/files/ > /etc/backup/restaure-base-teste/log-size_files-teste.log
#
echo FIM

