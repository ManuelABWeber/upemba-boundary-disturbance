from pathlib import Path
import sys,csv,json,hashlib,datetime
from paths import REPO as ROOT, WORK as OUT
import numpy as np
A=OUT
profiles=["Neither actor dominant","Militia dominant","Park dominant"]
def read(name):
    with (A/name).open(encoding="utf-8-sig") as f:return list(csv.DictReader(f))
assert json.loads((A/"input_validation.json").read_text())["all_counts_match"]
stats=[]
for mode,tags in [("main",[f"{k}km_shift{s}" for k in (5,10,20) for s in (0,50)]),
                  ("longrange",["40km_shift0","40km_shift50"]),("outer",["10km_shift0"])]:
    for tag in tags:
        centers=[0] if mode!="outer" else [0,*range(15,61,5)]
        prefix=f"fire_{mode}_{tag}"
        rows=read(prefix+"_draws.csv");diags=read(prefix+"_diagnostics.csv")
        assert len(rows)==999*len(centers)*3
        assert len(diags)==999*len(centers)
        lookup={(int(r["replicate"]),int(r["center"]),r["profile"]):float(r["estimate"]) for r in rows}
        assert len(lookup)==len(rows),"Duplicate draw identities"
        arr=np.array([[[lookup[b,c,p] for p in profiles] for c in centers] for b in range(1,1000)])
        assert np.isfinite(arr).all()
        assert all(r["valid"]=="TRUE" and float(r["auto_gradient"])<1e-5 and
                   float(r["analytic_gradient"])<1e-5 and float(r["min_eigen"])>0 for r in diags)
        for r in read(prefix+"_intervals.csv"):
            lo,hi=np.quantile(arr[:,centers.index(int(r["center"])),profiles.index(r["profile"])],[.025,.975])
            assert abs(float(r["low"])-lo)<1e-10 and abs(float(r["high"])-hi)<1e-10
            assert int(r["retained"])==999
        stats.append(dict(outcome="fire",run=prefix,replicates=999,model_fits=len(diags),
                          maximum_gradient=max(float(r["auto_gradient"]) for r in diags)))
tree=read("tree_spatial_intervals.csv")
for path in A.glob("tree_*_draws.npz"):
    if not path.name.startswith(("tree_main_","tree_outer_")):continue
    z=np.load(path);arr=z["draws"];centers=list(z["centers"])
    pop="baseline_forest_only" if "baseline_forest_only" in path.name else "reported_all_cells"
    scope="outer" if path.name.startswith("tree_outer_") else "main"
    tag=path.name.split(f"tree_{scope}_")[1].split("_"+pop)[0]
    B=9999 if scope=="outer" else (19999 if tag.startswith("40km") else 4999)
    assert len(arr)==B and np.isfinite(arr).all()
    relevant=[r for r in tree if r["population"]==pop and r["tag"]==tag and r["scope"]==scope]
    assert len(relevant)==len(centers)*3
    for r in relevant:
        lo,hi=np.quantile(arr[:,centers.index(int(r["center"])),profiles.index(r["profile"])],[.025,.975])
        assert abs(float(r["low"])-lo)<1e-10 and abs(float(r["high"])-hi)<1e-10
    stats.append(dict(outcome="tree_cover_loss",run=path.stem,replicates=B,model_fits=B*len(centers)))
assert len(stats)==27
for r in read("independent_tree_validation.csv"):
    assert abs(float(r["estimate_delta"]))<1e-10 and abs(float(r["se_delta"]))<1e-10
assert max(abs(float(r["difference"])) for r in read("independent_fire_validation.csv"))<1e-6
cross=read("fire_optimizer_crosscheck.csv")
assert len(cross)==10 and all(r["alternate_pdHess"]=="TRUE" and r["alternate_convergence"]=="0" for r in cross)
assert max(float(r["maximum_contrast_difference"]) for r in cross)<2e-6
summary={"all_counts_reproduced":1936,"runs_verified":len(stats),
         "fire_bootstrap_fits":sum(r["model_fits"] for r in stats if r["outcome"]=="fire"),
         "tree_bootstrap_fits":sum(r["model_fits"] for r in stats if r["outcome"]=="tree_cover_loss"),"runs":stats}
(A/"final_validation.json").write_text(json.dumps(summary,indent=2)+"\n")
print(json.dumps({k:v for k,v in summary.items() if k!="runs"},indent=2))
