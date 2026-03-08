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
    ds_ctx = hashlib.sha512()
    for _ in range(16 + a[0]):
        ds_ctx.update(salt)
    ds = ds_ctx.digest()
    s = b''
    i = len(salt)
    while i > 64:
        s += ds
        i -= 64
    s += ds[:i]

    c = a
    for i in range(rounds):
        ctx = hashlib.sha512()
        if i & 1: ctx.update(p)
        else: ctx.update(c)
        if i % 3: ctx.update(s)
        if i % 7: ctx.update(p)
        if i & 1: ctx.update(c)
        else: ctx.update(p)
        c = ctx.digest()

    b64chars = './0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    result = ''
    order = [
        (0, 21, 42), (22, 43, 1), (44, 2, 23), (3, 24, 45), (25, 46, 4),
        (47, 5, 26), (6, 27, 48), (28, 49, 7), (50, 8, 29), (9, 30, 51),
        (31, 52, 10), (53, 11, 32), (12, 33, 54), (34, 55, 13), (56, 14, 35),
        (15, 36, 57), (37, 58, 16), (59, 17, 38), (18, 39, 60), (40, 61, 19),
        (62, 20, 41), (63,)
    ]
    for triplet in order:
        if len(triplet) == 3:
            v = c[triplet[0]] << 16 | c[triplet[1]] << 8 | c[triplet[2]]
            for _ in range(4):
                result += b64chars[v & 0x3f]
                v >>= 6
        else:
            v = c[triplet[0]]
            result += b64chars[v & 0x3f]
            result += b64chars[(v >> 6) & 0x3f]

    return result
