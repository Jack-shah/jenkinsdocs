FROM node:16-alpine

RUN apk update && apk upgrade && apk add -U git curl
