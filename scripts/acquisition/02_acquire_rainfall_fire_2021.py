"""Complete one calendar year, reusing original monthly JD/CL pairs when present.

Default 2021; set UPEMBA_ILLUSTRATION_YEAR=2022 for the recorded second coverage
audit. Downloads and extracted rasters stay under the external data root.
"""
import urllib.request,json,pathlib,hashlib,gzip,tarfile,shutil,os,datetime
from concurrent.futures import ThreadPoolExecutor
root=pathlib.Path(os.environ.get('UPEMBA_DATA_ROOT','C:/0_Documents/Chapter_1'))
year=int(os.environ.get('UPEMBA_ILLUSTRATION_YEAR','2021'))
assert year in (2021,2022)
dest=root/'data'/f'rainfall_fire_{year}';dest.mkdir(parents=True,exist_ok=True)
meta=pathlib.Path('outputs/final_reconciliation/rainfall_fire');meta.mkdir(parents=True,exist_ok=True)
listing=json.load(urllib.request.urlopen(f'https://data.ceda.ac.uk/neodc/esacci/fire/data/burned_area/MODIS/pixel/v5.1/compressed/{year}/?json'))
jobs=[]
for item in listing['items']:
 if 'AREA_5' not in item['name']: continue
 stem=item['name'].removesuffix('.tar.gz')
 original=root/'data'/'fire'/stem
 reusable=all((original/(stem+'-'+layer+'.tif')).exists() for layer in ['JD','CL'])
 if not reusable: jobs.append((item['download'],dest/item['name'],'FireCCI51',item.get('md5')))
for month in range(1,13):
 name=f'chirps-v2.0.{year}.{month:02d}.tif.gz'
 jobs.append(('https://data.chc.ucsb.edu/products/CHIRPS-2.0/global_monthly/tifs/'+name,dest/name,'CHIRPS v2.0 final monthly',None))
def fetch(job):
 url,path,product,md5=job
 if not path.exists():
  tmp=path.with_suffix(path.suffix+'.partial')
  with urllib.request.urlopen(url,timeout=90) as r,open(tmp,'wb') as f: shutil.copyfileobj(r,f)
  tmp.replace(path)
 if md5 and hashlib.md5(path.read_bytes()).hexdigest().lstrip('0')!=md5.lstrip('0'): raise ValueError('MD5 mismatch '+str(path))
 if path.name.endswith('.tar.gz'):
  with tarfile.open(path) as t:
   for member in t.getmembers():
    if member.isfile() and member.name.endswith(('-JD.tif','-CL.tif','.xml')):
     target=dest/pathlib.Path(member.name).name
     if not target.exists():
      with t.extractfile(member) as src,open(target,'wb') as f: shutil.copyfileobj(src,f)
 else:
  target=path.with_suffix('')
  if not target.exists():
   with gzip.open(path,'rb') as src,open(target,'wb') as f: shutil.copyfileobj(src,f)
 print('ACQUIRED',path.name,flush=True)
 return {'product':product,'url':url,'file':path.name,'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'retrieved_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()}
with ThreadPoolExecutor(max_workers=3) as pool: results=list(pool.map(fetch,jobs))
(meta/f'acquisition_manifest_{year}.json').write_text(json.dumps(results,indent=2))
