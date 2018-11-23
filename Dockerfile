FROM scardon/ruby-node-alpine:2.5

RUN apk add --update --no-cache \
  git \
  build-base \
  postgresql-client postgresql-dev \
  libxml2 libxslt libxml2-dev libxslt-dev \
  && rm -rf /var/cache/apk/*

RUN mkdir /WebsiteOne
WORKDIR /WebsiteOne

COPY . /WebsiteOne

RUN bundle install

COPY vendor/assets/javascripts /WebsiteOne/assets/javascripts

RUN npm install --unsafe-perm
RUN npm install -g phantomjs-prebuilt --unsafe-perm

