FROM alpine:3.2

RUN apk update
RUN apk add dropbear
RUN echo -e "blerp\nblerp" | passwd
RUN mkdir -p /etc/dropbear/
CMD dropbear -F -R -E -p 2202
