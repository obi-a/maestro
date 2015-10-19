FROM cloudgear/ruby:2.2-onbuild
ENV RAGIOS_COUCHDB_ADDRESS couchdb
ENV RAGIOS_BIND_ADDRESS tcp://0.0.0.0:5041
RUN apt-get update
RUN apt-get install -y firefox xvfb
EXPOSE 5041
CMD ./ragios s start
