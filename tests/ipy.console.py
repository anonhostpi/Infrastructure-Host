"""Test builder package under IronPython console (ipy.bat).

Usage:
    cd <repo-root>
    ipy tests/ipy.console.py

Requires:
    - IronPython 3.4.2+ on PATH (ipy.bat)
    - ruamel.yaml installed: ipy -m pip install ruamel.yaml==0.16.13
    - Jinja2 installed:      ipy -m pip install Jinja2==2.10.3 MarkupSafe==1.1.1
    - Jinja2 lexer.py patched for .NET regex (see ipy.Jinja repo)
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
        mod = __import__('builder.' + name, fromlist=[name])
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
