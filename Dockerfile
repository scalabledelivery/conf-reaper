FROM alpine:latest
RUN apk add bash curl jq
COPY . /usr/src
ENTRYPOINT bash /usr/src/reaper.sh