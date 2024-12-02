FROM node:20.17.0-slim AS intermediate

RUN mkdir -p client/dist && echo 'SNAPSHOT' > /tmp/version.txt



# when upgrading, look for upstream changes to redirector.conf
# also, confirm setup-odk.sh strips out HTTP-01 ACME challenge location
FROM jonasal/nginx-certbot:5.4.0

EXPOSE 80
EXPOSE 443

# Persist Diffie-Hellman parameters and/or selfsign key
VOLUME [ "/etc/dh", "/etc/selfsign" ]

RUN apt-get update && apt-get install -y netcat-openbsd

RUN mkdir -p /usr/share/odk/nginx/

COPY files/nginx/setup-odk.sh /scripts/
RUN chmod +x /scripts/setup-odk.sh

COPY files/nginx/redirector.conf /usr/share/odk/nginx/
COPY files/nginx/common-headers.conf /usr/share/odk/nginx/

COPY --from=intermediate client/dist/ /usr/share/nginx/html
COPY --from=intermediate /tmp/version.txt /usr/share/nginx/html

ENTRYPOINT [ "/scripts/setup-odk.sh" ]
