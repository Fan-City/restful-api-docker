FROM node:7-alpine
MAINTAINER "michael" <michael.xu1983@qq.com>

RUN apk --update add git supervisor && rm -rf /var/cached/apk/*

# Prepare work directory and copy all files
RUN mkdir /app
WORKDIR /app

# install dependencies
COPY package.json /app
RUN cd /app && npm i --silent

COPY supervisord.conf /app
COPY watcher-tasks.js /app
COPY supervisord.conf supervisord.conf

EXPOSE 8080 8081
CMD ["/usr/bin/supervisord"]