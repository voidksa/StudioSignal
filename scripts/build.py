from pathlib import Path
from xml.sax.saxutils import escape
import json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'dist'
OUT.mkdir(parents=True, exist_ok=True)
PLUGIN = ROOT / 'plugin'
PLUGIN.mkdir(exist_ok=True)
modules = ['Config','Modes','Session','Activity','Api','Controller','UI','App']
chunks = ['-- StudioSignal v1.0. Generated from src/.\nlocal factories,cache={},{}\nlocal function requireModule(name)\n if cache[name]==nil then cache[name]=factories[name]() end\n return cache[name]\nend\n']
for name in modules:
    source = (ROOT/'src'/f'{name}.luau').read_text(encoding='utf-8')
    for dependency in modules:
        source = source.replace(f'require(script.Parent.{dependency})', f'requireModule("{dependency}")')
    chunks.append(f'factories["{name}"]=function()\n{source}\nend\n')
library = ''.join(chunks)
(OUT/'bundle-library.luau').write_text(library,encoding='utf-8')
entry = library + '\nrequireModule("App").start(plugin)\n'
(OUT/'StudioSignal.luau').write_text(entry,encoding='utf-8')
xml = '<roblox version="4"><Item class="Script" referent="RBX0"><Properties><string name="Name">StudioSignal</string><bool name="Disabled">false</bool><ProtectedString name="Source">'+escape(entry)+'</ProtectedString></Properties></Item></roblox>'
(OUT/'StudioSignal-v1.0.rbxmx').write_text(xml,encoding='utf-8')
(PLUGIN/'StudioSignal.luau').write_text(entry,encoding='utf-8')
(OUT/'preview-loader.luau').write_text(library + '\nreturn requireModule("App")\n',encoding='utf-8')
print(json.dumps({'output':str(OUT),'modules':len(modules),'bytes':len(entry.encode())}))

(OUT/'test-bundle.luau').write_text(library + '\n' + (ROOT/'tests/core.luau').read_text(encoding='utf-8'), encoding='utf-8')
