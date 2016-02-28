FROM ubuntu:14.04

RUN     /usr/sbin/locale-gen en_US.UTF-8
ENV     LANG en_US.UTF-8
# This stops apt from presenting interactive prompts when installing apps that
# would normally ask for them. Alternatively, check out debconf-set-selections.
ENV DEBIAN_FRONTEND=noninteractive

# groff is needed by the awscli pip package.
# rsync is needed by knife.
# zlib1g-dev is needed by the gem dependency chain.
RUN apt-get update && apt-get --yes --quiet install \
bundler \
groff \
python \
python-dev \
python-pip \
python-virtualenv \
rsync \
ssh \
vim \
git \
zlib1g-dev

RUN apt-get install -y --force-yes build-essential curl git
RUN apt-get install -y --force-yes zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev
RUN apt-get clean

RUN git clone https://github.com/sstephenson/rbenv.git /root/.rbenv
RUN git clone https://github.com/sstephenson/ruby-build.git /root/.rbenv/plugins/ruby-build
RUN ./root/.rbenv/plugins/ruby-build/install.sh
ENV PATH /root/.rbenv/bin:/root/.rbenv/shims:$PATH
RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh # or /etc/profile

# Install multiple versions of ruby
ENV CONFIGURE_OPTS --disable-install-doc
ADD ./versions.txt /root/versions.txt
RUN xargs -L 1 rbenv install < /root/versions.txt

# Install Bundler for each version of ruby
RUN echo 'gem: --no-rdoc --no-ri' >> /.gemrc
RUN bash -l -c 'for v in $(cat /root/versions.txt); do rbenv global $v; gem install bundler; done'

RUN mkdir -p /project/askii_deployment
WORKDIR /project/askii_deployment

# Install ruby gems
RUN echo $PATH
RUN ruby -v
ADD ./Gemfile Gemfile
RUN bundle install

# Install Python project to a virtualenv that will activate when we log in.
ADD ./requirements.txt requirements.txt
RUN virtualenv /project/env
RUN echo "source /project/env/bin/activate" > ~/.bashrc

RUN /project/env/bin/pip --quiet install --requirement requirements.txt
