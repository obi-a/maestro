FROM cloudgear/ruby:2.2-onbuild
ENV RAGIOS_COUCHDB_ADDRESS couchdb
ENV RAGIOS_BIND_ADDRESS tcp://0.0.0.0:80

RUN apt-get update
RUN apt-get dist-upgrade -y

RUN DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install python-software-properties
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install software-properties-common
RUN DEBIAN_FRONTEND=noninteractive add-apt-repository ppa:mozillateam/firefox-next

RUN apt-get update
RUN apt-get install -y firefox xvfb
EXPOSE 80
CMD ./ragios s start
