"""Deep merge utilities for cloud-init fragment composition."""


def deep_merge(base, override):
    """
    Deep merge override into base.
    - Dicts are recursively merged
    - Lists are extended (override appended to base)
    - Scalars are replaced by override
    """
    if not isinstance(base, dict) or not isinstance(override, dict):
        return override

    result = base.copy()
    for key, value in override.items():
        if key in result:
            if isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = deep_merge(result[key], value)
            elif isinstance(result[key], list) and isinstance(value, list):
                result[key] = result[key] + value
            else:
                result[key] = value
        else:
            result[key] = value

    return result
