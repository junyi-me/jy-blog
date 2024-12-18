FROM debian:latest AS builder

RUN apt-get update && apt-get install -y wget

WORKDIR /tmp
ARG DEB_FILE=hugo_extended_0.139.4_linux-amd64.deb
RUN wget https://github.com/gohugoio/hugo/releases/download/v0.139.4/${DEB_FILE}
RUN dpkg -i ${DEB_FILE}
RUN rm ${DEB_FILE}

WORKDIR /hugo
COPY . .

RUN hugo -e production -d /public

FROM nginx:alpine
COPY --from=builder /public /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

