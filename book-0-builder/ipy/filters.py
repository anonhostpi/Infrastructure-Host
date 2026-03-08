"""Custom Jinja2 filters for template rendering (IronPython-compatible)."""

import hashlib
import base64
import os

from ruamel.yaml import YAML as _YAML


def to_base64(value):
    """Encode string to base64."""
    return base64.b64encode(value.encode('utf-8')).decode('ascii')

def shell_quote(value):
    """Escape for shell single quotes."""
    return "'" + str(value).replace("'", "'\\''") + "'"

def shell_array(items):
    """Convert list to bash array literal."""
    return '(' + ' '.join(shell_quote(i) for i in items) + ')'
def ip_only(cidr_notation):
    """Extract IP from CIDR notation."""
    return str(cidr_notation).split('/')[0]

def cidr_only(cidr_notation):
    """Extract prefix from CIDR notation."""
    parts = str(cidr_notation).split('/')
    return parts[1] if len(parts) > 1 else '24'

def to_yaml(value):
    """Convert dict/list to YAML string using ruamel.yaml."""
    import io
    _y = _YAML()
    _y.default_flow_style = False
    buf = io.StringIO()
    _y.dump(value, buf)
    return buf.getvalue().rstrip()
def sha512_hash(password):
    """Generate SHA-512 password hash for /etc/shadow (cross-platform)."""
    salt_bytes = os.urandom(16)
    salt = base64.b64encode(salt_bytes, altchars=b'./').decode('ascii')[:16]
    rounds = 5000
    hash_result = _sha512_crypt(password, salt, rounds)
    return '$6$rounds=' + str(rounds) + '$' + salt + '$' + hash_result


def _sha512_crypt(password, salt, rounds):
    """Implement SHA-512 crypt algorithm (glibc compatible)."""
    password = password.encode('utf-8')
    salt = salt.encode('utf-8')
    b = hashlib.sha512(password + salt + password).digest()
    a_ctx = hashlib.sha512()
    a_ctx.update(password + salt)
    pwd_len = len(password)
    i = pwd_len
    while i > 64:
        a_ctx.update(b)
        i -= 64
    a_ctx.update(b[:i])
    i = pwd_len
    while i > 0:
        if i & 1: a_ctx.update(b)
        else: a_ctx.update(password)
        i >>= 1
    a = a_ctx.digest()
    dp_ctx = hashlib.sha512()
    for _ in range(pwd_len):
        dp_ctx.update(password)
    dp = dp_ctx.digest()
    p = b''
    i = pwd_len
    while i > 64:
        p += dp
        i -= 64
    p += dp[:i]
    pass  # WIP: ds/main loop
