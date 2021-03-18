FROM centos:7
LABEL maintainer="pawel.adamczyk.1@p.lodz.pl"

EXPOSE 2222/tcp 

# SGE
ADD soge/sge.sh /etc/profile.d/
ADD soge/module.sh /etc/profile.d/

ADD repos/ghetto.repo /etc/yum.repos.d/

#RUN \
# Tymczasowa instalacja git-a i ansible w celu uruchomienia playbook-ow
RUN yum -y install yum-plugin-remove-with-leaves epel-release 
#&& \
RUN yum -y install ansible 
#&& \
# Poprawka maksymalnej grupy systemowe konieczna ze wzgledu na wymagane GID grupy sgeadmin systemu SOGE, zaszlosc historyczna
RUN sed -ie 's/SYS_GID_MAX               999/SYS_GID_MAX               997/g' /etc/login.defs 
#&& yum -y install 
#git && \
# Pobranie repozytorium z playbook-ami
RUN yum -y install git
#&&
RUN cd /; git clone https://github.com/bockpl/boplaybooks.git
#; cd /boplaybooks && \
# Skasowanie tymczasowego srodowiska git, UWAGA: Brak tego wpisu w tej kolejnosci pozbawi srodowiska oprogramowania narzedziowego less, man itp.:
RUN yum -y remove git epel-release --remove-leaves 
#&& \
# Instalacja systemu autoryzacji AD PBIS
RUN \
cd boplaybooks ; echo ; pwd ; echo && \
#ansible-playbook Playbooks/install_PBIS.yml --connection=local --extra-vars "var_host=127.0.0.1" && \
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
# Skasowanie katalogu z playbookami
rm -rf /boplaybooks && \
# Skasowanie tymczasowego srodowiska ansible
yum -y remove ansible --remove-leaves && \
cd /; rm -rf /boplaybooks

# Dodanie autoryzacji  LDAP
RUN  yum install -y \
        nss-pam-ldapd \
        openssl \
        nscd \
        openldap-clients \
        authconfig && \
     yum clean all && \
     rm -rf /var/cache/yum

RUN  authconfig --update --enableldap --enableldapauth
RUN  authconfig --updateall --enableldap --enableldapauth

COPY copy4ldap/fingerprint-auth-ac /etc/pam.d/
COPY copy4ldap/system-auth-ac /etc/pam.d/
COPY copy4ldap/smartcard-auth-ac /etc/pam.d/
COPY copy4ldap/password-auth-ac /etc/pam.d/
#COPY copy4ldap/*ac /etc/pam.d/
COPY copy4ldap/nsswitch.conf /etc/
#COPY copy4ldap/nslcd.conf /etc/
#COPY copy4ldap/*conf /etc/

# Dodanie konfiguracji monit-a
ADD monit/monitrc /etc/
ADD monit/nslcd.conf /etc/monit.d/
ADD monit/sync_hosts.conf /etc/monit.d/
ADD monit/sshd.conf /etc/monit.d/
ADD monit/sge_exec.conf /etc/monit.d/
#ADD monit/pbis.conf /etc/monit.d/
#ADD monit/*.conf /etc/monit.d/
ADD monit/stop_sshd.sh /etc/monit.d/
ADD monit/stop_nslcd.sh /etc/monit.d/
ADD monit/start_sshd.sh /etc/monit.d/
ADD monit/start_nslcd.sh /etc/monit.d/
#ADD monit/stop_pbis.sh /etc/monit.d/
ADD monit/start_sync_hosts.sh /etc/monit.d/
#ADD monit/start_pbis.sh /etc/monit.d/
#ADD monit/*.sh /etc/monit.d/
#RUN mkdir /var/run/nslcd
RUN chown nslcd -fR /var/run/nslcd

# Zmiana uprawnien konfiguracji monit-a
RUN chmod 700 /etc/monitrc

ENV TIME_ZONE=Europe/Warsaw
ENV LANG=en_US.UTF-8

ADD start.sh /start.sh

CMD ["/bin/bash","-c","/start.sh"]
