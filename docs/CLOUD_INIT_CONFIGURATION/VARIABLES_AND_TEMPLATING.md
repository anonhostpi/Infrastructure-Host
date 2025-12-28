# 5.4 Cloud-init Variables and Templating

Cloud-init supports Jinja2 templating for dynamic configurations.

## Basic Templating

```yaml
#cloud-config
hostname: host-{{ ds.meta_data.instance_id }}

runcmd:
  - echo "Instance ID: {{ ds.meta_data.instance_id }}" > /etc/instance-info
  - echo "Local IPv4: {{ ds.meta_data.local_ipv4 }}" >> /etc/instance-info
```

## Available Variables

| Variable | Description |
|----------|-------------|
| `ds.meta_data.instance_id` | Instance ID from meta-data |
| `ds.meta_data.local_hostname` | Local hostname from meta-data |
| `ds.meta_data.local_ipv4` | Local IPv4 address |
| `v1.instance_id` | Instance ID |
| `v1.local_hostname` | Local hostname |
| `v1.region` | Region (cloud-specific) |

## Conditional Configuration

```yaml
#cloud-config
{% if ds.meta_data.instance_id.startswith('prod') %}
packages:
  - monitoring-agent
  - security-tools
{% else %}
packages:
  - debug-tools
{% endif %}
```

## Loops

```yaml
#cloud-config
write_files:
{% for i in range(3) %}
  - path: /etc/config/file{{ i }}.conf
    content: "Configuration file {{ i }}"
{% endfor %}
```

## Environment-Based Configuration

Define variables in meta-data:

```yaml
# meta-data
instance-id: prod-web-01
local-hostname: prod-web-01
environment: production
role: webserver
```

Reference in user-data:

```yaml
#cloud-config
hostname: {{ ds.meta_data.local_hostname }}

runcmd:
  - echo "Environment: {{ ds.meta_data.environment }}" >> /etc/server-info
  - echo "Role: {{ ds.meta_data.role }}" >> /etc/server-info
```

## Template Validation

Test your templates before deployment:

```bash
# Validate cloud-init syntax
cloud-init schema --config-file user-data

# Render template (on a system with cloud-init)
cloud-init query --format "$(cat user-data)"
```
