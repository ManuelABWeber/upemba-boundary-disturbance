"""Descriptive spatial and temporal residual correlations; no naive p-values."""
from pathlib import Path
import sys,csv
from paths import REPO as ROOT, WORK as OUT
import numpy as np
import json
z=np.load(OUT/"landscape_arrays.npz")
sel=abs(z["distance"])<=10
cells=z["cells"][sel];group=z["group"][sel];side=z["distance"][sel]<0
events=z["events"][sel];forest=z["forest"][sel]
fire=z["fire"][:,sel]
fitted={}
with (OUT/"fire_fitted_surface.csv").open() as f:
    for r in csv.DictReader(f):
        fitted[int(r["SESU_ID"]),int(r["year"]),r["side"]=="inside"]=float(r["fitted"])
F=np.zeros_like(fire,dtype=float)
T=np.full_like(fire,np.nan,dtype=float)
for yi,yr in enumerate(range(2001,2023)):
    for g in (1,3):
        for s in (False,True):
            ss=(group==g)&(side==s)
            mu=fitted[g,yr,s]
            F[yi,ss]=(fire[yi,ss]-mu)/np.sqrt(mu*(1-mu))
            risk=ss&(~np.isfinite(events)|(events>=yr))
            yy=(events[risk]==yr).astype(float);p=yy.mean()
            if 0<p<1:T[yi,risk]=(yy-p)/np.sqrt(p*(1-p))
nrows,ncols=json.loads((ROOT/"data/dependence_sensitivity/grid.json").read_text())["shape"]
rr,cc=np.unravel_index(cells,(nrows,ncols))
lookup=np.full(nrows*ncols,-1,dtype=int);lookup[cells]=np.arange(len(cells))
def corr(a,b):
    keep=np.isfinite(a)&np.isfinite(b);a=a[keep];b=b[keep]
    return len(a),float(np.corrcoef(a,b)[0,1]) if len(a)>2 else np.nan
rows=[]
for distance_cells in (1,2,5,10,20,40,60,80):
    ii=[];jj=[]
    for dr,dc in [(0,distance_cells),(distance_cells,0)]:
        r2=rr+dr;c2=cc+dc;valid=(r2<nrows)&(c2<ncols)
        src=np.where(valid)[0]
        dest=lookup[r2[valid]*ncols+c2[valid]]
        ok=dest>=0;ii.append(src[ok]);jj.append(dest[ok])
    i=np.concatenate(ii);j=np.concatenate(jj)
    for outcome,array in [("fire",F),("tree_cover_loss",T)]:
        count,correlation=corr(array[:,i].ravel(),array[:,j].ravel())
        rows.append(dict(outcome=outcome,distance_km=distance_cells*.5,cell_pairs=len(i),
            finite_cell_year_pairs=count,residual_correlation=correlation))
with (OUT/"spatial_residual_correlations.csv").open("w",newline="") as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
rows=[]
for lag in range(1,5):
    for outcome,array in [("fire",F),("tree_cover_loss",T)]:
        count,correlation=corr(array[lag:].ravel(),array[:-lag].ravel())
        rows.append(dict(outcome=outcome,lag_years=lag,finite_pairs=count,residual_correlation=correlation))
with (OUT/"within_cell_temporal_correlations.csv").open("w",newline="") as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
print("Residual diagnostics complete. Tree residuals use empirical group-side-year risk-set means; fire uses fitted model means.")
