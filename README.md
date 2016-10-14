## fluentd papertrail
This makes use of the following fluentd plugins:

 * remote-syslog
 * kubernetes-metadata

I'm presently using this image to power a daemonset in our kubernetes cluster. Here is a sample of the yml manifest that defines it:

```yml
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  namespace: ...
  name: ...
spec:
  template:
    metadata:
      labels:
        app: ...
      name: ...
    spec:
      containers:
      - image: arobson/fluentd-papertrail
        resources:
          limits:
            memory: 200m
        imagePullPolicy: Always
        name: ...
        volumeMounts:
          - name: config
            mountPath: /etc/fluent
          - name: varlog
            mountPath: /var/log
          - name: varlibdockercontainers
            mountPath: /var/lib/docker/containers
            readOnly: true
      volumes:
        - name: config
          configMap:
            name: papertrail-config
            items:
              - key: fluentd.conf
                path: fluentd.conf
        - name: varlog
          hostPath:
            path: /var/log
        - name: varlibdockercontainers
          hostPath:
            path: /var/lib/docker/containers

```

Define a configmap named `papertrail-config` containing the file `fluent.conf` to control how you collect, filter and send docker log entries to papertrail.

```bash
<source>
  type tail
  read_from_head true
  path /var/lib/docker/containers/*/*-json.log
  pos_file /var/log/fluentd-docker.pos
  time_format %Y-%m-%dT%H:%M:%S
  tag docker.*
</source>

# Using filter to add container IDs to each event
<filter docker.var.lib.docker.containers.*.*.log>
  type record_transformer
  <record>
    container_id ${tag_parts[5]}
  </record>
</filter>

<match docker.var.lib.docker.containers.*.*.log>
  type remote_syslog
  host ...
  port ...
  tag fluentd
  severity debug
  flush_interval 5s
</match>
```