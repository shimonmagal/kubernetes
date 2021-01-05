FROM openjdk:8-jre-slim
LABEL maintainer="support@overops.com"

# install curl and procps
RUN apt-get update; apt-get install -y curl procps

# add rootless user
RUN groupadd --gid 1000 overops
RUN adduser --home /opt/takipi-server --uid 1000 --gid 1000 overops

# create and change ownership of private directory
RUN mkdir /opt/private; chown overops:overops /opt/private

# rootless
USER 1000:1000

# environmental variables
ENV HOST_URL localhost:8080
ENV FRONTEND_URL http://localhost:8080

ENV DB_TYPE h2
ENV DB_URL database_server_url
ENV DB_USER database_user
ENV DB_PASS database_password
ENV DB_SSL --no-db-ssl

# install into the /opt directory
WORKDIR /opt

# download and install the backend
RUN curl -sL https://s3.amazonaws.com/app-takipi-com/deploy/takipi-server/takipi-server-java.tar.gz | tar -xvzf -

# use mount to make .properties files available
RUN mv /opt/takipi-server/conf/tomcat-original/my.server.properties private/my.server.properties \
 && mv /opt/takipi-server/conf/tomcat-original/smtp.properties private/smtp.properties \
 && mv /opt/takipi-server/conf/tomcat-original/smtpserver.properties private/smtpserver.properties \
 && touch private/my.agentsettings.properties \
 && mkdir -p /opt/takipi-server/conf/tomcat/shared \
 && ln -s /opt/private/my.server.properties /opt/takipi-server/conf/tomcat/shared/my.server.properties \
 && ln -s /opt/private/smtp.properties /opt/takipi-server/conf/tomcat/shared/smtp.properties \
 && ln -s /opt/private/smtpserver.properties /opt/takipi-server/conf/tomcat/shared/smtpserver.properties \
 && ln -s /opt/private/my.agentsettings.properties /opt/takipi-server/conf/tomcat/shared/my.agentsettings.properties
VOLUME ["/opt/private"]

# use a volume to store data
VOLUME ["/opt/takipi-server/storage"]

WORKDIR /opt/takipi-server

# create a run script
RUN echo "#!/bin/bash" > run.sh \
 && echo "cat /opt/takipi-server/VERSION" >> run.sh \
 && echo "if [ -r /opt/takipi-server/storage/s3/data/onprem-sparktale/125/93/kd/KD.class ]" >> run.sh \
 && echo "then" >> run.sh \
 && echo "cp -p /opt/takipi-server/storage/s3/data/onprem-sparktale/125/93/kd/KD.class /opt/takipi-server/conf/tomcat/shared/." >> run.sh \
 && echo "fi" >> run.sh \
 && echo "/opt/takipi-server/bin/takipi-server.sh -u \${HOST_URL} --frontend-url \${FRONTEND_URL} --db-type \${DB_TYPE} --db-url \${DB_URL} --db-user \${DB_USER} --db-password \${DB_PASS} \${DB_SSL} --skip-resource-validation start" >> run.sh \
 && echo "/bin/sleep 10" >> run.sh \
 && echo "/usr/bin/tail -f /opt/takipi-server/log/tomcat/stdout -f /opt/takipi-server/log/tomcat/stderr -f /opt/takipi-server/log/tomcat/tomcat/catalina.log" >> run.sh \
 && chmod +x run.sh

# print version
RUN cat /opt/takipi-server/VERSION

EXPOSE 8080

# run the service, printing logs to stdout
CMD ["./run.sh"]
