cat <<EOF | kubectl apply -f -
apiVersion: fluentbit.fluent.io/v1alpha2
kind: FluentBit
metadata:
  name: fluent-bit
  namespace: fluent
  labels:
    app.kubernetes.io/name: fluent-bit
spec:
  image: kubesphere/fluent-bit:v1.8.11
  positionDB:
    hostPath:
      path: /var/lib/fluent-bit/
  resources:
    requests:
      cpu: 10m
      memory: 25Mi
    limits:
      cpu: 500m
      memory: 200Mi
  fluentBitConfigName: fluent-bit-only-config
  tolerations:
    - operator: Exists
---
apiVersion: fluentbit.fluent.io/v1alpha2
kind: ClusterFluentBitConfig
metadata:
  name: fluent-bit-only-config
  labels:
    app.kubernetes.io/name: fluent-bit
spec:
  service:
    parsersFile: parsers.conf
  inputSelector:
    matchLabels:
      fluentbit.fluent.io/enabled: "true"
      fluentbit.fluent.io/mode: "fluentbit-only"
  filterSelector:
    matchLabels:
      fluentbit.fluent.io/enabled: "true"
      fluentbit.fluent.io/mode: "fluentbit-only"
  outputSelector:
    matchLabels:
      fluentbit.fluent.io/enabled: "true"
      fluentbit.fluent.io/mode: "fluentbit-only"
---
apiVersion: fluentbit.fluent.io/v1alpha2
kind: ClusterInput
metadata:
  name: kubelet
  labels:
    fluentbit.fluent.io/enabled: "true"
    fluentbit.fluent.io/mode: "fluentbit-only"
spec:
  systemd:
    tag: service.kubelet
    path: /var/log/journal
    db: /fluent-bit/tail/kubelet.db
    dbSync: Normal
    systemdFilter:
      - _SYSTEMD_UNIT=kubelet.service
---
apiVersion: fluentbit.fluent.io/v1alpha2
kind: ClusterFilter
metadata:
  name: systemd
  labels:
    fluentbit.fluent.io/enabled: "true"
    fluentbit.fluent.io/mode: "fluentbit-only"
spec:
  match: service.*
  filters:
  - lua:
      script:
        key: systemd.lua
        name: fluent-bit-lua
      call: add_time
      timeAsTable: true
---
apiVersion: v1
data:
  systemd.lua: |
    function add_time(tag, timestamp, record)
      new_record = {}
      timeStr = os.date("!*t", timestamp["sec"])
      t = string.format("%4d-%02d-%02dT%02d:%02d:%02d.%sZ", timeStr["year"], timeStr["month"], timeStr["day"], timeStr["hour"], timeStr["min"], timeStr["sec"], timestamp["nsec"])
      kubernetes = {}
      kubernetes["pod_name"] = record["_HOSTNAME"]
      kubernetes["container_name"] = record["SYSLOG_IDENTIFIER"]
      kubernetes["namespace_name"] = "kube-system"
      new_record["time"] = t
      new_record["log"] = record["MESSAGE"]
      new_record["kubernetes"] = kubernetes
      return 1, timestamp, new_record
    end
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/component: operator
    app.kubernetes.io/name: fluent-bit-lua
  name: fluent-bit-lua
  namespace: fluent
---
apiVersion: fluentbit.fluent.io/v1alpha2
kind: ClusterOutput
metadata:
  name: es
  labels:
    fluentbit.fluent.io/enabled: "true"
    fluentbit.fluent.io/mode: "fluentbit-only"
spec:
  matchRegex: (?:kube|service)\.(.*)
  es:
    host: elasticsearch-master.elastic.svc
    port: 9200
    generateID: true
    logstashPrefix: fluent-log-fb-only
    logstashFormat: true
    timeKey: "@timestamp"
EOF
