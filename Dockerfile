FROM node:8.10-alpine

RUN apk --no-cache add curl

RUN addgroup -S app && adduser -S -g app app

WORKDIR /usr/bin
COPY of-watchdog ./fwatchdog

WORKDIR /root/

# Turn down the verbosity to default level.
ENV NPM_CONFIG_LOGLEVEL warn

RUN mkdir -p /home/app/function

# Wrapper/boot-strapper
WORKDIR /home/app
COPY package.json ./

# This ordering means the npm installation is cached for the outer function handler.
RUN npm i

# Copy outer function handler
COPY index.js ./
COPY bootstrap.sh ./

# chmod for tmp is for a buildkit issue (@alexellis)
RUN chown app:app -R /home/app \
    && chmod 777 /tmp

USER app

ENV cgi_headers="true"
ENV fprocess="node index.js"
ENV mode="http"
ENV upstream_url="http://127.0.0.1:3000"

ENV exec_timeout="20s" 
ENV write_timeout="25s" 
ENV read_timeout="25s" 

HEALTHCHECK --interval=1s CMD [ -e /tmp/.lock ] || exit 1

CMD ["/home/app/bootstrap.sh"]
