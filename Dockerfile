FROM debian:latest

RUN apt-get update && apt-get install -y wget

WORKDIR /tmp
ARG DEB_FILE=hugo_extended_0.139.4_linux-amd64.deb
RUN wget https://github.com/gohugoio/hugo/releases/download/v0.139.4/${DEB_FILE}
RUN dpkg -i ${DEB_FILE}
RUN rm ${DEB_FILE}

WORKDIR /hugo
COPY . .

# Environment variables
ENV HUGO_ENV=development
ENV HUGO_BASEURL=http://localhost:1313
ENV HUGO_APPENDPORT=true

# Start Hugo server
ENTRYPOINT ["sh", "-c", "hugo server --bind 0.0.0.0 -e ${HUGO_ENV} --baseURL=${HUGO_BASEURL} --appendPort=${HUGO_APPENDPORT}"]

