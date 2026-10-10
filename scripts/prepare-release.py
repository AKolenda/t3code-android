#!/usr/bin/env python3
"""Set the Android version after Expo prebuild."""
import json
import os
from pathlib import Path
import re
import time

source = Path(os.environ.get('SOURCE_DIR', 'source'))
code = int(time.time() // 60)
path = source / 'apps/mobile/android/app/build.gradle'
text = path.read_text()
base = re.search(r'versionName "([^"]+)"', text).group(1)
version = f'{base}.{code}'
text, count = re.subn(r'versionCode \d+', f'versionCode {code}', text)
assert count == 1
text, count = re.subn(r'versionName "[^"]+"', f'versionName "{version}"', text)
assert count == 1
assert "applicationId 'com.t3tools.t3code'" in text
path.write_text(text)
Path('release-version.json').write_text(json.dumps({'version': version, 'versionCode': code, 'package': 'com.t3tools.t3code'}, indent=2) + '\n')
if os.environ.get('GITHUB_OUTPUT'):
    with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
        output.write(f'version={version}\ntag=v{version}\n')
print(version)
