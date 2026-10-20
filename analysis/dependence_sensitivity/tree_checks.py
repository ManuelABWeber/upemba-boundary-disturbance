"""Joint whole-history spatial bootstrap, temporal HAC and influence checks."""
from pathlib import Path
import sys,csv,json,time
from paths import REPO as ROOT, WORK as OUT
import numpy as np
from scipy.stats import t
meta=list(csv.DictReader((OUT/"surface_columns.csv").open()))
profiles=["Neither actor dominant","Militia dominant","Park dominant"]
X=np.zeros((44,4))
for j,r in enumerate(meta[:88:2]):
    X[j,profiles.index(r["governance_profile"])]=1
    X[j,3]=int(r["SESU_ID"]=="3")
L=np.column_stack((np.eye(3),np.full(3,.5)))
centers=[int(meta[j]["center"]) for j in range(0,len(meta),88)]
def data_vectors(n,y):
    n=n.reshape(*n.shape[:-1],44,2);y=y.reshape(*y.shape[:-1],44,2)
    a,b=y[...,1]+.5,n[...,1]-y[...,1]+.5
    c,d=y[...,0]+.5,n[...,0]-y[...,0]+.5
    D=np.log(a/b)-np.log(c/d);w=1/(1/a+1/b+1/c+1/d)
    return D,w
def fit(n,y,xx=X):
    D,w=data_vectors(n,y)
    A=np.einsum("...k,ki,kj->...ij",w,xx,xx)
    rhs=np.einsum("...k,...k,ki->...i",w,D,xx)
    beta=np.linalg.solve(A,rhs[...,None])[...,0]
    return beta@L.T
def save_csv(name,rows):
    with (OUT/name).open("w",newline="") as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
base=np.load(OUT/"blocks_10km_shift0.npz")
baseline={}
temporal=[];influence=[];diagnostic=[]
for population,prefix in [("reported_all_cells","tree"),("baseline_forest_only","forest")]:
    nn=base[prefix+"_n"].sum(axis=0).reshape(11,88)
    yy=base[prefix+"_y"].sum(axis=0).reshape(11,88)
    estimates=fit(nn,yy);baseline[population]=estimates
    for ci,center in enumerate(centers):
        D,w=data_vectors(nn[ci],yy[ci])
        A=X.T@(w[:,None]*X);Ai=np.linalg.inv(A);beta=Ai@(X.T@(w*D))
        residual=D-X@beta;h=np.einsum("ij,jk,ik->i",X,Ai,X)*w
        # HC3-adjusted observation scores; sum groups before applying time lags.
        score=X*(w*residual/(1-h))[:,None]
        annual=score.reshape(2,22,4).sum(axis=0)
        infl=annual@Ai@L.T
        for lag in range(5):
            meat=annual.T@annual
            for ll in range(1,lag+1):
                cross=annual[ll:].T@annual[:-ll]
                meat+=(1-ll/(lag+1))*(cross+cross.T)
            V=Ai@meat@Ai*(22/21)
            se=np.sqrt(np.maximum(0,np.diag(L@V@L.T)))
            for p in range(3):
                temporal.append(dict(population=population,center=center,profile=profiles[p],lag_years=lag,
                    estimate=estimates[ci,p],se=se[p],low=estimates[ci,p]-t.ppf(.975,21)*se[p],high=estimates[ci,p]+t.ppf(.975,21)*se[p]))
        for yi in range(22):
            keep=np.tile(np.arange(22)!=yi,2)
            xx=X[keep];ww=w[keep];dd=D[keep]
            bb=np.linalg.solve(xx.T@(ww[:,None]*xx),xx.T@(ww*dd));ee=L@bb
            for p in range(3):
                influence.append(dict(population=population,center=center,omitted_year=2001+yi,profile=profiles[p],estimate=ee[p],change=ee[p]-estimates[ci,p]))
        if center==0:
            for p in range(3):
                for lag in range(1,5):
                    diagnostic.append(dict(population=population,profile=profiles[p],lag_years=lag,
                        annual_influence_correlation=float(np.corrcoef(infl[lag:,p],infl[:-lag,p])[0,1])))
save_csv("tree_temporal_hac.csv",temporal)
save_csv("tree_leave_year_out.csv",influence)
save_csv("tree_temporal_diagnostics.csv",diagnostic)
all_intervals=[];all_diffs=[];support=[];mc=[]
for km in (5,10,20,40):
    for shift in (0,50):
        tag=f"{km}km_shift{shift}";z=np.load(OUT/f"blocks_{tag}.npz")
        for scope in (["main","outer"] if tag=="10km_shift0" else ["main"]):
            cc=11 if scope=="outer" else 1
            ncols=cc*88
            active=z["fire_n"][:,:ncols].sum(axis=1)>0
            nt=int(active.sum())
            B=19999 if km==40 else (9999 if scope=="outer" else 4999)
            rng=np.random.default_rng(140291+km*100+shift+(scope=="outer")*10000)
            weights=rng.multinomial(nt,np.full(nt,1/nt),size=B)
            for population,prefix in [("reported_all_cells","tree"),("baseline_forest_only","forest")]:
                t0=time.monotonic()
                N=z[prefix+"_n"][active,:ncols].astype(float)
                Y=z[prefix+"_y"][active,:ncols].astype(float)
                draws=[]
                for start in range(0,B,100):
                    nn=(weights[start:start+100]@N).reshape(-1,cc,88)
                    yy=(weights[start:start+100]@Y).reshape(-1,cc,88)
                    draws.append(fit(nn,yy))
                draws=np.concatenate(draws)
                np.savez_compressed(OUT/f"tree_{scope}_{tag}_{population}_draws.npz",draws=draws,centers=np.array(centers[:cc]))
                for ci,center in enumerate(centers[:cc]):
                    for p in range(3):
                        lo,hi=np.quantile(draws[:,ci,p],[.025,.975])
                        all_intervals.append(dict(population=population,scope=scope,tag=tag,center=center,profile=profiles[p],
                            estimate=baseline[population][ci,p],low=lo,high=hi,replicates=B,blocks=nt))
                        q1=np.quantile(draws[:999,ci,p],[.025,.975])
                        q2=np.quantile(draws[999:,ci,p],[.025,.975])
                        mc.append(dict(population=population,scope=scope,tag=tag,center=center,profile=profiles[p],
                            low_first=q1[0],low_second=q2[0],high_first=q1[1],high_second=q2[1]))
                if scope=="outer":
                    for ci,center in enumerate(centers[1:],1):
                        for p in range(3):
                            delta=draws[:,0,p]-draws[:,ci,p]
                            lo,hi=np.quantile(delta,[.025,.975])
                            all_diffs.append(dict(population=population,outer_center=center,profile=profiles[p],
                                estimate=baseline[population][0,p]-baseline[population][ci,p],low=lo,high=hi,replicates=B))
                print("tree",scope,tag,population, B,"draws",round(time.monotonic()-t0,2),"seconds",flush=True)
        main=z["tree_n"][:,:88]
        support.append(dict(tag=tag,active_blocks=int((main.sum(axis=1)>0).sum()),
            both_sides_blocks=int(((main[:,::2].sum(axis=1)>0)&(main[:,1::2].sum(axis=1)>0)).sum()),
            event_blocks=int((z["tree_y"][:,:88].sum(axis=1)>0).sum())))
save_csv("tree_spatial_intervals.csv",all_intervals)
save_csv("tree_joint_boundary_differences.csv",all_diffs)
save_csv("tree_block_support.csv",support)
save_csv("tree_bootstrap_stability.csv",mc)
save_csv("tree_baseline_estimates.csv",[dict(population=pop,center=centers[ci],profile=profiles[p],estimate=est[ci,p]) for pop,est in baseline.items() for ci in range(11) for p in range(3)])
print("Tree assessment computations complete",flush=True)
