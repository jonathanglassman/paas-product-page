FROM ruby:2.5-alpine

ENV RUNTIME_PACKAGES "git make"
ENV DEV_PACKAGES "gcc ruby-dev g++ zlib-dev libffi-dev"
COPY Gemfile /tmp/Gemfile
COPY .ruby-version /tmp/.ruby-version
COPY Gemfile.lock /tmp/Gemfile.lock
RUN apk add --update $RUNTIME_PACKAGES
RUN apk add $DEV_PACKAGES \
  && gem install bundler --no-document \
  && cd /tmp && bundle \
  && apk del $DEV_PACKAGES \
  && rm -rf /var/cache/apk/*
