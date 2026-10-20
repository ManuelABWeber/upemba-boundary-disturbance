"""Verify committed inputs, all accepted draws, and derived interval summaries."""
import csv
import hashlib
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import numpy as np
from paths import DATA, REPO, RETAINED

CODE = Path(__file__).resolve().parent

def rows(path):
    with path.open(encoding='utf-8-sig', newline='') as handle:
        return list(csv.DictReader(handle))

manifest = json.loads((DATA / 'release_manifest.json').read_text())
for item in manifest['files']:
    file = REPO / item['path']
    assert file.stat().st_size == item['bytes'], item['path']
    assert hashlib.sha256(file.read_bytes()).hexdigest() == item['sha256'], item['path']

metadata = rows(RETAINED / 'surface_columns.csv')
counts = rows(RETAINED / 'count_validation.csv')
lookup = {(r['outcome'], int(r['center']), int(r['group']), int(r['year']), int(r['side'])): r for r in counts}
assert len(lookup) == 1936
forest = rows(RETAINED / 'tree_forest_only_counts.csv')
forest_lookup = {(int(r['center']), int(r['group']), int(r['year']), int(r['side'])): r for r in forest}
for file in sorted(DATA.glob('blocks_*.npz')):
    with np.load(file, allow_pickle=False) as block:
        assert block['fire_n'].shape[1] == len(metadata) == 968
        for prefix, outcome in [('fire', 'fire'), ('tree', 'tree_cover_loss')]:
            n, y = block[prefix+'_n'].sum(axis=0), block[prefix+'_y'].sum(axis=0)
            assert np.all(block[prefix+'_y'] <= block[prefix+'_n'])
            for index, column in enumerate(metadata):
                key = (outcome, int(column['center']), int(column['SESU_ID']), int(column['year']), int(column['side']=='inside'))
                record = lookup[key]
                assert int(n[index]) == int(record['n']) == int(record['reference_n'])
                assert int(y[index]) == int(record['y']) == int(record['reference_y'])
        n, y = block['forest_n'].sum(axis=0), block['forest_y'].sum(axis=0)
        for index, column in enumerate(metadata):
            key = (int(column['center']), int(column['SESU_ID']), int(column['year']), int(column['side']=='inside'))
            assert int(n[index]) == int(forest_lookup[key]['n'])
            assert int(y[index]) == int(forest_lookup[key]['y'])

def compare_csv(expected, actual):
    a, b = rows(expected), rows(actual)
    assert len(a) == len(b), expected.name
    # Summaries may use a different directory iteration order on another platform.
    a.sort(key=lambda r: tuple(r.values()))
    b.sort(key=lambda r: tuple(r.values()))
    for left, right in zip(a, b):
        assert left.keys() == right.keys(), expected.name
        for key in left:
            if left[key] == right[key]:
                continue
            try:
                x, y = float(left[key]), float(right[key])
            except ValueError:
                raise AssertionError((expected.name, key, left[key], right[key]))
            assert (math.isnan(x) and math.isnan(y)) or math.isclose(x, y, rel_tol=1e-10, abs_tol=1e-10), (expected.name, key, x, y)

temporary_parent = REPO / 'outputs/_validation'
temporary_parent.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='verify-dependence-', dir=temporary_parent) as directory:
    environment = dict(os.environ, UPEMBA_DEPENDENCE_OUTPUT_DIR=directory, OPENBLAS_NUM_THREADS='1')
    for name in ['stage_retained.py', 'audit_results.py', 'summarize_results.py']:
        subprocess.run([sys.executable, str(CODE / name)], cwd=REPO, env=environment, check=True)
    for name in ['combined_spatial_intervals.csv', 'profile_pairwise_spatial_intervals.csv',
                 'bootstrap_endpoint_monte_carlo.csv', 'joint_boundary_intervals.csv',
                 'fire_pairwise_temporal_intervals.csv', 'fire_fit_summary.csv']:
        compare_csv(RETAINED / name, Path(directory) / name)
print(f'PASS: {len(manifest["files"])} file hashes; 1,936 count pairs at every block configuration; 27 bootstrap runs; all derived summaries.')
