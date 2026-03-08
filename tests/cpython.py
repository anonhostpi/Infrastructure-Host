"""Test ipy package under CPython.

Usage:
    cd <repo-root>
    python tests/cpython.py
"""
import sys
import os

sys.path.insert(0, 'book-0-builder')
repo_root = os.getcwd()

print('Python: ' + sys.version.split('\n')[0])
print('')

# Level 1: Imports
print('=== Level 1: Import Test ===')
modules = ['composer', 'filters', 'artifacts', 'context', 'renderer']
imported = {}
for name in modules:
    try:
        mod = __import__('ipy.' + name, fromlist=[name])
        imported[name] = mod
        print('  ' + name + ': OK')
    except Exception as e:
        print('  ' + name + ': FAIL - ' + str(e))

# Level 2: Discover fragments
print('')
print('=== Level 2: Discover Fragments ===')
try:
    renderer = imported['renderer']
    frags = renderer.discover_fragments(repo_root)
    print('  Found ' + str(len(frags)) + ' fragments')
    for f in frags:
        print('    - ' + str(f.get('name', '???')) + ' (order: ' + str(f.get('build_order', '???')) + ')')
except Exception as e:
    print('  FAIL: ' + str(e))

# Level 3: Create environment
print('')
print('=== Level 3: Create Environment ===')
try:
    env = renderer.create_environment(repo_root)
    custom = ['shell_quote', 'shell_array', 'sha512_hash', 'ip_only', 'cidr_only', 'to_yaml', 'to_base64']
    missing = [f for f in custom if f not in env.filters]
    if missing:
        print('  FAIL: Missing filters: ' + str(missing))
    else:
        print('  Jinja2 env created with all custom filters')
        print('  Search paths: ' + str(env.loader.searchpath))
except Exception as e:
    print('  FAIL: ' + str(e))

print('')
print('ALL TESTS COMPLETE')
