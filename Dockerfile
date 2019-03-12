FROM node:10.15-alpine


RUN addgroup -S app && adduser -S -g app app

WORKDIR /usr/bin
COPY of-watchdog ./fwatchdog

WORKDIR /root/

# Turn down the verbosity to default level.
ENV NPM_CONFIG_LOGLEVEL warn

RUN mkdir -p /home/app

# Wrapper/boot-strapper
WORKDIR /home/app

# Copy outer function handler
COPY bootstrap.sh ./

# chmod for tmp is for a buildkit issue (@alexellis)
RUN chown app:app -R /home/app \
    && chmod 777 /tmp

# Required to avoid EACCES errors, cf. 
# https://stackoverflow.com/questions/44633419/no-access-permission-error-with-npm-global-install-on-docker-image
RUN npm -g config set user root

# Install the Wireline CLI
RUN apk --no-cache add curl file openssl coreutils git python build-base cairo-dev jpeg-dev pango-dev

RUN npm i -g request && \
    npm i -g request-promise-native && \
    npm i -g domexception && \
    npm i -g wrtc && \
    npm i -g @wirelineio/cli && \
    apk del git python build-base && \
    rm -rf /var/cache/apk/*

RUN [ ! -d /data ] && mkdir /data
RUN chown app:app -R /data

USER app

ENV cgi_headers="true"
ENV fprocess="wire run"
ENV mode="http"
ENV upstream_url="http://127.0.0.1:3000"

ENV exec_timeout="20s" 
ENV write_timeout="25s" 
ENV read_timeout="25s" 

HEALTHCHECK --interval=1s CMD [ -e /tmp/.lock ] || exit 1

CMD ["/home/app/bootstrap.sh"]
