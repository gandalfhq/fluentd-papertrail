## fluentd papertrail
This makes use of the following fluentd plugins:

 * remote-syslog
 * record-reformer
 * kubernetes_metadata_filter

I'm presently using this image to power a daemonset in our kubernetes cluster. Here is a sample of the yml manifest that defines it:

```yml
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  namespace: infrastructure
  name: papertrailer
spec:
  template:
    metadata:
      labels:
        app: papertrail
      name: papertrailer
    spec:
      containers:
      - image: arobson/fluentd-papertrail
        resources:
          limits:
            memory: 200Mi
        imagePullPolicy: Always
        name: papertrailer
        volumeMounts:
          - name: config
            mountPath: /fluentd/etc
          - name: varlog
            mountPath: /var/log
          - name: varlogcontainers
            mountPath: /var/log/containers
            readOnly: true
      volumes:
        - name: config
          configMap:
            name: papertrail-config
            items:
              - key: fluent.conf
                path: fluent.conf
        - name: varlog
          hostPath:
            path: /var/log
        - name: varlogcontainers
          hostPath:
            path: /var/log/containers
```

Define a configmap named `papertrail-config` containing the file `fluent.conf` to control how you collect, filter and send docker log entries to papertrail.

```bash
#<source>
#  type tail
#  format json
#  time_key time
#  read_from_head true
#  path /var/lib/docker/containers/*/*-json.log
#  pos_file /var/log/fluentd-docker.pos
#  time_format %Y-%m-%dT%H:%M:%S
#  tag docker.*
#</source>

<source>
  type tail
  format json
  time_key time
  read_from_head true
  path /var/log/containers/*-json.log
  pos_file /var/log/fluentd-docker.pos
  time_format %Y-%m-%dT%H:%M:%S
  tag reform.*
</source>

<match reform.**>
  type record_reformer
  enable_ruby true
  tag k8s.${tag_suffix[4].split('-')[0..-2].join('-')}
</match>

<match fluent.**>
  type null
</match>

#<match docker.var.lib.docker.containers.*.*.log>
<match k8s.**>
  type remote_syslog
  host logs4.papertrailapp.com
  port 53581
  tag fluentd
  severity debug
  flush_interval 5s
</match>

```