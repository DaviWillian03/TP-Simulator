"""Pistas extras das temporadas antigas (2026-11-12): Sepang, Bahrein e Hockenheim (bacinger/f1-circuits, MIT) e Valência,
Coreia e Índia (sem traçado aberto no bacinger: extraídas do OpenStreetMap, © colaboradores do OSM, ODbL 1.0, por
tools/osm_extract_track.py em tools/osm_tracks/). Mesmo método e acabamento
das pistas de 2026: traçado escalado ao comprimento oficial, zonas de ultrapassagem pelas 3 maiores
retas, boxes pela geometria, perfil, relevo, bioma, zebras e marcos. Valores de desempenho PROVISÓRIOS.
Uso: python tools/add_extra_circuits.py <pasta do bacinger/f1-circuits> [id ...]   (sem ids: todas)
"""
import json
import math
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from build_calendar import project, straights  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "game" / "data" / "circuits"

TRACKS = [
    dict(id="sepang", geo="my-1999", gp="GP da Malásia", name="Sepang International Circuit", short="Sepang", country="Malásia",
         cc="my", city="Sepang", rnd=2, date="2012-03-25", laps=56, base=98.0, pit=21.0, diff=0.35, rain=0.55, wear=1.15,
         profile=(0.35, 0.30, 0.35), night=False,
         scenery={"theme": "forest", "landmarks": ["palms"], "trees": 0.2, "kerbs": ["#d42020", "#f2f2f2"]},
         elevation=[[0.0, 0.0], [0.08, -4.0], [0.2, 6.0], [0.35, 12.0], [0.5, 8.0], [0.65, 2.0], [0.8, -4.0], [0.92, -2.0], [1.0, 0.0]]),
    dict(id="bahrain", geo="bh-2002", gp="GP do Bahrein", name="Bahrain International Circuit", short="Sakhir", country="Bahrein",
         cc="bh", city="Sakhir", rnd=4, date="2012-04-22", laps=57, base=96.0, pit=22.0, diff=0.3, rain=0.02, wear=1.1,
         profile=(0.45, 0.40, 0.15), night=False,
         scenery={"theme": "desert", "landmarks": ["palms"], "trees": 0.0, "city": 0.04, "kerbs": ["#d42020", "#f2f2f2"]},
         elevation=[[0.0, 0.0], [0.15, 2.0], [0.3, 6.0], [0.45, 10.0], [0.6, 4.0], [0.8, 0.0], [1.0, 0.0]]),
    dict(id="hockenheim", geo="de-1932", gp="GP da Alemanha", name="Hockenheimring", short="Hockenheim", country="Alemanha",
         cc="de", city="Hockenheim", rnd=10, date="2012-07-22", laps=67, base=76.5, pit=19.0, diff=0.4, rain=0.3, wear=0.95,
         profile=(0.40, 0.40, 0.20), night=False,
         scenery={"theme": "forest", "landmarks": ["stadium_section"], "trees": 0.3, "kerbs": ["#d42020", "#f2f2f2"],
                  "spans": {"stadium_section": [0.86, 0.97]}},
         elevation=[[0.0, 0.0], [0.2, 2.0], [0.45, 4.0], [0.7, 1.0], [1.0, 0.0]]),
    dict(id="valencia", osm="valencia", gp="GP da Europa", name="Valencia Street Circuit", short="Valência", country="Espanha",
         cc="es", city="Valência", rnd=8, date="2012-06-24", laps=57, base=100.5, pit=20.0, diff=0.8, rain=0.05, wear=0.95,
         profile=(0.35, 0.50, 0.15), night=False,
         scenery={"theme": "harbor", "landmarks": ["bridge"], "trees": 0.05, "city": 0.5, "street": True,
                  "kerbs": ["#d42020", "#f2f2f2"], "spans": {"bridge": [0.468, 0.488]}},
         elevation=[[0.0, 0.0], [0.47, 0.0], [0.478, 4.0], [0.488, 0.0], [1.0, 0.0]]),
    dict(id="yeongam", osm="yeongam", gp="GP da Coreia", name="Korea International Circuit", short="Yeongam", country="Coreia do Sul",
         cc="kr", city="Yeongam", rnd=16, date="2012-10-14", laps=55, base=100.5, pit=20.0, diff=0.4, rain=0.25, wear=1.05,
         profile=(0.45, 0.35, 0.20), night=False,
         scenery={"theme": "coast", "landmarks": ["wing_stand"], "trees": 0.06, "city": 0.06, "kerbs": ["#d42020", "#f2f2f2"]},
         elevation=[[0.0, 0.0], [0.3, 1.0], [0.6, 3.0], [0.85, 1.0], [1.0, 0.0]]),
    dict(id="buddh", osm="buddh", gp="GP da Índia", name="Buddh International Circuit", short="Buddh", country="Índia",
         cc="in", city="Greater Noida", rnd=17, date="2012-10-28", laps=60, base=87.0, pit=19.0, diff=0.4, rain=0.02, wear=1.0,
         profile=(0.40, 0.25, 0.35), night=False,
         scenery={"theme": "prairie", "landmarks": ["wing_stand"], "trees": 0.05, "ground": "#a39a66", "kerbs": ["#d42020", "#f2f2f2"]},
         elevation=[[0.0, 0.0], [0.06, 6.0], [0.12, 14.0], [0.3, 8.0], [0.5, 2.0], [0.7, 4.0], [0.9, 1.0], [1.0, 0.0]]),
]

TRACKS_DIR = ROOT / "tools" / "osm_tracks"


def pit_fracs(pts, length):
    n = len(pts)
    cum = [0.0]
    for i in range(n):
        cum.append(cum[-1] + math.dist(pts[i], pts[(i + 1) % n]))

    def ang(i):
        k = 1
        while cum[min(i + k, n)] - cum[i] < 30 and k < n // 4:
            k += 1
        a, b, c = pts[(i - k) % n], pts[i], pts[(i + k) % n]
        v1 = (b[0] - a[0], b[1] - a[1])
        v2 = (c[0] - b[0], c[1] - b[1])
        return abs(math.degrees(math.atan2(v1[0] * v2[1] - v1[1] * v2[0], v1[0] * v2[0] + v1[1] * v2[1])))
    fr = [cum[i] / length for i in range(n)]
    last = [fr[i] for i in range(n) if fr[i] > 0.78 and ang(i) > 22]
    first = [fr[i] for i in range(n) if fr[i] < 0.22 and ang(i) > 22]
    e = min(max((max(last) + 0.008) if last else 0.95, 0.86), 0.985)
    x = min(max((min(first) - 0.010) if first else 0.05, 0.025), 0.14)
    return round(e, 3), round(x, 3)


def main():
    src = pathlib.Path(sys.argv[1])
    only = set(sys.argv[2:])
    for t in TRACKS:
        if only and t["id"] not in only:
            continue
        path = TRACKS_DIR / f"{t['osm']}.geojson" if "osm" in t else src / "circuits" / f"{t['geo']}.geojson"
        g = json.loads(path.read_text(encoding="utf-8"))
        length = float(g["features"][0]["properties"]["length"])
        pts = project(g["features"][0]["geometry"]["coordinates"])
        s = length / sum(math.dist(pts[i], pts[(i + 1) % len(pts)]) for i in range(len(pts)))
        pts = [(x * s, y * s) for x, y in pts]
        runs = straights(pts, length)[:3]
        names = ["Reta principal", "Segunda reta", "Terceira reta"]
        zones = [{"name": names[i], "braking_frac": round((b % length) / length, 3), "strength": [1.0, 0.8, 0.4][i]}
                 for i, (a, b) in enumerate(runs)]
        e, x = pit_fracs(pts, length)
        sc = dict(t["scenery"])
        sc["landmark"] = sc["landmarks"][0] if sc["landmarks"] else ""
        data = {
            "id": t["id"], "name": t["name"], "short_name": t["short"], "grand_prix": t["gp"], "country": t["country"],
            "country_code": t["cc"], "city": t["city"], "round": t["rnd"], "date": t["date"], "sprint": False, "night": t["night"],
            "length_m": length, "laps": t["laps"], "base_lap_time_s": t["base"], "pit_lane_loss_s": t["pit"],
            "pit_entry_frac": e, "pit_box_frac": 0.0, "pit_exit_frac": x, "tyre_wear_factor": t["wear"],
            "overtaking_difficulty": t["diff"], "overtaking_zones": zones,
            "profile": {"straight": t["profile"][0], "slow": t["profile"][1], "fast": t["profile"][2]},
            "rain_probability": t["rain"], "scenery": sc, "elevation": t["elevation"], "season": 2012,
            "_notas": {
                "tracado": (f"OpenStreetMap (© colaboradores do OSM, ODbL 1.0) via tools/osm_tracks/{t['osm']}.geojson, escalado para {int(length)} m"
                            if "osm" in t else f"bacinger/f1-circuits {t['geo']}.geojson (MIT), escalado para {int(length)} m"),
                "provisorio": "base_lap_time_s, pit_lane_loss_s, overtaking_difficulty, rain_probability, desgaste e relevo são PROVISÓRIOS",
                "zonas": "pontos de freada ao fim das 3 maiores retas, calculados pela geometria",
                "box": "entrada/saída do pit lane calculadas pela geometria; PROVISÓRIO",
                "temporada": "pista extra (temporada 2012); no Grande Prêmio fica disponível para qualquer temporada/categoria",
            },
            "points": [[round(px, 1), round(py, 1)] for px, py in pts],
        }
        (OUT / f"{t['id']}.json").write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding="utf-8")
        print(t["id"], int(length), "m", "zonas", [z["braking_frac"] for z in zones], "box", e, x)


if __name__ == "__main__":
    main()
