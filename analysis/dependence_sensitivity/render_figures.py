"""Build a review report only after the planned computational runs finish."""
from pathlib import Path
import sys,os,csv,json,math,hashlib,shutil
from paths import REPO as ROOT, WORK as OUT
DEST=OUT
DEST.mkdir(parents=True,exist_ok=True)
os.environ["MPLCONFIGDIR"]=str(OUT/"matplotlib_cache")
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
status=json.loads((OUT/"assessment_status.json").read_text())
assert status["results_complete"],"Do not issue a final report from incomplete bootstrap runs"
def read(name):
    with (OUT/name).open(encoding="utf-8-sig") as f:return list(csv.DictReader(f))
profiles=["Neither actor dominant","Militia dominant","Park dominant"]
labels=["Fragmented","Militia-centred","Park-centred"]
rows=read("combined_spatial_intervals.csv")
lookup={(r["outcome"],r["population"],r["tag"],r["profile"]):r for r in rows}
with (ROOT/"outputs/final_robustness/baseline_primary_results.csv").open() as f:
    orig={(r["outcome"],r["governance_profile"]):r for r in csv.DictReader(f)}
plt.rcParams.update({"font.family":"DejaVu Sans","font.size":10,"axes.spines.top":False,"axes.spines.right":False})
fig,axes=plt.subplots(1,2,figsize=(10.5,5.1),sharex=True,sharey=True)
methods=[("Original",None,"#777777"),("5 km",5,"#347c9b"),("10 km",10,"#36866b"),("20 km",20,"#c18435"),("40 km",40,"#9a4b68")]
for ax,outcome,title in zip(axes,["tree_cover_loss","fire"],["Tree-cover loss","Fire"]):
    for pi,p in enumerate(profiles):
        for mi,(label,km,color) in enumerate(methods):
            yy=2-pi+(mi-2)*.115
            if km is None:
                r=orig[outcome,p];e,lo,hi=[float(r[k]) for k in ("estimate","lower_95_ci","upper_95_ci")]
                ax.errorbar(e,yy,xerr=[[e-lo],[hi-e]],fmt="o",markersize=4,color=color,capsize=2,label=label if pi==0 else None)
            else:
                for shift in (50,0):
                    r=lookup[outcome,"reported_all_cells",f"{km}km_shift{shift}",p]
                    e,lo,hi=[float(r[k]) for k in ("estimate","low","high")]
                    ax.hlines(yy+(0.018 if shift else 0),lo,hi,color=color,alpha=.4 if shift else 1,linewidth=1.5)
                    ax.plot(e,yy+(0.018 if shift else 0),"o",markersize=4,markerfacecolor="white" if shift else color,
                            markeredgecolor=color,alpha=.5 if shift else 1,label=label if pi==0 and shift==0 else None)
    ax.axvline(0,color="#444444",linestyle="--",linewidth=.8)
    ax.set_title(title,fontsize=13,pad=12)
    ax.set_yticks([2,1,0],labels)
    ax.set_xlabel("Inside minus outside log odds")
    ax.grid(axis="x",color="#dddddd",linewidth=.5)
    ax.set_xlim(-2.2,.9);ax.set_ylim(-.5,2.5)
handles,legendlabels=axes[0].get_legend_handles_labels()
fig.legend(handles,legendlabels,loc="lower center",ncol=5,frameon=False,bbox_to_anchor=(.5,.015))
fig.subplots_adjust(left=.12,right=.98,top=.88,bottom=.19,wspace=.18)
fig.savefig(DEST/"dependence_intervals.png",dpi=220)
fig.savefig(DEST/"dependence_intervals.pdf")
plt.close(fig)

boundary=[r for r in read("joint_boundary_intervals.csv") if r["outcome"]=="tree_cover_loss" and r["population"]=="reported_all_cells"]
fig,axes=plt.subplots(1,3,figsize=(10.5,5.5),sharex=True,sharey=True)
for ax,p,title in zip(axes,profiles,labels):
    rs=sorted([r for r in boundary if r["profile"]==p],key=lambda r:int(r["outer_center"]))
    for r in rs:
        yy=int(r["outer_center"]);e=float(r["estimate"])
        ax.hlines(yy,float(r["simultaneous_low"]),float(r["simultaneous_high"]),color="#b7b7b7",linewidth=2)
        ax.hlines(yy,float(r["low"]),float(r["high"]),color="#226878",linewidth=2)
        ax.plot(e,yy,"o",color="#226878",markersize=4)
    ax.axvline(0,color="#444444",linestyle="--",linewidth=.8)
    ax.set_title(title,fontsize=12);ax.set_xlabel("Legal minus outer contrast")
    ax.grid(axis="x",color="#dddddd",linewidth=.5)
axes[0].set_ylabel("Outer-boundary offset (km)")
axes[0].set_yticks(range(15,61,5));axes[0].invert_yaxis()
fig.tight_layout()
fig.savefig(DEST/"tree_boundary_comparisons.png",dpi=220)
fig.savefig(DEST/"tree_boundary_comparisons.pdf")
plt.close(fig)
