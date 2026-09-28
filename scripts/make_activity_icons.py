"""Generate the StudioSignal icon family and atlas."""
from pathlib import Path
import json
import cairosvg
from PIL import Image, ImageDraw, ImageFont

OUT=Path(__file__).resolve().parents[1]/'assets'/'icons'
OUT.mkdir(parents=True,exist_ok=True)
# All glyphs use a shared 128-unit grid, generous negative space and strong silhouettes.
icons=[
('building','Building','#a89cff','<path d="M64 25 97 44v39L64 103 31 83V44Z"/><path d="m31 44 33 20 33-20M64 64v39M48 35l33 20"/>'),
('scripting','Luau','#a89cff','<path d="m44 39-25 25 25 25m40-50 25 25-25 25M73 29 55 99"/>'),
('server','Server script','#ff998a','<rect x="28" y="25" width="72" height="32" rx="9"/><rect x="28" y="71" width="72" height="32" rx="9"/><path d="M45 41h1m14 0h22M45 87h1m14 0h22"/>'),
('client','Local script','#6ae5c1','<rect x="24" y="26" width="80" height="60" rx="10"/><path d="M49 103h30M64 86v17m-8-60-11 11 11 11m16-22 11 11-11 11"/>'),
('module','Module script','#6dcfff','<path d="M29 39h24V26h23v13h23v25H85v22h14v17H74V89H51v14H29V79h14V57H29Z"/>'),
('testing','Playtesting','#93ed92','<path d="M45 28q-8-5-8 5v62q0 10 8 5l54-32q7-4 0-8Z" fill="currentColor" stroke="none"/>'),
('terrain','Terrain','#79d9a3','<path d="m19 91 31-54 22 35 15-23 23 42Z"/><path d="m40 54 10 7 10-7M26 103h76"/>'),
('ui','Interface','#ec9deb','<rect x="22" y="26" width="84" height="76" rx="10"/><path d="M22 47h84M49 47v55M63 64h28M63 80h18"/>'),
('animation','Animation','#ffc478','<path d="m64 27 25 37-25 37-25-37Z"/><path d="M24 42v44M104 42v44"/>'),
('lighting','Lighting','#ffe18a','<circle cx="64" cy="64" r="23"/><path d="M64 17v9m0 76v9M17 64h9m76 0h9M31 31l7 7m52 52 7 7M31 97l7-7m52-52 7-7"/>'),
('audio','Audio','#8bdadf','<path d="M28 54v20m18-35v50m18-65v80m18-65v50m18-35v20"/>'),
('modeling','Modeling','#91b8ff','<path d="m26 78 22-43h36l22 43-42 26Z"/><path d="M26 78h80M48 35l16 69 20-69M48 35 26 78m58-43 22 43"/>'),
('debugging','Debugging','#ff9ca5','<rect x="42" y="42" width="44" height="56" rx="21"/><path d="m51 42-7-15m33 15 7-15M25 52l17 7m44 0 17-7M23 76h19m44 0h19M30 100l14-12m40 0 14 12M64 51v34"/>'),
('focus','Focus','#c5adff','<path d="M22 45V25h20m44 0h20v20M22 83v20h20m44 0h20V83"/><circle cx="64" cy="64" r="19"/><circle cx="64" cy="64" r="3" fill="currentColor"/>'),
('idle','Away','#adbbcf','<path d="M91 84A38 38 0 0 1 46 30a39 39 0 1 0 45 54Z" fill="currentColor" stroke="none"/>'),
('brand','StudioSignal','#d6a665','<path d="M41 24H101V43H49L44 48V55H80L100 75V87L82 105H27V86H74L80 80V75H43L24 56V42Z" fill="currentColor" stroke="none"/>'),
]

palette=['#d6b185','#e4dbc9','#cd9585','#a9bd97','#99b5bf','#aec393','#b0bc87','#c2afa1','#d4b287','#d7c283','#a4b9b3','#a6b0c0','#ca9b93','#dcc08e','#adaaa1','#d6a665']
icons=[(k,n,palette[i],g) for i,(k,n,c,g) in enumerate(icons)]

manifest=[]
atlas=Image.new('RGBA',(1024,1024),(0,0,0,0))
board=Image.new('RGB',(1280,1130),'#171817')
draw=ImageDraw.Draw(board)
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',22)
heading=ImageFont.truetype('C:/Windows/Fonts/seguisb.ttf',34)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',16)
draw.text((36,22),'StudioSignal / Activity icons',font=heading,fill='#f1f1fc')
draw.text((38,70),'Original vector family  |  16 distinct silhouettes  |  64 px and 24 px previews',font=small,fill='#aab3c9')
for i,(key,name,color,glyph) in enumerate(icons):
    svg=f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128"><rect width="128" height="128" rx="22" fill="#232421"/><g color="{color}" fill="none" stroke="currentColor" stroke-width="7" stroke-linejoin="round" stroke-linecap="round">{glyph}</g></svg>'''
    stem='ss2-'+key
    (OUT/(stem+'.svg')).write_text(svg,encoding='utf-8')
    cairosvg.svg2png(bytestring=svg.encode(),write_to=str(OUT/(stem+'.png')),output_width=1024,output_height=1024)
    icon=Image.open(OUT/(stem+'.png')).convert('RGBA')
    atlas.paste(icon.resize((256,256),Image.Resampling.LANCZOS),((i%4)*256,(i//4)*256))
    x=36+(i%4)*314;y=120+(i//4)*245
    draw.rounded_rectangle((x,y,x+290,y+221),radius=12,fill='#242521')
    board.paste(icon.resize((112,112),Image.Resampling.LANCZOS),(x+22,y+18),icon.resize((112,112),Image.Resampling.LANCZOS))
    for size,dx in [(64,164),(24,241)]:
        thumb=icon.resize((size,size),Image.Resampling.LANCZOS)
        board.paste(thumb,(x+dx,y+46),thumb)
    draw.text((x+22,y+151),name,font=font,fill='#f0f2fb')
    draw.text((x+22,y+184),stem,font=small,fill=color)
    manifest.append(dict(key=stem,label=name,color=color,index=i,file=stem+'.png'))
    if key=='brand':
        icon.save(OUT.parent/'StudioSignal-logo.png')
        (OUT.parent/'StudioSignal-logo.svg').write_text(svg,encoding='utf-8')
atlas.save(OUT/'StudioSignal-atlas.png')
board.save(OUT.parent/'StudioSignal-icon-family.png')
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print(json.dumps({'icons':len(icons),'folder':str(OUT),'atlas':'StudioSignal-atlas.png'}))
