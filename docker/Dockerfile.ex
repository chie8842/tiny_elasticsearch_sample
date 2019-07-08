FROM ubuntu:18.04
MAINTAINER Chie HAYASHIDA <chie8842@gmail.com>

# apt-get
ENV DEBIAN_FRONTEND=noninteractive
ARG RUBY_PATH=/usr/local
ARG RUBY_VERSION=2.5.1
RUN apt-get update && apt-get install -y \
  git \
  vim \
  wget \
  curl \
  openjdk-11-jdk \
  python3.6-minimal \
  python3-pip \
  rbenv ruby-build ruby-dev \
  postgresql \
  language-pack-ja-base \
  language-pack-ja \
  libpq-dev \
  swig \
  cmake \
  sudo \
  systemd \
  libboost-all-dev libgsl0-dev libeigen3-dev

# Install Ruby
RUN git clone git://github.com/rbenv/ruby-build.git $RUBY_PATH/plugins/ruby-build \
&&  $RUBY_PATH/plugins/ruby-build/install.sh
RUN ruby-build $RUBY_VERSION $RUBY_PATH

# Install python package
RUN python3 -m pip install --upgrade pip
COPY requirements.txt /requirements.txt
RUN pip3 install -r requirements.txt
RUN pip3 install awscli

# Install ElasticSearch
RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
RUN sudo apt install apt-transport-https
RUN echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
RUN sudo apt update && apt install elasticsearch

RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-kuromoji
RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install org.codelibs:elasticsearch-analysis-kuromoji-ipadic-neologd:7.1.0

# settings
ARG user_name=ubuntu
ARG user_id=1000
ARG group_name=ubuntu
ARG group_id=1000

# create user
RUN groupadd -g ${group_id} ${group_name} \
  && \
    useradd -u ${user_id} -g ${group_id} -d /home/${user_name} --create-home --shell /bin/bash ${user_name} \
  && \
    echo "${user_name} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
  && \
    chown -R ${user_name}:${group_name} /home/${user_name}

# user settings
USER ubuntu
WORKDIR /work
ENV HOME /home/ubuntu
ENV LANG="ja_JP.UTF-8" \
    LANGUAGE="ja_JP:ja" \
    LC_ALL="ja_JP.UTF-8"

# Ruby setting
RUN rbenv install 2.6.3
RUN echo 'eval "$(rbenv init -)"' >> ~/.bashrc
RUN rbenv init - && rbenv global 2.6.3 && . ~/.bashrc && rbenv exec gem install bundler

# Set alias for python3.5
RUN echo "alias python=python3" >> $HOME/.bashrc && \
  echo "alias pip=pip3" >> $HOME/.bashrc

WORKDIR /work
CMD /bin/bash

