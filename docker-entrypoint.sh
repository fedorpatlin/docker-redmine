#!/bin/bash

CUSTOM_CONFDIR=/config
REDMINE_HOME=/opt/redmine-"$REDMINE_VERSION"

load_custom_config(){
  if [ -f "$CUSTOM_CONFDIR"/database.yml ]; then
    cp -v "$CUSTOM_CONFDIR"/database.yml "$REDMINE_HOME"/config
  fi
  if [ -f "$CUSTOM_CONFDIR"/configuration.yml ]; then
    cp -v "$CUSTOM_CONFDIR"/configuration.yml "$REDMINE_HOME"/config/configuration.yml
  fi
}

make_database_migrations(){
  su -c 'bundle exec rake generate_secret_token' "$REDMINE_USER"
  su -c 'bundle exec rake db:migrate' $REDMINE_USER
}

start_application(){
  su -c "bundle exec bin/rails server webrick -b 0.0.0.0 -e production" "$REDMINE_USER"
}

load_custom_config
if [ -z "$NO_MIGRATION" ]; then
  make_database_migrations;
fi
start_application
