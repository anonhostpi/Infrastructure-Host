# 6.5 System Settings Fragment

**Template:** `src/autoinstall/cloud-init/40-system.yaml.tpl`

Configures system-wide settings like timezone.

## Template

```yaml
timezone: America/Phoenix
```

## Configuration Fields

| Field | Value | Description |
|-------|-------|-------------|
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
- **Locale** - If different from autoinstall defaults
- **Keyboard** - If different from autoinstall defaults

Currently, locale and keyboard are set in autoinstall (see [5.2 Autoinstall Configuration](../AUTOINSTALL_MEDIA_CREATION/AUTOINSTALL_CONFIGURATION.md)).
