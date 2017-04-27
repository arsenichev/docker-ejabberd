#!/bin/bash

set -e

echo $EJABBERD_ADMINS
echo $EJABBERD_USERS

export EJABBERD_HTTPS=false
export EJABBERD_ADMINS=$XMPP_ADMIN
export EJABBERD_USERS=$XMPP_ADMIN:$XMPP_ADMIN_PWD
export EJABBERD_AUTH_METHOD="internal external"
export EJABBERD_EXTAUTH_PROGRAM="$EJABBERD_HOME/extauth/auth.py --config $EJABBERD_HOME/extauth/extauth.ini"

EXTAUTH_LOG=/var/log/ejabberd/extauth.log
touch $EXTAUTH_LOG
chmod 777 $EXTAUTH_LOG
tail -F $EXTAUTH_LOG &

#sed -i "s/__namespace__/$NAMESPACE/g;" $EJABBERD_HOME/extauth/extauth.ini
#sed -i "s/__cluster_domain__/$CLUSTER_DOMAIN/g;" $EJABBERD_HOME/extauth/extauth.ini
sed -i "s/__nginx_internal_ip__/$NGINX_INTERNAL_SERVICE_HOST/g;" $EJABBERD_HOME/extauth/extauth.ini
sed -i "s/##mod_cobrowser: {}/mod_cobrowser: {}/g;" $EJABBERD_HOME/conf/ejabberd.yml.tpl

printenv | grep EJABBERD

run start
