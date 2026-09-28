from pathlib import Path
from xml.sax.saxutils import escape
import argparse
import json
import re

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description='Build the public development source or a locally configured distribution.')
parser.add_argument('--deployment-config', type=Path, help='Local JSON with applicationId and assetIds; never a token or secret.')
args = parser.parse_args()
deployment = None
if args.deployment_config:
    deployment = json.loads(args.deployment_config.read_text(encoding='utf-8'))
    if set(deployment) != {'applicationId', 'assetIds'}:
        raise ValueError('Deployment config accepts only applicationId and assetIds.')
    if not isinstance(deployment['applicationId'], str) or not re.fullmatch(r'\d{17,20}', deployment['applicationId']):
        raise ValueError('applicationId must be a public numeric application identifier.')
    expected = json.loads((ROOT/'assets/icons/discord-assets.json').read_text(encoding='utf-8'))
    if not isinstance(deployment['assetIds'], dict) or set(deployment['assetIds']) != set(expected):
        raise ValueError('assetIds must provide every activity and brand key.')
    if any(not isinstance(v, str) or not re.fullmatch(r'\d{17,20}', v) for v in deployment['assetIds'].values()):
        raise ValueError('assetIds must contain public numeric artwork identifiers.')
OUT = ROOT / ('.local/dist' if deployment else 'dist')
OUT.mkdir(parents=True, exist_ok=True)
PLUGIN = ROOT / 'plugin'
PLUGIN.mkdir(exist_ok=True)
modules = ['Config','Modes','Session','Activity','Api','Diagnostics','Controller','QRCode','Profiles','ProfileEditor','ActionIcons','UI','Panel','App']
version = re.search(r'Version\s*=\s*"([^"]+)"', (ROOT/'src/Config.luau').read_text(encoding='utf-8')).group(1)
chunks = [f'-- StudioSignal {version}. Generated from src/.\n' + 'local factories,cache={},{}\nlocal function requireModule(name)\n if cache[name]==nil then cache[name]=factories[name]() end\n return cache[name]\nend\n']
for name in modules:
    source = (ROOT/'src'/f'{name}.luau').read_text(encoding='utf-8')
    if deployment and name == 'Config':
        source = source.replace('ApplicationId = ""', 'ApplicationId = "' + deployment['applicationId'] + '"')
    if deployment and name == 'Modes':
        for key, asset_id in deployment['assetIds'].items():
            source = source.replace('"' + key.upper() + '_ASSET_ID"', '"' + asset_id + '"')
    for dependency in modules:
        source = source.replace(f'require(script.Parent.{dependency})', f'requireModule("{dependency}")')
    chunks.append(f'factories["{name}"]=function()\n{source}\nend\n')
library = ''.join(chunks)
(OUT/'bundle-library.luau').write_text(library,encoding='utf-8')
entry = library + '\nrequireModule("App").start(plugin)\n'
(OUT/'StudioSignal.luau').write_text(entry,encoding='utf-8')
xml = '<roblox version="4"><Item class="Script" referent="RBX0"><Properties><string name="Name">StudioSignal</string><bool name="Disabled">false</bool><ProtectedString name="Source">'+escape(entry)+'</ProtectedString></Properties></Item></roblox>'
(OUT/f'StudioSignal-{version}.rbxmx').write_text(xml,encoding='utf-8')
if not deployment:
    (PLUGIN/'StudioSignal.luau').write_text(entry,encoding='utf-8')
(OUT/'preview-loader.luau').write_text(library + '\nreturn requireModule("App")\n',encoding='utf-8')
print(json.dumps({'output':str(OUT),'modules':len(modules),'bytes':len(entry.encode())}))

(OUT/'test-bundle.luau').write_text(library + '\n' + (ROOT/'tests/core.luau').read_text(encoding='utf-8'), encoding='utf-8')
(OUT/'ui-test-bundle.luau').write_text(library + '\n' + (ROOT/'tests/ui.luau').read_text(encoding='utf-8'), encoding='utf-8')
