FROM cloudgear/ruby:2.2-onbuild
ENV RAGIOS_COUCHDB_ADDRESS couchdb
ENV RAGIOS_BIND_ADDRESS tcp://0.0.0.0:80

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        bzip2 \
        libfontconfig \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
    && mkdir /tmp/phantomjs \
    && curl -L https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 \
           | tar -xj --strip-components=1 -C /tmp/phantomjs \
    && cd /tmp/phantomjs \
    && mv bin/phantomjs /usr/local/bin \
    && cd \
    && apt-get purge --auto-remove -y \
        curl \
    && apt-get clean \
    && rm -rf /tmp/* /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y supervisor

RUN mkdir -p /var/log/supervisor

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN gem install scout_realtime

EXPOSE 80 5555
CMD ["/usr/bin/supervisord"]
