#!/bin/bash

if [ -n "${CONFLUENCE_PROXY_NAME}" ]
then
    xmlstarlet ed -P -S -L \
        --insert "//Connector[not(@proxyName)]" \
        --type attr \
        -n proxyName \
        --value "${CONFLUENCE_PROXY_NAME}" \
        ${CONFLUENCE_INSTALL_DIR}/conf/server.xml
fi

if [ -n "${CONFLUENCE_PROXY_PORT}" ]
then
    xmlstarlet ed -P -S -L \
        --insert "//Connector[not(@proxyPort)]" \
        --type attr \
        -n proxyPort \
        --value "${CONFLUENCE_PROXY_PORT}" \
        ${CONFLUENCE_INSTALL_DIR}/conf/server.xml
fi

if [ -n "${CONFLUENCE_PROXY_SCHEME}" ]
then
    xmlstarlet ed -P -S -L \
        --insert "//Connector[not(@scheme)]" \
        --type attr \
        -n scheme \
        --value "${CONFLUENCE_PROXY_SCHEME}" \
        ${CONFLUENCE_INSTALL_DIR}/conf/server.xml
fi

groupadd -r confluence -g ${GROUP_ID}
useradd -u ${USER_ID} -r -g confluence -d ${CONFLUENCE_INSTALL_DIR} -s /sbin/nologin \
    -c "Confluence user" confluence

chown -R confluence: "${CONFLUENCE_HOME_DIR}" \
                     "${CONFLUENCE_INSTALL_DIR}"

if [ "$1" = 'confluence' ]; then
    exec /usr/local/bin/gosu confluence ${CONFLUENCE_INSTALL_DIR}/bin/start-confluence.sh -fg
else
    exec /usr/local/bin/gosu confluence "$@"
fi
