# 6.6 System Settings Fragment

**Template:** `src/autoinstall/cloud-init/40-system.yaml.tpl`

Configures system-wide settings: locale, keyboard, and timezone.

## Template

```yaml
locale: en_US.UTF-8

keyboard:
  layout: us

timezone: America/Phoenix
```

## Configuration Fields

| Field | Value | Description |
|-------|-------|-------------|
| `locale` | en_US.UTF-8 | American English, UTF-8 encoding |
| `keyboard.layout` | us | Standard American QWERTY |
| `timezone` | America/Phoenix | System timezone |

## Timezone

The timezone is set to `America/Phoenix` (MST, no daylight saving time).

To use a different timezone, modify the template or override via environment variable:

```bash
export AUTOINSTALL_SYSTEM_TIMEZONE="America/New_York"
make cloud-init
```

See [3.1 BuildContext](../BUILD_SYSTEM/BUILD_CONTEXT.md) for environment variable overrides.

## Available Timezones

List available timezones:

```bash
timedatectl list-timezones
```

Common options:
- `America/New_York` - Eastern
- `America/Chicago` - Central
- `America/Denver` - Mountain
- `America/Los_Angeles` - Pacific
- `UTC` - Coordinated Universal Time

## Future Considerations

This fragment may be extended to include:

- **NTP/chrony** - Time synchronization configuration
