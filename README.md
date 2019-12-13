# boaccess
Kontener dostępowy klastra Bluecoean

Przyklad wywolania:
docker run -dt --rm --name ${BOACCESS} --cpus ${RDZENIE_BOACCESS} --memory ${PAMIEC_BOACCESS_G} --memory-swap ${PAMIEC_BOACCESS_G} -h ${BO_HOSTNAME} -v ${MFS_OPT}:${BO_OPT} -v ${MFS_HOME}:${BO_HOME} -p 2222:22 --net cluster_network --ip ${BO_IP} -e DEBUG=true ${BO_REPO}
