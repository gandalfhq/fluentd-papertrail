FROM fluent/fluentd:latest
MAINTAINER Alex Robson <arobson@gmail.com>
WORKDIR /home/fluent
ENV PATH /home/fluent/.gem/ruby/2.3.0/bin:$PATH

# cutomize following "gem install fluent-plugin-..." line as you wish

USER root
RUN apk --no-cache --update add sudo build-base ruby-dev && \
    # sudo -u fluent gem install --no-document fluent-plugin-kubernetes_metadata_filter -v 0.25.3 && \
    sudo -u fluent gem install --no-document fluent-plugin-remote_syslog && \
    rm -rf /home/fluent/.gem/ruby/2.3.0/cache/*.gem && sudo -u fluent gem sources -c && \
    apk del sudo build-base ruby-dev && rm -rf /var/cache/apk/*

EXPOSE 24284

USER fluent
CMD exec fluentd -c /fluentd/etc/fluent.conf -p /fluentd/plugins $FLUENTD_OPT