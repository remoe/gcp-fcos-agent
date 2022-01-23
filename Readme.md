# Description

This is a minimal version of Google Metrics Collector tested with Fedora Core OS. It allows to show the following in GCP metrics console:

- Memory Utilization
- Disk Space Utilization

And the GCP dashboard shows "OPS Agent" installed :)

It is based on https://github.com/GoogleCloudPlatform/opentelemetry-operations-collector

# Requirements

## GCP account 

```yaml
files:
  - path: /etc/gcp-fcos-agent/gcp-account
    mode: 0400
    contents:
      inline: |
        GOOGLE_CLOUD_PROJECT=[your project]
        GOOGLE_APPLICATION_CREDENTIALS=/etc/gcp-fcos-agent/google-service-account-metrics.json
```

## GCP metrics service account

Partial sample:
```yaml
files:
  - path: /etc/gcp-fcos-agent/google-service-account-metrics.json
    mode: 0400
    contents:
      inline: |
        {
          "type": "service_account",
          ...
        }
```

## OpenTelemetry configuration

This can be generated with https://github.com/GoogleCloudPlatform/ops-agent

```
google_cloud_ops_agent_engine -service=otel -in /etc/google-cloud-ops-agent/config.yaml
```

/etc/google-cloud-ops-agent/config.yaml:

```yaml
logging:
  receivers:
    syslog:
      type: systemd_journald
  service:
    pipelines:
      default_pipeline:
        receivers: [syslog]
metrics:
  receivers:
    hostmetrics:
      type: hostmetrics
      collection_interval: 60s
  processors:
    metrics_filter:
      type: exclude_metrics
      metrics_pattern: []
  service:
    pipelines:
      default_pipeline:
        receivers: [hostmetrics]
        processors: [metrics_filter]
```

Partial OpenTelemetry sample:

```yaml
files:
  - path: /etc/gcp-fcos-agent/otelopscol/config.yaml
    mode: 0400
    contents:
      inline: |
        exporters:
          googlecloud:
            metric:
              prefix: ""
            user_agent: Google-Cloud-Ops-Agent-Metrics/2.8.2 (BuildDistro=fc35;Platform=linux;ShortName=fedora;ShortVersion=35)
        processors:
        ...
```

## Systemd Service

To run the OpenTelemetry collector one need to define a Systemd service:

```yaml
systemd:
  units:
    - name: gcp-opentelemetry-collector.service
      enabled: true
      contents: |
        [Unit]
        Description=GCP OpenTelemetry Collector
        Wants=network-online.target
        After=network-online.target
        [Service]
        EnvironmentFile=/etc/gcp-fcos-agent/gcp-account
        ExecStart=/usr/local/sbin/gcp-fcos-agent/otelopscol --config=/etc/gcp-fcos-agent/otelopscol/config.yaml
        [Install]
        WantedBy=multi-user.target  
```

# Build the OpenTelemetry collector

```
make docker-build-image
make TARGET=build-tarball-gh docker-run .
```
