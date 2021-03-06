FROM centos:7

ENV REDMINE_VERSION=3.3.0
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
                    which \
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
                    postgresql-devel \
                    mariadb-devel \
  && cd /opt/redmine-$REDMINE_VERSION\
  && curl http://auth02.sec.sovzond.center/ipa/config/ca.crt > /etc/pki/ca-trust/source/anchors/ca.crt \
  && update-ca-trust \
  && echo Installing database.yml\
  && echo -e "production:\n  adapter: sqlite3\n  database: db/redmine.sqlite3\n" > config/database.yml \
  && echo -e "gem \"mysql2\", \"~> 0.3.11\", :platforms => [:mri, :mingw, :x64_mingw]\n\
gem \"pg\", \"~> 0.18.1\", :platforms => [:mri, :mingw, :x64_mingw]\n" > Gemfile.local\
  && cat config/database.yml\
  && chown -R "$REDMINE_USER": /opt/redmine-$REDMINE_VERSION\
  && su -c 'bundle install' "$REDMINE_USER" \
  && su -c 'bundle exec rake generate_secret_token' "$REDMINE_USER" \
#  && su -c 'bundle exec rake db:migrate' $REDMINE_USER \
  && echo $REDMINE_LANG | su -c 'bundle exec rake redmine:load_default_data' $REDMINE_USER \
  && yum remove -y make gcc cpp glibc-devel glibc-headers kernel-headers libmpc mpfr sqlite-devel libxml2-devel xz-devel zlib-devel ImageMagick-devel \
  && yum clean all \
  && yum list installed  | grep '\-devel' | awk '{print $1}' | xargs yum remove -y\
  && echo "" > /var/log/yum.log

WORKDIR /opt/redmine-$REDMINE_VERSION

# CMD su -c 'bundle exec bin/rails server webrick -b 0.0.0.0 -e production' $REDMINE_USER
COPY docker-entrypoint.sh /bin/docker-entrypoint.sh
RUN chmod +x /bin/docker-entrypoint.sh
ENTRYPOINT ["/bin/docker-entrypoint.sh"]

# Redirect logs to stdout
#
RUN echo "Rails.logger = Logger.new(STDOUT)" >> config/additional_environment.rb \
 && echo "Rails.logger.level = :info " >> config/additional_environment.rb

VOLUME [ "/opt/redmine-$REDMINE_VERSION/db", "/opt/redmine-$REDMINE_VERSION/files", "/config" ]
EXPOSE 3000
RUN sed -i 's|Rails.application.initialize!|#Rails.application.initialize!|g' config/environment.rb && echo -e 'RedmineApp::Application.routes.default_scope = "/redmine"\nRails.application.initialize!' >> config/environment.rb
