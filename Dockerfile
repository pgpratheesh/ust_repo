FROM centos:centos6

FROM tomcat:latest
#https://github.com/docker-library/tomcat

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH

RUN mkdir -p "$CATALINA_HOME"
RUN chown -R 777 "$CATALINA_HOME"
WORKDIR $CATALINA_HOME

EXPOSE 9090
CMD ["catalina.sh", "run"]


