#!/bin/bash

CUSTOM_CONFDIR=/config
REDMINE_HOME=/opt/redmine-"$REDMINE_VERSION"

load_custom_config(){
  find "$CUSTOM_CONFDIR" -type f -name '*.yml' -exec cp -v {} "$REDMINE_HOME"/config \;
}

start_application(){
  su -c "bundle exec bin/rails server webrick -b 0.0.0.0 -e production" "$REDMINE_USER"
}

load_custom_config
start_application
