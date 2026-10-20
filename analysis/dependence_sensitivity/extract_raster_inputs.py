"""Reproduce approved counts and cache joint geographic-block histories."""
from pathlib import Path
import sys, csv, json, hashlib, time, os
from paths import REPO as ROOT, WORK as OUT
import numpy as np
import rasterio
BASE = Path(os.environ["UPEMBA_DEPENDENCE_RASTER_ROOT"])
CENTERS = [0, *range(15, 61, 5)]
YEARS = np.arange(2001, 2023)
PROFILES = ["Neither actor dominant", "Militia dominant", "Park dominant"]
chron = {}
with (ROOT/"data/dependence_sensitivity/profile_chronology.csv").open(encoding="utf-8-sig") as f:
    for r in csv.DictReader(f):
        chron[int(r["SESU_ID"]),int(r["year"])] = PROFILES.index(r["governance_profile"])
with rasterio.open(BASE/"run_2026_04_07/SESU_ID_500m.tif") as ds:
    group = ds.read(1,masked=True).filled(0).ravel()
    shape, transform = ds.shape, ds.transform
with rasterio.open(BASE/"run_2026_04_07/SESU_covariates_500m.tif") as ds:
    def band(name):
        return ds.read(ds.descriptions.index(name)+1,masked=True).filled(np.nan).ravel()
    distance = band("dist_parc_national_signed_m")/1000
    forest = band("forest2000_ge_30pct")==1
    events = band("year_deforest_masked")
    events[events<=0] = np.nan
selected = np.where(np.isin(group,[1,3]) & np.isfinite(distance) & (distance>=-10) & (distance<=70))[0]
row,col = np.unravel_index(selected,shape)
x,y = (np.asarray(v) for v in rasterio.transform.xy(transform,row,col))
group,distance,forest,events = [v[selected] for v in (group,distance,forest,events)]
fire=[]
with rasterio.open(BASE/"data/FireCCI51_season_DOYmin_tau_and_binary_2001_2020_500m_epsg32735.tif") as ds:
    assert ds.shape==shape and ds.transform==transform
    for yr in YEARS[:20]:
        a=ds.read(ds.descriptions.index(f"{yr}_fire_season_{yr}")+1,masked=True).filled(0).ravel()[selected]==1
        fire.append(a)
for yr in YEARS[20:]:
    with rasterio.open(BASE/f"terra_fire/fire_{yr}_tau025.tif") as ds:
        assert ds.shape==shape and ds.transform==transform
        fire.append(ds.read(1,masked=True).filled(0).ravel()[selected]==1)
fire=np.asarray(fire)
np.savez_compressed(OUT/"landscape_arrays.npz",cells=selected,x=x,y=y,group=group,distance=distance,forest=forest,events=events,fire=fire)

print("Extracted landscape_arrays.npz to",OUT)
