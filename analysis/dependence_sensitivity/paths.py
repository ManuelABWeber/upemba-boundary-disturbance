"""Paths shared by the supplementary sensitivity scripts; run from any directory."""
from pathlib import Path
import os
REPO = Path(__file__).resolve().parents[2]
DATA = REPO / "data/dependence_sensitivity"
RETAINED = REPO / "outputs/dependence_sensitivity"
WORK = Path(os.environ.get("UPEMBA_DEPENDENCE_OUTPUT_DIR", REPO / "outputs/_validation/dependence_sensitivity")).resolve()
if any(WORK == p or p in WORK.parents for p in (DATA, RETAINED)):
    raise ValueError("Working outputs must stay outside the committed inputs and retained results")
WORK.mkdir(parents=True, exist_ok=True)
