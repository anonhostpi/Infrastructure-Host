"""Custom Jinja2 filters for template rendering."""

import crypt
import yaml


def shell_quote(value):
    """Escape for shell single quotes."""
    return "'" + str(value).replace("'", "'\\''") + "'"


def shell_array(items):
    """Convert list to bash array literal."""
    return '(' + ' '.join(shell_quote(i) for i in items) + ')'


def sha512_hash(password):
    """Generate SHA-512 password hash for /etc/shadow."""
    salt = crypt.mksalt(crypt.METHOD_SHA512)
    return crypt.crypt(password, salt)


def ip_only(cidr_notation):
    """Extract IP from CIDR notation: 192.168.1.1/24 -> 192.168.1.1"""
    return str(cidr_notation).split('/')[0]


def cidr_only(cidr_notation):
    """Extract prefix from CIDR notation: 192.168.1.1/24 -> 24"""
    parts = str(cidr_notation).split('/')
    return parts[1] if len(parts) > 1 else '24'


def to_yaml(value):
    """Convert dict/list to YAML string."""
    return yaml.dump(value, default_flow_style=False, allow_unicode=True).rstrip()
