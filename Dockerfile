# NodeBB — Railway wrapper image.
#
# The category leader's template writes NodeBB's setup.json from a start command
# of the form `sh -c "... echo $CONFIG_JSON > setup.json ..."`. The JSON value is
# expanded by the outer shell and then re-parsed by the inner one, which performs
# quote removal, so the file that lands on disk is `{database: postgres, url: ...}`
# — not JSON. NodeBB's installer aborts on it and the container exits, so the
# forum never serves a page. This wrapper writes config.json with a JSON encoder
# instead of a shell, installs NodeBB non-interactively before the port is bound
# (upstream's documented alternative is a public web installer that lets the first
# stranger to load the URL create the administrator), re-applies the admin
# password on every boot so a redeploy is a working password reset, refuses to
# start without a password, and keeps config, build output and uploads on the
# volume.
FROM ghcr.io/nodebb/nodebb:4.15.1

USER root
COPY railway-entrypoint.sh /railway/entrypoint.sh
COPY railway-write-config.js /railway/write-config.js
RUN chmod +x /railway/entrypoint.sh

ENV NODEBB_DATA_DIR=/data \
    NODEBB_ADMIN_USERNAME=admin \
    CONFIG_DIR=/opt/config

ENTRYPOINT ["/railway/entrypoint.sh"]
