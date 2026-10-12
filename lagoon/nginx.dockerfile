ARG CLI_IMAGE
FROM ${CLI_IMAGE} as cli

FROM uselagoon/nginx-drupal:latest

COPY --from=cli /app /app

# Real IP through Fastly.
RUN set -o pipefail \
  && wget -qO- https://api.fastly.com/public-ip-list \
    | grep -oE '[0-9a-f.:]+/[0-9]+' \
    | sed 's|.*|set_real_ip_from &;|' \
    > /etc/nginx/conf.d/00-fastly-realip.conf \
  && test -s /etc/nginx/conf.d/00-fastly-realip.conf

# Redirects.
COPY ./lagoon/redirects-map.conf /etc/nginx/redirects-map.conf

# Drupal at /cms and /api, everything else to the frontend.
COPY ./lagoon/app.conf /etc/nginx/conf.d/app.conf

# Lagoon runs as a random UID in group 0; ep rewrites these files in place at startup.
RUN fix-permissions /etc/nginx

# Define where the Drupal Root is located
ENV WEBROOT=web
