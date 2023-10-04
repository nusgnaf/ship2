ARG APP_ROOT=/src/app
ARG RUBY_VERSION=3.2.2

FROM ruby:${RUBY_VERSION}-alpine AS base
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
ARG APP_ROOT

RUN apk add --no-cache build-base sqlite-dev

RUN mkdir -p ${APP_ROOT}
COPY Gemfile Gemfile.lock ${APP_ROOT}/

WORKDIR ${APP_ROOT}
RUN gem install bundler:2.4.19 \
    && bundle config --local deployment 'true' \
    && bundle config set --global mirror.https://rubygems.org https://gems.ruby-china.com \
    && bundle config --local frozen 'true' \
    && bundle config --local no-cache 'true' \
    && bundle config --local without 'development test' \
    && bundle install -j "$(getconf _NPROCESSORS_ONLN)" \
    && find ${APP_ROOT}/vendor/bundle -type f -name '*.c' -delete \
    && find ${APP_ROOT}/vendor/bundle -type f -name '*.h' -delete \
    && find ${APP_ROOT}/vendor/bundle -type f -name '*.o' -delete \
    && find ${APP_ROOT}/vendor/bundle -type f -name '*.gem' -delete

RUN bundle exec bootsnap precompile --gemfile app/ lib/

FROM ruby:${RUBY_VERSION}-alpine
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
ARG APP_ROOT

RUN apk add --no-cache shared-mime-info tzdata sqlite-libs

COPY --from=base /usr/local/bundle/config /usr/local/bundle/config
COPY --from=base /usr/local/bundle /usr/local/bundle
COPY --from=base ${APP_ROOT}/vendor/bundle ${APP_ROOT}/vendor/bundle
COPY --from=base ${APP_ROOT}/tmp/cache ${APP_ROOT}/tmp/cache

RUN mkdir -p ${APP_ROOT}

ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=yes
ENV APP_ROOT=$APP_ROOT

COPY . ${APP_ROOT}

# Apply Execute Permission
RUN adduser -h ${APP_ROOT} -D -s /bin/nologin ruby ruby && \
    chown ruby:ruby ${APP_ROOT} && \
    chown -R ruby:ruby ${APP_ROOT}/log && \
    chown -R ruby:ruby ${APP_ROOT}/tmp && \
    chmod -R +r ${APP_ROOT}

USER ruby
WORKDIR ${APP_ROOT}

EXPOSE 3000
ENTRYPOINT ["bin/rails"]
CMD ["server", "-b", "0.0.0.0"]
