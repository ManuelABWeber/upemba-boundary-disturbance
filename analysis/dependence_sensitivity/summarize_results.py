from pathlib import Path
import sys,csv,json,hashlib,datetime
from paths import REPO as ROOT, WORK as OUT
import numpy as np
from scipy.stats import binom,t
profiles=["Neither actor dominant","Militia dominant","Park dominant"]
def read(name):
    with (OUT/name).open(encoding="utf-8-sig") as f:return list(csv.DictReader(f))
def write(name,rows):
    with (OUT/name).open("w",newline="") as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
intervals=[]
for r in read("tree_spatial_intervals.csv"):
    if r["scope"]=="main":
        intervals.append(dict(outcome="tree_cover_loss",population=r["population"],tag=r["tag"],profile=r["profile"],
            estimate=float(r["estimate"]),low=float(r["low"]),high=float(r["high"]),replicates=int(r["replicates"])))
for mode in ("main","longrange"):
    for path in sorted(OUT.glob(f"fire_{mode}_*_intervals.csv")):
        for r in read(path.name):
            intervals.append(dict(outcome="fire",population="reported_all_cells",tag=r["tag"],profile=r["profile"],
                estimate=float(r["estimate"]),low=float(r["low"]),high=float(r["high"]),replicates=int(r["retained"])))
for r in intervals:
    r.update(odds_ratio=float(np.exp(r["estimate"])),or_low=float(np.exp(r["low"])),or_high=float(np.exp(r["high"])),
             excludes_zero=r["low"]>0 or r["high"]<0)
write("combined_spatial_intervals.csv",intervals)
pairs=[];mc=[];boundary=[]
treebase=read("tree_baseline_estimates.csv")
for path in OUT.glob("tree_main_*_draws.npz"):
    arr=np.load(path)["draws"][:,0,:]
    population="baseline_forest_only" if "baseline_forest_only" in path.name else "reported_all_cells"
    tag=path.name.split("tree_main_")[1].split("_"+population)[0]
    base=np.array([float(next(r for r in treebase if r["population"]==population and r["center"]=="0" and r["profile"]==p)["estimate"]) for p in profiles])
    for i,j in [(1,0),(2,0),(2,1)]:
        lo,hi=np.quantile(arr[:,i]-arr[:,j],[.025,.975])
        pairs.append(dict(outcome="tree_cover_loss",population=population,tag=tag,contrast=profiles[i]+" minus "+profiles[j],estimate=base[i]-base[j],low=lo,high=hi,replicates=len(arr)))
    for p in range(3):
        s=np.sort(arr[:,p]);B=len(s)
        for q in (.025,.975):
            ranks=binom.ppf([.025,.975],B,q).astype(int)
            ranks=np.clip(ranks,0,B-1)
            mc.append(dict(outcome="tree_cover_loss",population=population,tag=tag,profile=profiles[p],quantile=q,
                endpoint=float(np.quantile(s,q)),mc_low=s[ranks[0]],mc_high=s[ranks[1]],replicates=B))
for mode in ("main","longrange"):
    for path in OUT.glob(f"fire_{mode}_*_draws.csv"):
        if not path.with_name(path.name.replace("_draws.csv","_intervals.csv")).exists():
            continue
        rows=read(path.name)
        reps=sorted({int(r["replicate"]) for r in rows})
        lookup={(int(r["replicate"]),r["profile"]):float(r["estimate"]) for r in rows}
        arr=np.array([[lookup[i,p] for p in profiles] for i in reps])
        tag=rows[0]["tag"]
        base=np.array([next(r["estimate"] for r in intervals if r["outcome"]=="fire" and r["tag"]==tag and r["profile"]==p) for p in profiles])
        for i,j in [(1,0),(2,0),(2,1)]:
            lo,hi=np.quantile(arr[:,i]-arr[:,j],[.025,.975])
            pairs.append(dict(outcome="fire",population="reported_all_cells",tag=tag,contrast=profiles[i]+" minus "+profiles[j],estimate=base[i]-base[j],low=lo,high=hi,replicates=len(arr)))
        for p in range(3):
            s=np.sort(arr[:,p]);B=len(s)
            for q in (.025,.975):
                ranks=np.clip(binom.ppf([.025,.975],B,q).astype(int),0,B-1)
                mc.append(dict(outcome="fire",population="reported_all_cells",tag=tag,profile=profiles[p],quantile=q,
                    endpoint=float(np.quantile(s,q)),mc_low=s[ranks[0]],mc_high=s[ranks[1]],replicates=B))
for population in ("reported_all_cells","baseline_forest_only"):
    z=np.load(OUT/f"tree_outer_10km_shift0_{population}_draws.npz")
    arr=z["draws"];delta=arr[:,0:1,:]-arr[:,1:,:]
    centers=z["centers"][1:]
    base=np.array([[float(next(r for r in treebase if r["population"]==population and int(r["center"])==int(c) and r["profile"]==p)["estimate"]) for p in profiles] for c in z["centers"]])
    est=base[0:1,:]-base[1:,:];sd=delta.std(axis=0,ddof=1)
    standardized=(delta-delta.mean(axis=0))/sd
    crit=np.quantile(np.max(abs(standardized),axis=(1,2)),.95)
    for ci,c in enumerate(centers):
        for p in range(3):
            lo,hi=np.quantile(delta[:,ci,p],[.025,.975])
            boundary.append(dict(outcome="tree_cover_loss",population=population,outer_center=int(c),profile=profiles[p],
                estimate=est[ci,p],low=lo,high=hi,simultaneous_low=est[ci,p]-crit*sd[ci,p],simultaneous_high=est[ci,p]+crit*sd[ci,p],
                simultaneous_critical_value=crit,replicates=len(arr)))
firepath=OUT/"fire_outer_10km_shift0_draws.csv"
if firepath.exists() and (OUT/"fire_outer_10km_shift0_intervals.csv").exists():
    rows=read(firepath.name);centers=sorted({int(r["center"]) for r in rows});reps=sorted({int(r["replicate"]) for r in rows})
    lookup={(int(r["replicate"]),int(r["center"]),r["profile"]):float(r["estimate"]) for r in rows}
    complete=[r for r in reps if all((r,c,p) in lookup for c in centers for p in profiles)]
    arr=np.array([[[lookup[r,c,p] for p in profiles] for c in centers] for r in complete])
    base_rows=read("fire_outer_baseline.csv")
    base=np.array([[float(next(r for r in base_rows if int(r["center"])==c and r["profile"]==p)["estimate"]) for p in profiles] for c in centers])
    delta=arr[:,0:1,:]-arr[:,1:,:];est=base[0:1,:]-base[1:,:];sd=delta.std(axis=0,ddof=1)
    crit=np.quantile(np.max(abs((delta-delta.mean(axis=0))/sd),axis=(1,2)),.95)
    for ci,c in enumerate(centers[1:]):
        for p in range(3):
            lo,hi=np.quantile(delta[:,ci,p],[.025,.975])
            boundary.append(dict(outcome="fire",population="reported_all_cells",outer_center=c,profile=profiles[p],
                estimate=est[ci,p],low=lo,high=hi,simultaneous_low=est[ci,p]-crit*sd[ci,p],simultaneous_high=est[ci,p]+crit*sd[ci,p],
                simultaneous_critical_value=crit,replicates=len(arr)))
write("profile_pairwise_spatial_intervals.csv",pairs)
write("bootstrap_endpoint_monte_carlo.csv",mc)
write("joint_boundary_intervals.csv",boundary)
annual_rows=read("fire_annual_influence.csv")
annual=np.array([[float(r[f"V{i}"]) for i in range(1,4)] for r in annual_rows])
base_rows=read("fire_main_baseline.csv")
base=np.array([float(next(r for r in base_rows if r["profile"]==p)["estimate"]) for p in profiles])
temporal_pairs=[]
for lag in range(5):
    V=annual.T@annual
    for ll in range(1,lag+1):
        C=annual[ll:].T@annual[:-ll]
        V+=(1-ll/(lag+1))*(C+C.T)
    V*=22/21
    for i,j in [(1,0),(2,0),(2,1)]:
        se=np.sqrt(max(0,V[i,i]+V[j,j]-2*V[i,j]))
        est=base[i]-base[j]
        temporal_pairs.append(dict(outcome="fire",contrast=profiles[i]+" minus "+profiles[j],lag_years=lag,
            estimate=est,se=se,low=est-t.ppf(.975,21)*se,high=est+t.ppf(.975,21)*se))
write("fire_pairwise_temporal_intervals.csv",temporal_pairs)
failures=[]
for path in OUT.glob("fire_*_diagnostics.csv"):
    if "temporal" in path.name or "pilot" in path.name:continue
    rows=read(path.name)
    if rows and "valid" in rows[0]:
        failures.append(dict(file=path.name,attempted=len(rows),failed=sum(r["valid"]!="TRUE" for r in rows)))
write("fire_fit_summary.csv",failures)
status={"updated_utc":datetime.datetime.now(datetime.timezone.utc).isoformat(),"spatial_interval_rows":len(intervals),
        "fire_files":failures,
        "results_complete":all((OUT/f"fire_main_{tag}_intervals.csv").exists() for tag in ["5km_shift0","10km_shift0","20km_shift0","5km_shift50","10km_shift50","20km_shift50"]) and all((OUT/f"fire_longrange_{tag}_intervals.csv").exists() for tag in ["40km_shift0","40km_shift50"]) and (OUT/"fire_outer_10km_shift0_intervals.csv").exists()}
(OUT/"assessment_status.json").write_text(json.dumps(status,indent=2))
print(json.dumps(status,indent=2))
