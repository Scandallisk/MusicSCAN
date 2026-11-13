"""Regenerate theme views from the tracked catalog and reviewed rules; offline only."""
import argparse,csv,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--check',action='store_true')
args=parser.parse_args()
rules=json.loads((ROOT/'tools/theme-rules.json').read_text(encoding='utf-8'))
with (ROOT/'catalog/CATALOG.csv').open(encoding='utf-8',newline='') as f: rows=list(csv.DictReader(f))
members={name:[] for name in rules}
audit=[]
for row in rows:
    for name,rule in rules.items():
        matched=[token for token in rule['tokens'] if token in row['sourceFilename'].lower()]
        if row['zone'] in rule['zones'] or matched:
            members[name].append(row['key'])
            audit.append(dict(theme=name,key=row['key'],fileDataID=row['fileDataID'],title=row['title'],zone=row['zone'],reason='zone:'+row['zone'] if row['zone'] in rule['zones'] else 'filename:'+matched[0]))
text='-- Generated theme views; IDs and underlying catalog records are unchanged.\nlocal _, ns = ...\nns.ThemeOrder = '+ '{'+','.join(json.dumps(x) for x in rules)+'}\nns.ThemeKeys = {\n'
for name,keys in members.items():
    assert len(keys)==len(set(keys))
    text+='    ['+json.dumps(name)+'] = {\n'+''.join('        ['+json.dumps(k)+'] = true,\n' for k in keys)+'    },\n'
text+='}\n'
path=ROOT/'MusicSCAN/Themes.lua'
if args.check:
    assert path.read_text(encoding='utf-8')==text, 'Themes.lua differs from reviewed inputs'
else:
    path.write_text(text,encoding='utf-8')
    with (ROOT/'catalog/THEME-AUDIT.csv').open('w',newline='',encoding='utf-8') as f:
        writer=csv.DictWriter(f,fieldnames=list(audit[0]));writer.writeheader();writer.writerows(audit)
print('Theme views verified:',{name:len(keys) for name,keys in members.items()})
