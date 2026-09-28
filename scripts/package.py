"""Validate and package a locally generated StudioSignal build."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from xml.etree import ElementTree
import hashlib
import json
import re

root = Path(__file__).resolve().parents[1]
out = root / 'dist'
version = re.search(r'Version\s*=\s*"([^"]+)"', (root/'src/Config.luau').read_text(encoding='utf-8')).group(1)
model = out / f'StudioSignal-{version}.rbxmx'
doc = ElementTree.parse(model)
assert len(doc.findall('./Item')) == 1
assert doc.find('./Item').attrib['class'] == 'Script'
source = doc.find('.//ProtectedString').text
assert source == (out / 'StudioSignal.luau').read_text(encoding='utf-8')
assert source == (root / 'plugin/StudioSignal.luau').read_text(encoding='utf-8')

archive_path = out / f'StudioSignal-{version}.zip'
with ZipFile(archive_path, 'w', ZIP_DEFLATED) as archive:
    for folder in ('src', 'tests', 'scripts', 'assets', 'docs'):
        for path in sorted((root / folder).rglob('*')):
            if path.is_file() and '__pycache__' not in path.parts:
                archive.write(path, path.relative_to(root).as_posix())
    for name in ('README.md', 'LICENSE', 'CHANGELOG.md', 'stylua.toml'):
        archive.write(root / name, name)
    for name in ('StudioSignal.luau', model.name):
        archive.write(out / name, name)

hashes = {path.name: hashlib.sha256(path.read_bytes()).hexdigest()
          for path in (model, out / 'StudioSignal.luau', archive_path)}
(out / 'SHA256.json').write_text(json.dumps(hashes, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'xmlValid': True, 'embeddedSourceMatches': True, 'files': hashes}, indent=2))
