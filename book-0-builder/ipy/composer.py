"""Deep merge utilities for cloud-init fragment composition."""


def deep_merge(base, override):
    """
    Deep merge override into base.
    - Dicts are recursively merged
    - Lists are extended (override appended to base)
    - Scalars are replaced by override
    """
    pass  # WIP
