"""Custom Jinja2 filters for template rendering (IronPython-compatible)."""

import hashlib
import base64
import os

from ruamel.yaml import YAML as _YAML


def to_base64(value): pass  # WIP
def shell_quote(value): pass  # WIP
def shell_array(items): pass  # WIP
def ip_only(cidr_notation): pass  # WIP
def cidr_only(cidr_notation): pass  # WIP
def to_yaml(value): pass  # WIP
def sha512_hash(password): pass  # WIP
def _sha512_crypt(password, salt, rounds): pass  # WIP
