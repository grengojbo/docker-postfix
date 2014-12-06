FROM ubuntu-debootstrap:14.04
MAINTAINER      Oleg Dolya "oleg.dolya@gmail.com"

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND noninteractive

RUN mkdir -p /etc/opendkim
RUN mkdir -p /etc/supervisor/conf.d/

# Update
RUN apt-get update && apt-get install -y curl net-tools sudo

# Start editing
# Install package here for cache
RUN apt-get -y install supervisor postfix sasl2-bin opendkim opendkim-tools

EXPOSE 25

# install confd
RUN curl -sSL -o /usr/local/bin/confd https://s3-us-west-2.amazonaws.com/opdemand/confd-git-b8e693c \
    && chmod +x /usr/local/bin/confd

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD postfix.sh /opt/postfix.sh
RUN chmod +x /opt/postfix.sh

# Add files
ADD assets/install.sh /opt/install.sh

# Run
CMD /opt/install.sh;/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
