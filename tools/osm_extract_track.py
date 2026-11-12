#!/usr/bin/env python3
"""Extrai o traçado de um circuito do OpenStreetMap (© colaboradores do OpenStreetMap, licença ODbL 1.0) e grava em
tools/osm_tracks/<id>.geojson no mesmo formato do bacinger/f1-circuits (lista de [lon, lat] começando na linha de
largada, no sentido da corrida; properties.length = comprimento oficial). Depois, tools/add_extra_circuits.py gera a pista.

Usado em 2026-11-12 para as pistas de 2012 sem traçado aberto: Valência, Coreia (Yeongam) e Índia (Buddh).

Uso: python3 tools/osm_extract_track.py <arquivo.osm> <id> <ids das vias separados por vírgula> <comprimento_m>
        <lon,lat da largada> <cw|ccw> [<arquivo.osm extra> ...]
As vias são encadeadas pelas pontas (nó em comum; senão, a ponta mais próxima, com aviso da emenda em metros).
"""
import json
import math
import pathlib
import sys
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "tools" / "osm_tracks"
K = math.pi / 180 * 6371000


def load(paths):
    nodes, ways = {}, {}
    for p in paths:
        t = ET.parse(p).getroot()
        for n in t.iter("node"):
            nodes[n.get("id")] = (float(n.get("lon")), float(n.get("lat")))
        for w in t.iter("way"):
            ways[w.get("id")] = [nd.get("ref") for nd in w.iter("nd")]
    return nodes, ways


def dist(a, b):
    return math.hypot((a[0] - b[0]) * math.cos(math.radians(a[1])) * K, (a[1] - b[1]) * K)


def chain(nodes, ways, ids):
    segs = [[nodes[r] for r in ways[i] if r in nodes] for i in ids]
    loop = list(segs.pop(0))
    gaps = []
    while segs:
        end = loop[-1]
        best = None
        for j, s in enumerate(segs):
            for rev in (False, True):
                d = dist(end, s[-1] if rev else s[0])
                if best is None or d < best[0]:
                    best = (d, j, rev)
        d, j, rev = best
        s = segs.pop(j)
        s = list(reversed(s)) if rev else s
        if d > 1.0:
            gaps.append(round(d))
        loop.extend(s if d > 1.0 else s[1:])
    close = dist(loop[-1], loop[0])
    if close > 1.0:
        gaps.append(round(close))
    if close < 1.0:
        loop.pop()
    return loop, gaps


def signed_area(pts):
    a = 0.0
    for i in range(len(pts)):
        x1, y1 = pts[i]
        x2, y2 = pts[(i + 1) % len(pts)]
        a += x1 * y2 - x2 * y1
    return a / 2.0


def main():
    osm, tid, ids, length, start, sense = sys.argv[1:7]
    extra = sys.argv[7:]
    nodes, ways = load([osm] + extra)
    loop, gaps = chain(nodes, ways, ids.split(","))
    # sentido: área com sinal em lon/lat (positiva = anti-horário visto de cima, com o norte para cima)
    ccw = signed_area(loop) > 0
    if (sense == "ccw") != ccw:
        loop.reverse()
    sx, sy = (float(v) for v in start.split(","))
    i0 = min(range(len(loop)), key=lambda i: dist(loop[i], (sx, sy)))
    loop = loop[i0:] + loop[:i0]
    raw = sum(dist(loop[i], loop[(i + 1) % len(loop)]) for i in range(len(loop)))
    OUT.mkdir(parents=True, exist_ok=True)
    g = {"type": "FeatureCollection", "features": [{"type": "Feature", "properties": {
        "id": tid, "length": int(length), "osm_length": round(raw), "gaps_m": gaps,
        "source": "© OpenStreetMap contributors, ODbL 1.0 (https://www.openstreetmap.org/copyright)", "osm_ways": ids},
        "geometry": {"type": "LineString", "coordinates": [[round(x, 7), round(y, 7)] for x, y in loop + [loop[0]]]}}]}
    (OUT / f"{tid}.geojson").write_text(json.dumps(g), encoding="utf-8")
    print(f"{tid}: {len(loop)} pontos, {round(raw)} m no OSM (oficial {length}), emendas {gaps}")


if __name__ == "__main__":
    main()
