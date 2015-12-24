FROM centos:7

ENV REDMINE_VERSION=3.2.0
ENV REDMINE_URL=http://www.redmine.org/releases/redmine-$REDMINE_VERSION.tar.gz\
    REDMINE_USER=redmine\
    REDMINE_UID=60000\
    REDMINE_GID=60000\
    RAILS_ENV=production\
    REDMINE_LANG=ru

WORKDIR /opt
RUN groupadd -g $REDMINE_GID $REDMINE_USER && useradd -u $REDMINE_UID -g $REDMINE_USER $REDMINE_USER
RUN  curl $REDMINE_URL > redmine-$REDMINE_VERSION.tar.gz\
  && tar -zxvf redmine-$REDMINE_VERSION.tar.gz\
  && rm -f redmine-$REDMINE_VERSION.tar.gz\
  && yum install -y ruby \
                    ruby-devel \
                    rake \
                    rubygem-bundler \
                    make \
                    gcc \
                    patch \
                    git \
                    subversion \
                    libxml2 \
                    libxml2-devel\
                    ImageMagick \
                    ImageMagick-devel \
                    sqlite \
                    sqlite-devel \
  && cd /opt/redmine-$REDMINE_VERSION\
# Installing our ca-certificate
  && curl http://auth02.sec.sovzond.center/ipa/config/ca.crt > /etc/pki/ca-trust/source/anchors/ca.crt \
  && update-ca-trust \
# Installing database.yml
  && echo -e "production:\n  adapter: sqlite3\n  database: db/redmine.sqlite3\n" > config/database.yml \
  && chown -R "$REDMINE_USER": /opt/redmine-$REDMINE_VERSION\
  && su -c 'bundle install' "$REDMINE_USER" \
  && su -c 'bundle exec rake generate_secret_token' "$REDMINE_USER" \
  && su -c 'bundle exec rake db:migrate' $REDMINE_USER \
  && echo $REDMINE_LANG | su -c 'bundle exec rake redmine:load_default_data' $REDMINE_USER \
  && yum remove -y make gcc cpp glibc-devel glibc-headers kernel-headers libmpc mpfr sqlite-devel libxml2-devel xz-devel zlib-devel ImageMagick-devel \
  && yum clean all \
  && echo "" > /var/log/yum.log

WORKDIR /opt/redmine-$REDMINE_VERSION
#
# Applying patch
RUN echo -e "From ff5360cc63177f3e636bbff769fb7c5266ddef28 Mon Sep 17 00:00:00 2001\n\
From: fedor patlin <patlin.f@sovzond.center>\n\
Date: Thu, 24 Dec 2015 12:32:17 +0500\n\
Subject: [PATCH] User creation from LDAP. Exception when attribute contains\n\
 non-ascii characters\n\
\n\
---\n\
 app/models/auth_source_ldap.rb | 3 ++-\n\
 1 file changed, 2 insertions(+), 1 deletion(-)\n\
\n\
diff --git a/app/models/auth_source_ldap.rb b/app/models/auth_source_ldap.rb\n\
index d5a8550..c403502 100644\n\
--- a/app/models/auth_source_ldap.rb\n\
+++ b/app/models/auth_source_ldap.rb\n\
@@ -197,7 +197,8 @@ class AuthSourceLdap < AuthSource\n\
 \n\
   def self.get_attr(entry, attr_name)\n\
     if !attr_name.blank?\n\
-      entry[attr_name].is_a?(Array) ? entry[attr_name].first : entry[attr_name]\n\
+      result = entry[attr_name].is_a?(Array) ? entry[attr_name].first : entry[attr_name]\n\
+      result.force_encoding('UTF-8')\n\
     end\n\
   end\n\
 end\n\
-- \n\
2.5.0\n\
\n" | patch -p1

CMD su -c 'bundle exec bin/rails server webrick -b 0.0.0.0 -e production' $REDMINE_USER

# Redirect logs to stdout
#
RUN echo "Rails.logger = Logger.new(STDOUT)" >> config/additional_environment.rb \
 && echo "Rails.logger.level = :info " >> config/additional_environment.rb

VOLUME [ "/opt/redmine-$REDMINE_VERSION/db", "/opt/redmine-$REDMINE_VERSION/config" ]
EXPOSE 3000
