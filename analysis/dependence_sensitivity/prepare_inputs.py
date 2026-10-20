"""Reproduce approved counts and cache joint geographic-block histories."""
from pathlib import Path
import sys, csv, json, hashlib, time
from paths import REPO as ROOT, WORK as OUT
import numpy as np
import shutil
from paths import DATA
CENTERS = [0, *range(15, 61, 5)]
YEARS = np.arange(2001, 2023)
PROFILES = ["Neither actor dominant", "Militia dominant", "Park dominant"]
chron = {}
with (ROOT/"data/dependence_sensitivity/profile_chronology.csv").open(encoding="utf-8-sig") as f:
    for r in csv.DictReader(f):
        chron[int(r["SESU_ID"]),int(r["year"])] = PROFILES.index(r["governance_profile"])
z=np.load(DATA/"landscape_arrays.npz", allow_pickle=False)
group,distance,forest,events,x,y,fire = [z[k] for k in ("group","distance","forest","events","x","y","fire")]
shutil.copy2(DATA/"landscape_arrays.npz",OUT/"landscape_arrays.npz")
ref={}
with (ROOT/"analysis_spatial_falsification_revised_dev/tables/boundary_surface_summary.csv").open(encoding="utf-8-sig") as f:
    for r in csv.DictReader(f):
        if r["threshold_tag"]=="tau025" and float(r["boundary_center_km"]) in CENTERS and r["outcome"] in ["fire","tree_cover_loss"]:
            ref[r["outcome"],int(float(r["boundary_center_km"])),int(r["SESU_ID"]),int(r["year"]),int(r["side"]=="interior_facing")]=(int(r["n"]),int(r["y"]))
meta=[]
for center in CENTERS:
    for g in (1,3):
        for yr in YEARS:
            for side in (0,1):
                meta.append(dict(center=center,SESU_ID=g,year=int(yr),side="inside" if side else "outside",governance_profile=PROFILES[chron[g,yr]]))
with (OUT/"surface_columns.csv").open("w",newline="") as f:
    w=csv.DictWriter(f,fieldnames=list(meta[0]));w.writeheader();w.writerows(meta)
validation=[]
for center in CENTERS:
    for g in (1,3):
        for yi,yr in enumerate(YEARS):
            for side in (0,1):
                sel=(abs(distance-center)<=10)&(group==g)&((distance<center)==side)
                risk=sel&(~np.isfinite(events)|(events>=yr))
                vals={"fire":(sel.sum(),fire[yi,sel].sum()),"tree_cover_loss":(risk.sum(),(events[risk]==yr).sum())}
                for outcome,(n,yy) in vals.items():
                    expected=ref.get((outcome,center,g,int(yr),side))
                    validation.append(dict(outcome=outcome,center=center,group=g,year=int(yr),side=side,n=int(n),y=int(yy),reference_n=None if expected is None else expected[0],reference_y=None if expected is None else expected[1],exact=expected==(n,yy)))
with (OUT/"count_validation.csv").open("w",newline="") as f:
    w=csv.DictWriter(f,fieldnames=list(validation[0]));w.writeheader();w.writerows(validation)
assert all(r["exact"] for r in validation), [r for r in validation if not r["exact"]][:5]
print(f"Validated {len(validation)} outcome/group/year/side counts across {len(CENTERS)} boundaries",flush=True)

for km,offset in [(k,o) for k in (5,10,20,40) for o in (0,.5)]:
    tag=f"{km}km_shift{int(offset*100)}"
    t0=time.monotonic()
    keys=np.column_stack([np.floor(x/(1000*km)-offset),np.floor(y/(1000*km)-offset)]).astype(int)
    unique,bi=np.unique(keys,axis=0,return_inverse=True)
    nt=len(unique); nc=len(meta)
    arrays={name:np.zeros((nt,nc),dtype=np.int32) for name in ("fire_n","fire_y","tree_n","tree_y","forest_n","forest_y")}
    for j,r in enumerate(meta):
        center,g,yr,side=r["center"],r["SESU_ID"],r["year"],r["side"]=="inside"
        sel=(abs(distance-center)<=10)&(group==g)&((distance<center)==side)
        risk=sel&(~np.isfinite(events)|(events>=yr))
        ev=risk&(events==yr)
        for name,mask in [("fire_n",sel),("fire_y",sel&fire[yr-2001]),("tree_n",risk),("tree_y",ev),("forest_n",risk&forest),("forest_y",ev&forest)]:
            arrays[name][:,j]=np.bincount(bi[mask],minlength=nt)
    np.savez_compressed(OUT/f"blocks_{tag}.npz",keys=unique,**arrays)
    # Column-major integer arrays are directly readable by R without a connector.
    for name in ("fire_n","fire_y"):
        arrays[name].ravel(order="F").astype("<i4").tofile(OUT/f"{name}_{tag}.bin")
    info={"block_km":km,"origin_fraction":offset,"ntiles":nt,"ncolumns":nc,"centers":CENTERS,
          "main_active_blocks":int(np.count_nonzero(arrays["fire_n"][:,:88].sum(axis=1))),
          "main_mixed_landscape_blocks":int(np.count_nonzero((arrays["fire_n"][:,:44].sum(axis=1)>0)&(arrays["fire_n"][:,44:88].sum(axis=1)>0)))}
    (OUT/f"blocks_{tag}.json").write_text(json.dumps(info,indent=2))
    print(tag,info,"seconds",round(time.monotonic()-t0,1),flush=True)
(OUT/"input_validation.json").write_text(json.dumps({"all_counts_match":True,"comparisons":len(validation),"centers":CENTERS,"main_cell_count":int((abs(distance)<=10).sum()),"main_tree_events":int(((abs(distance)<=10)&np.isfinite(events)&(events<=2022)).sum()),"main_fire_cell_year_events":int(fire[:,abs(distance)<=10].sum())},indent=2))
cached=np.load(OUT/"blocks_10km_shift0.npz")
nn=cached["forest_n"].sum(axis=0);yy=cached["forest_y"].sum(axis=0)
forest_counts=[dict(outcome="tree_cover_loss",center=r["center"],group=r["SESU_ID"],year=r["year"],
    side=int(r["side"]=="inside"),n=int(nn[i]),y=int(yy[i])) for i,r in enumerate(meta)]
with (OUT/"tree_forest_only_counts.csv").open("w",newline="") as f:
    w=csv.DictWriter(f,fieldnames=list(forest_counts[0]));w.writeheader();w.writerows(forest_counts)
