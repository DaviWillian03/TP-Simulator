#!/usr/bin/env python3
"""Uso do solo REAL em volta de cada pista, a partir do OpenStreetMap (© colaboradores do OSM, ODbL 1.0) — 2026-11-13.

Gera, para a pista <id>:
  game/assets/ground/<id>.jpg      textura do chão (2048 px): florestas, campos em mosaico, cidade, estacionamentos,
                                   água, ruas e telhados com sombra; a faixa da pista fica limpa (o asfalto é a malha 3D)
  game/assets/ground/<id>_mask.png máscara 256 px: R = floresta (árvores 3D só ali), G = cidade (sem árvores), B = água
  game/data/scenery/<id>.json      caixa (metros do jogo) + plantas dos prédios com altura (o jogo levanta em 3D)

As coordenadas usam a MESMA projeção dos traçados (tools/build_calendar.project): lon/lat -> metros em torno do centro do
geojson do traçado, escalado ao comprimento oficial. Assim o mapa real cai exatamente em volta da pista do jogo.

Uso: python3 tools/make_landuse.py <id> [<id> ...]     (download em cache: tools/.osm_cache, fora do git)
"""
import json
import math
import pathlib
import random
import sys
import time
import urllib.request
import xml.etree.ElementTree as ET

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent.parent
CIRCUITS = ROOT / "game/data/circuits"
REFS = ROOT.parent / "refs/f1-circuits/circuits"
OSM_TRACKS = ROOT / "tools/osm_tracks"
CACHE = ROOT / "tools/.osm_cache"
OUT_TEX = ROOT / "game/assets/ground"
OUT_DATA = ROOT / "game/data/scenery"
MARGIN = 700.0  # igual a Scenery3D.MARGIN
TEX = 2048
MASK = 256
TILE = 0.01  # graus por pedaço de download
K = math.pi / 180 * 6371000
UA = "track-landuse-builder/1.0"

# geojson de origem de cada pista (bacinger ou extraído do OSM)
GEO = {"albertpark": "au-1953", "shanghai": "cn-2004", "suzuka": "jp-1962", "miami": "us-2022", "montreal": "ca-1978",
       "monaco": "mc-1929", "barcelona": "es-1991", "spielberg": "at-1969", "silverstone": "gb-1948", "spa": "be-1925",
       "hungaroring": "hu-1986", "zandvoort": "nl-1948", "monza": "it-1922", "madring": "es-2026", "baku": "az-2016",
       "singapore": "sg-2008", "austin": "us-2012", "mexico": "mx-1962", "interlagos": "br-1940", "lasvegas": "us-2023",
       "lusail": "qa-2004", "yasmarina": "ae-2009", "sepang": "my-1999", "bahrain": "bh-2002", "hockenheim": "de-1932"}

# paleta ORIGINAL (tons naturais, levemente estilizados)
C = {
    "base": (122, 150, 84), "grass": (128, 162, 88), "park": (110, 150, 80), "forest": (44, 74, 38), "scrub": (104, 122, 70),
    "farm": [(168, 164, 98), (147, 163, 86), (181, 168, 110), (143, 174, 95), (194, 179, 122), (120, 150, 76), (160, 150, 92)],
    "residential": (184, 176, 162), "industrial": (166, 162, 154), "parking": (138, 138, 134), "water": (63, 111, 149),
    "sand": (214, 196, 154), "bare": (170, 150, 112), "road": (104, 104, 102), "dirt": (160, 143, 106), "rail": (120, 110, 100),
    "roof": [(201, 194, 181), (169, 163, 154), (176, 122, 100), (190, 184, 172), (150, 152, 156), (205, 200, 190)],
    "shadow": (60, 64, 56), "pitch": (96, 150, 70),
}
ROAD_W = {"motorway": 16, "trunk": 14, "primary": 11, "secondary": 9, "tertiary": 8, "unclassified": 6, "residential": 6,
          "living_street": 5, "service": 4, "track": 2.2, "path": 1.0, "footway": 1.0, "cycleway": 1.5}


def geo_coords(cid):
    src = OSM_TRACKS / f"{cid}.geojson" if (OSM_TRACKS / f"{cid}.geojson").exists() else REFS / f"{GEO[cid]}.geojson"
    g = json.loads(src.read_text(encoding="utf-8"))
    return g["features"][0]["geometry"]["coordinates"], float(g["features"][0]["properties"]["length"])


def projection(cid):
    """(lon,lat) -> metros do jogo, igual a build_calendar.project + escala ao comprimento oficial."""
    coords, length = geo_coords(cid)
    lat0 = sum(c[1] for c in coords) / len(coords)
    lon0 = sum(c[0] for c in coords) / len(coords)
    cosl = math.cos(math.radians(lat0))
    pts = [((c[0] - lon0) * cosl * K, -(c[1] - lat0) * K) for c in coords]
    if math.dist(pts[0], pts[-1]) < 0.5:
        pts = pts[:-1]
    src_len = sum(math.dist(pts[i], pts[(i + 1) % len(pts)]) for i in range(len(pts)))
    data = json.loads((CIRCUITS / f"{cid}.json").read_text(encoding="utf-8"))
    s = float(data["length_m"]) / src_len
    fwd = lambda lon, lat: ((lon - lon0) * cosl * K * s, -(lat - lat0) * K * s)
    inv = lambda x, y: (x / (cosl * K * s) + lon0, -y / (K * s) + lat0)
    return fwd, inv, data


def fetch(bbox):
    """Baixa o OSM de uma caixa (lon0, lat0, lon1, lat1) em pedaços, com cache. Devolve a lista de arquivos."""
    CACHE.mkdir(parents=True, exist_ok=True)
    files = []
    lon = math.floor(bbox[0] / TILE) * TILE
    while lon < bbox[2]:
        lat = math.floor(bbox[1] / TILE) * TILE
        while lat < bbox[3]:
            files += _fetch_tile(round(lon, 4), round(lat, 4), TILE)
            lat += TILE
        lon += TILE
    return files


def _fetch_tile(lon, lat, size):
    f = CACHE / f"{lon:.4f}_{lat:.4f}_{size:.4f}.osm"
    if not f.exists():
        url = f"https://api.openstreetmap.org/api/0.6/map?bbox={lon},{lat},{lon + size},{lat + size}"
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        for attempt in range(4):
            try:
                with urllib.request.urlopen(req, timeout=90) as r:
                    f.write_bytes(r.read())
                break
            except urllib.error.HTTPError as e:
                if e.code == 400 and size > 0.0026:  # muitos nós: divide em 4
                    h = size / 2
                    return (_fetch_tile(lon, lat, h) + _fetch_tile(lon + h, lat, h) + _fetch_tile(lon, lat + h, h)
                            + _fetch_tile(lon + h, lat + h, h))
                time.sleep(2 * (attempt + 1))
            except Exception:
                time.sleep(2 * (attempt + 1))
        time.sleep(0.4)
    return [f] if f.exists() else []


def parse(files):
    nodes, ways, rels = {}, {}, {}
    for f in files:
        try:
            t = ET.parse(f).getroot()
        except ET.ParseError:
            continue
        for n in t.iter("node"):
            nodes[n.get("id")] = (float(n.get("lon")), float(n.get("lat")))
        for w in t.iter("way"):
            ways[w.get("id")] = ([nd.get("ref") for nd in w.iter("nd")], {x.get("k"): x.get("v") for x in w.iter("tag")})
        for r in t.iter("relation"):
            tags = {x.get("k"): x.get("v") for x in r.iter("tag")}
            if tags.get("type") == "multipolygon":
                rels[r.get("id")] = ([(m.get("ref"), m.get("role")) for m in r.iter("member") if m.get("type") == "way"], tags)
    return nodes, ways, rels


def rings_of(member_ways, ways):
    """Monta anéis fechados a partir das vias de uma relação multipolígono (encadeia pelas pontas)."""
    segs = [list(ways[w][0]) for w in member_ways if w in ways and len(ways[w][0]) > 1]
    rings = []
    while segs:
        ring = segs.pop(0)
        changed = True
        while ring[0] != ring[-1] and changed:
            changed = False
            for i, s in enumerate(segs):
                if s[0] == ring[-1]:
                    ring += s[1:]
                elif s[-1] == ring[-1]:
                    ring += s[::-1][1:]
                elif s[-1] == ring[0]:
                    ring = s[:-1] + ring
                elif s[0] == ring[0]:
                    ring = s[::-1][:-1] + ring
                else:
                    continue
                segs.pop(i)
                changed = True
                break
        rings.append(ring)
    return rings


def classify(tags):
    lu, nat, lei, am = tags.get("landuse"), tags.get("natural"), tags.get("leisure"), tags.get("amenity")
    if nat == "water" or lu in ("reservoir", "basin") or tags.get("waterway") == "riverbank":
        return "water"
    if lu == "forest" or nat == "wood":
        return "forest"
    if nat in ("scrub", "heath") or lu == "orchard" or lu == "vineyard":
        return "scrub"
    if lu in ("farmland", "farmyard", "allotments"):
        return "farm"
    if lu in ("meadow", "grass", "village_green", "recreation_ground") or nat == "grassland":
        return "grass"
    if lei in ("park", "garden", "golf_course"):
        return "park"
    if lei in ("pitch", "stadium", "track"):
        return "pitch"
    if lu in ("residential",):
        return "residential"
    if lu in ("industrial", "commercial", "retail", "railway", "construction", "garages", "military"):
        return "industrial"
    if am == "parking" or lu == "parking":
        return "parking"
    if nat in ("sand", "beach", "bare_rock", "scree") or lu in ("quarry", "brownfield", "landfill"):
        return "sand" if nat in ("sand", "beach") else "bare"
    return None


ORDER = ["farm", "grass", "park", "scrub", "forest", "residential", "industrial", "bare", "sand", "pitch", "parking", "water"]


def build(cid):
    fwd, inv, data = projection(cid)
    pts = data["points"]
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    box = (min(xs) - MARGIN, min(ys) - MARGIN, max(xs) + MARGIN, max(ys) + MARGIN)
    lo = inv(box[0], box[3])
    hi = inv(box[2], box[1])
    files = fetch((lo[0] - 0.002, lo[1] - 0.002, hi[0] + 0.002, hi[1] + 0.002))
    nodes, ways, rels = parse(files)
    W = box[2] - box[0]
    H = box[3] - box[1]
    sc = TEX / max(W, H)
    tw, th = int(W * sc), int(H * sc)
    px = lambda x, y: ((x - box[0]) * sc, (y - box[1]) * sc)
    rnd = random.Random(hash(cid) & 0xFFFF)

    def ring_px(refs):
        out = []
        for r in refs:
            if r in nodes:
                out.append(px(*fwd(*nodes[r])))
        return out

    # áreas por classe (vias fechadas + relações)
    polys = {k: [] for k in ORDER}
    used_in_rel = set()
    for rid, (members, tags) in rels.items():
        k = classify(tags)
        if not k:
            continue
        outers = [w for w, role in members if role != "inner"]
        for ring in rings_of(outers, ways):
            if len(ring) > 3 and ring[0] == ring[-1]:  # só contornos fechados (pedaço incompleto viraria um "lago" falso)
                polys[k].append(ring_px(ring))
        used_in_rel.update(w for w, _ in members)
    for wid, (refs, tags) in ways.items():
        if len(refs) < 4 or refs[0] != refs[-1] or "building" in tags:
            continue
        k = classify(tags)
        if k and wid not in used_in_rel:
            polys[k].append(ring_px(refs))

    img = Image.new("RGB", (tw, th), C["base"])
    d = ImageDraw.Draw(img)
    _patchwork(d, tw, th, sc, rnd)  # fundo: lavouras em mosaico (onde o OSM não tem dado, parece campo de verdade)
    mask = Image.new("RGB", (tw, th), (0, 0, 0))
    md = ImageDraw.Draw(mask)
    for k in ORDER:
        for poly in polys[k]:
            if len(poly) < 3:
                continue
            col = rnd.choice(C["farm"]) if k == "farm" else C.get(k, C["base"])
            if k in ("grass", "park", "residential"):
                col = tuple(max(0, min(255, c + rnd.randint(-8, 8))) for c in col)
            d.polygon(poly, fill=col)
            if k == "forest":
                md.polygon(poly, fill=(255, 0, 0))
            elif k == "scrub":
                md.polygon(poly, fill=(110, 0, 0))
            elif k in ("residential", "industrial", "parking"):
                md.polygon(poly, fill=(0, 255, 0))
            elif k == "water":
                md.polygon(poly, fill=(0, 0, 255))

    # ruas e ferrovias (linhas por largura real)
    for wid, (refs, tags) in ways.items():
        hw = tags.get("highway")
        if hw and hw in ROAD_W and hw != "raceway":
            line = ring_px(refs)
            if len(line) > 1:
                col = C["dirt"] if hw in ("track", "path", "footway", "cycleway") else C["road"]
                if hw in ("path", "footway", "cycleway", "track"):  # trilhas: discretas (somem sob as árvores)
                    col = tuple((a * 2 + b) // 3 for a, b in zip(col, C["forest"]))
                d.line(line, fill=col, width=max(1, int(ROAD_W[hw] * sc)), joint="curve")
        elif tags.get("railway") == "rail":
            line = ring_px(refs)
            if len(line) > 1:
                d.line(line, fill=C["rail"], width=max(1, int(4 * sc)))
        elif tags.get("waterway") in ("river", "canal", "stream"):
            line = ring_px(refs)
            if len(line) > 1:
                d.line(line, fill=C["water"], width=max(1, int((14 if tags["waterway"] != "stream" else 4) * sc)))

    # prédios: telhado + sombra deslocada (luz vinda do noroeste)
    buildings = []
    sh = max(1, int(3 * sc))
    for wid, (refs, tags) in ways.items():
        if "building" not in tags or len(refs) < 4:
            continue
        ring = [fwd(*nodes[r]) for r in refs if r in nodes]
        if len(ring) < 4:
            continue
        area = abs(sum(ring[i][0] * ring[i + 1][1] - ring[i + 1][0] * ring[i][1] for i in range(len(ring) - 1))) / 2
        if area < 20:
            continue
        cx = sum(p[0] for p in ring) / len(ring)
        cy = sum(p[1] for p in ring) / len(ring)
        if not (box[0] < cx < box[2] and box[1] < cy < box[3]):
            continue
        h = _height(tags, area, rnd)
        poly = [px(x, y) for x, y in ring]
        d.polygon([(x + sh, y + sh) for x, y in poly], fill=C["shadow"])
        roof = rnd.choice(C["roof"])
        d.polygon(poly, fill=roof)
        md.polygon(poly, fill=(0, 255, 0))
        simp = ring[:-1] if len(ring) <= 13 else ring[:-1][:: max(1, len(ring) // 12)]
        buildings.append([round(h, 1), [[round(x, 1), round(y, 1)] for x, y in simp], "#%02x%02x%02x" % roof])

    # faixa da pista limpa (grama): o asfalto e as áreas de escape são a malha 3D do jogo
    track_px = [px(x, y) for x, y in pts] + [px(*pts[0])]
    d.line(track_px, fill=C["grass"], width=int(46 * sc), joint="curve")
    md.line(track_px, fill=(0, 0, 0), width=int(80 * sc), joint="curve")

    img = _texture(img, rnd)
    OUT_TEX.mkdir(parents=True, exist_ok=True)
    OUT_DATA.mkdir(parents=True, exist_ok=True)
    img.save(OUT_TEX / f"{cid}.jpg", quality=84)
    mask.resize((MASK, int(MASK * th / tw) if tw >= th else MASK), Image.BILINEAR).save(OUT_TEX / f"{cid}_mask.png")
    # prédios perto da pista têm prioridade (o limite protege o desempenho no celular)
    buildings.sort(key=lambda b: min(math.dist((b[1][0][0], b[1][0][1]), p) for p in pts[::6]))
    buildings = buildings[:2500]
    (OUT_DATA / f"{cid}.json").write_text(json.dumps({
        "_notas": "Gerado por tools/make_landuse.py a partir do OpenStreetMap (© colaboradores do OSM, ODbL 1.0). "
                  "box = [x0, z0, x1, z1] da textura em metros do jogo; buildings = [altura, planta [[x, z]...], cor do telhado].",
        "box": [round(v, 1) for v in box], "buildings": buildings}, separators=(",", ":")), encoding="utf-8")
    print(f"{cid}: {len(files)} pedaços, {sum(len(v) for v in polys.values())} áreas, {len(buildings)} prédios, textura {tw}x{th}")


def _patchwork(d, tw, th, sc, rnd):
    """Mosaico de lavouras retangulares levemente giradas (talhões de 120-320 m), em tons de campo, sob o mapa real."""
    import math as _m
    ang = rnd.uniform(0, _m.pi)
    ca, sa = _m.cos(ang), _m.sin(ang)
    diag = int(_m.hypot(tw, th))
    cx, cy = tw / 2, th / 2
    v = -diag
    while v < diag:
        hgt = rnd.uniform(120, 320) * sc
        u = -diag
        while u < diag:
            wid = rnd.uniform(120, 320) * sc
            col = rnd.choice(C["farm"] + [C["base"], C["grass"], C["grass"]])
            col = tuple(max(0, min(255, c + rnd.randint(-6, 6))) for c in col)
            corners = [(u, v), (u + wid, v), (u + wid, v + hgt), (u, v + hgt)]
            d.polygon([(cx + a * ca - b * sa, cy + a * sa + b * ca) for a, b in corners], fill=col)
            u += wid
        v += hgt


def _height(tags, area, rnd):
    if "height" in tags:
        try:
            return float(tags["height"].split()[0])
        except ValueError:
            pass
    if "building:levels" in tags:
        try:
            return float(tags["building:levels"]) * 3.2 + 1.5
        except ValueError:
            pass
    b = tags.get("building")
    base = {"house": 7, "detached": 7, "residential": 9, "apartments": 18, "industrial": 9, "warehouse": 10,
            "commercial": 12, "retail": 7, "grandstand": 14, "garage": 3.5, "garages": 3.5, "shed": 3.5, "roof": 6,
            "office": 20, "hotel": 30}.get(b, 8 if area < 400 else 11)
    return base * rnd.uniform(0.85, 1.25)


def _texture(img, rnd):
    """Grão orgânico: variação suave de luz (manchas grandes) + ruído fino, para o chão não parecer chapado."""
    a = np.asarray(img).astype(np.float32)
    h, w = a.shape[:2]
    rs = np.random.RandomState(rnd.randint(0, 99999))
    big = Image.fromarray((rs.rand(h // 64 + 2, w // 64 + 2) * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
    mid = Image.fromarray((rs.rand(h // 12 + 2, w // 12 + 2) * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
    fine = rs.rand(h, w)
    n = (np.asarray(big, np.float32) / 255 - 0.5) * 0.16 + (np.asarray(mid, np.float32) / 255 - 0.5) * 0.10 + (fine - 0.5) * 0.06
    a *= (1.0 + n)[..., None]
    out = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))
    return out.filter(ImageFilter.GaussianBlur(0.6))


if __name__ == "__main__":
    for cid in sys.argv[1:]:
        build(cid)
