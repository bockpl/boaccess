FROM centos:7
LABEL maintainer="przemyslaw.trzeciak@p.lodz.pl"

EXPOSE 2222/tcp 

# SGE
ADD soge/sge.sh /etc/profile.d/
ADD soge/module.sh /etc/profile.d/


RUN \
# Tymczasowa instalacja git-a i ansible w celu uruchomienia playbook-ow
yum -y install yum-plugin-remove-with-leaves && \
yum -y install ansible && \
# Poprawka maksymalnej grupy systemowe konieczna ze wzgledu na wymagane GID grupy sgeadmin systemu SOGE, zaszlosc historyczna
sed -ie 's/SYS_GID_MAX               999/SYS_GID_MAX               997/g' /etc/login.defs && yum -y install git && \
# Pobranie repozytorium z playbook-ami
cd /; git clone https://github.com/bockpl/boplaybooks.git; cd /boplaybooks && \
# Instalacja systemu autoryzacji AD PBIS
ansible-playbook Playbooks/install_PBIS.yml --connection=local --extra-vars "var_host=127.0.0.1" && \
# Instalacja obslugi e-mail
ansible-playbook Playbooks/install_Mail_support.yml --connection=local --extra-vars "var_host=127.0.0.1" && \
# Instalacja systemu Monit
ansible-playbook Playbooks/install_Monit.yml --connection=local --extra-vars "var_host=127.0.0.1" && \
# Instalacja wymagan dla podsystemu Module
ansible-playbook Playbooks/install_dep_Module.yml --connection=local --extra-vars "var_host=127.0.0.1" && \
# Instalacja wymagan dla ssh
ansible-playbook Playbooks/install_boaccess_ssh.yml --connection=local --extra-vars "var_host=127.0.0.1" && \
# Instalacja wymagan umozliwiajacych uruchamianie zadan w systemie kolejkowym
ansible-playbook Playbooks/install_boaccess_submit.yml --connection=local --extra-vars "var_host=127.0.0.1" && \
# Instalacja narzedzi do interaktywnej wpracy w konsoli dla uzytkownikow klastra
ansible-playbook Playbooks/install_boaccess_tools.yml --connection=local --extra-vars "var_host=127.0.0.1" && \
# Skasowanie tymczasowego srodowiska git i ansible
yum -y remove git --remove-leaves && \
yum -y remove ansible --remove-leaves && \
cd /; rm -rf /boplaybooks

# Dodanie konfiguracji monit-a
ADD monit/monitrc /etc/
ADD monit/sshd.conf /etc/monit.d/
ADD monit/pbis.conf /etc/monit.d/
ADD monit/sync_hosts.conf /etc/monit.d/
ADD monit/start_sshd.sh /etc/monit.d/
ADD monit/start_pbis.sh /etc/monit.d/
ADD monit/start_sync_hosts.sh /etc/monit.d/

# Zmiana uprawnien konfiguracji monit-a
RUN chmod 700 /etc/monitrc

ENV TIME_ZONE=Europe/Warsaw
ENV LANG=pl_PL.UTF-8

ADD start.sh /start.sh

CMD ["/bin/bash","-c","/start.sh"]
