"""Latency measurement on synthetic 50-plot batches.

Uses TestClient (in-process); measures application-layer latency only.
Excludes network, TLS, and FastAPI's network stack. Numbers are lower
bounds for real-world HTTP.
"""
import sys, time, statistics
from pathlib import Path
import random
sys.path.insert(0, r'C:\SPROUT-Qonnect\03_api')
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)
random.seed(7)

def jitter_poly(lon, lat, half=0.0008):
    return {'type': 'Polygon', 'coordinates': [[
        [lon-half, lat-half], [lon+half, lat-half],
        [lon+half, lat+half], [lon-half, lat+half],
        [lon-half, lat-half],
    ]]}

anchor = (37.5505, 6.0005)
samples = []
for i in range(50):
    lon = anchor[0] + random.uniform(-0.003, 0.003)
    lat = anchor[1] + random.uniform(-0.003, 0.003)
    samples.append({
        'plot_id': f'PLT-LAT-{i:04d}',
        'geometry': jitter_poly(lon, lat),
        'area_ha': 1.0,
    })

per_endpoint = {'zone': [], 'landcover': [], 'agb': [], 'risk': []}
batch_start = time.perf_counter()
for s in samples:
    body = {'plot_id': s['plot_id'], 'geometry': s['geometry'], 'area_ha': s['area_ha']}
    for ep in per_endpoint:
        t0 = time.perf_counter()
        r = client.post(f'/v1/{ep}', json=body)
        per_endpoint[ep].append((time.perf_counter() - t0) * 1000.0)
batch_ms = (time.perf_counter() - batch_start) * 1000.0

print(f'Latency test: {len(samples)} plots x 4 endpoints (TestClient, in-process)')
print(f'  Total batch time : {batch_ms:,.1f} ms ({batch_ms/1000:.2f} s)')
print(f'  Per-plot avg     : {batch_ms/len(samples):.1f} ms')
print(f'  Throughput       : {len(samples) / (batch_ms/1000):.0f} plots/s')
print()
print(f'  {"endpoint":12s}  {"p50":>8s}  {"p95":>8s}  {"max":>8s}  (ms)')
for ep, times in per_endpoint.items():
    p50 = statistics.median(times)
    p95 = sorted(times)[int(len(times)*0.95)]
    print(f'  {ep:12s}  {p50:8.2f}  {p95:8.2f}  {max(times):8.2f}')