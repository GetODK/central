FROM node:18.17 as intermediate
ARG OIDC_DISCOVERY_URL
ARG OIDC_CLIENT_ID
ARG OIDC_CLIENT_SECRET

COPY ./ ./
RUN files/prebuild/write-version.sh
RUN echo "\$OIDC_DISCOVERY_URL in the Dockerfile: [${OIDC_DISCOVERY_URL:-blank}]"
RUN OIDC_DISCOVERY_URL="$OIDC_DISCOVERY_URL" OIDC_CLIENT_ID="$OIDC_CLIENT_ID" OIDC_CLIENT_SECRET="$OIDC_CLIENT_SECRET" \
  files/prebuild/build-frontend.sh

# when upgrading, look for upstream changes to redirector.conf
# also, confirm setup-odk.sh strips out HTTP-01 ACME challenge location
FROM jonasal/nginx-certbot:4.2.0

EXPOSE 80
EXPOSE 443

VOLUME [ "/etc/dh", "/etc/selfsign", "/etc/nginx/conf.d" ]
ENTRYPOINT [ "/bin/bash", "/scripts/setup-odk.sh" ]

RUN apt-get update && apt-get install -y netcat-openbsd

RUN mkdir -p /usr/share/odk/nginx/

COPY files/nginx/setup-odk.sh /scripts/
COPY files/local/customssl/*.pem /etc/customssl/live/local/
COPY files/nginx/*.conf* /usr/share/odk/nginx/

COPY --from=intermediate client/dist/ /usr/share/nginx/html
COPY --from=intermediate /tmp/version.txt /usr/share/nginx/html
