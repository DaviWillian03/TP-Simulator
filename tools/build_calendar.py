"""Gera os dados dos 22 circuitos do calendário 2026 (game/data/circuits/*.json) e o
calendário (game/data/calendar_2026.json).

Traçados: https://github.com/bacinger/f1-circuits (MIT), clonado em ../refs/f1-circuits
ou no caminho passado como argumento. Metadados abaixo: valores de corrida PROVISÓRIOS
(tempo base, perda no box, dificuldade de ultrapassagem, chance de chuva), a calibrar na
pesquisa. Calendário confirmado por busca em 2026-11-01: Bahrein e Arábia Saudita cancelados
(22 GPs); sprints em China, Miami, Canadá, Grã-Bretanha, Holanda e Singapura.

Uso: python tools/build_calendar.py [pasta_f1-circuits]
"""
import json
import math
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "refs/f1-circuits"
OUT = ROOT / "game/data/circuits"
R = 6371000.0

# id, geojson, nome do GP, circuito, nome curto, país, cidade, data (domingo), voltas,
# tempo base (s), perda no box (s), dificuldade de ultrapassagem (0..1), chance de chuva,
# sprint, noturna, tema do cenário, marco visual
CAL = [
    ("albertpark", "au-1953", "GP da Austrália", "Albert Park", "Melbourne", "Austrália", "Melbourne", "2026-03-08", 58, 79.0, 19.0, 0.5, 0.15, False, False, "lake", "lake"),
    ("shanghai", "cn-2004", "GP da China", "Shanghai International Circuit", "Xangai", "China", "Xangai", "2026-03-15", 56, 93.5, 23.0, 0.35, 0.2, True, False, "city", "grandstand_wings"),
    ("suzuka", "jp-1962", "GP do Japão", "Suzuka International Racing Course", "Suzuka", "Japão", "Suzuka", "2026-03-29", 53, 90.0, 22.0, 0.7, 0.3, False, False, "forest", "ferris_wheel"),
    ("miami", "us-2022", "GP de Miami", "Miami International Autodrome", "Miami", "Estados Unidos", "Miami", "2026-05-03", 57, 88.5, 20.0, 0.45, 0.25, True, False, "coast", "stadium"),
    ("montreal", "ca-1978", "GP do Canadá", "Circuit Gilles-Villeneuve", "Montreal", "Canadá", "Montreal", "2026-05-24", 70, 73.0, 18.0, 0.35, 0.3, True, False, "river", "biosphere"),
    ("monaco", "mc-1929", "GP de Mônaco", "Circuit de Monaco", "Mônaco", "Mônaco", "Monte Carlo", "2026-06-07", 78, 72.5, 20.0, 0.95, 0.15, False, False, "harbor", "yachts"),
    ("barcelona", "es-1991", "GP da Espanha", "Circuit de Barcelona-Catalunya", "Barcelona", "Espanha", "Montmeló", "2026-06-14", 66, 76.0, 21.0, 0.6, 0.1, False, False, "hills", "grandstand"),
    ("spielberg", "at-1969", "GP da Áustria", "Red Bull Ring", "Spielberg", "Áustria", "Spielberg", "2026-06-28", 71, 66.0, 20.0, 0.35, 0.3, False, False, "mountains", "mountains"),
    ("silverstone", "gb-1948", "GP da Grã-Bretanha", "Silverstone Circuit", "Silverstone", "Reino Unido", "Silverstone", "2026-07-05", 52, 88.0, 20.0, 0.45, 0.35, True, False, "airfield", "hangars"),
    ("spa", "be-1925", "GP da Bélgica", "Circuit de Spa-Francorchamps", "Spa", "Bélgica", "Stavelot", "2026-07-19", 44, 105.5, 18.0, 0.3, 0.45, False, False, "forest", "hills"),
    ("hungaroring", "hu-1986", "GP da Hungria", "Hungaroring", "Hungaroring", "Hungria", "Mogyoród", "2026-07-26", 70, 79.0, 20.0, 0.8, 0.15, False, False, "hills", "grandstand"),
    ("zandvoort", "nl-1948", "GP da Holanda", "Circuit Zandvoort", "Zandvoort", "Países Baixos", "Zandvoort", "2026-08-23", 72, 72.5, 21.0, 0.8, 0.3, True, False, "dunes", "sea"),
    ("monza", "it-1922", "GP da Itália", "Autodromo Nazionale Monza", "Monza", "Itália", "Monza", "2026-09-06", 53, 81.5, 23.0, 0.25, 0.15, False, False, "park", "trees"),
    ("madring", "es-2026", "GP de Madri", "Circuito de Madring", "Madri", "Espanha", "Madri", "2026-09-13", 57, 87.0, 21.0, 0.55, 0.1, False, False, "city", "towers"),
    ("baku", "az-2016", "GP do Azerbaijão", "Baku City Circuit", "Baku", "Azerbaijão", "Baku", "2026-09-26", 51, 104.0, 20.0, 0.3, 0.05, False, False, "oldcity", "flame_towers"),
    ("singapore", "sg-2008", "GP de Singapura", "Marina Bay Street Circuit", "Singapura", "Singapura", "Singapura", "2026-10-11", 62, 93.5, 28.0, 0.85, 0.3, True, True, "bay", "ferris_wheel"),
    ("austin", "us-2012", "GP dos Estados Unidos", "Circuit of the Americas", "Austin", "Estados Unidos", "Austin", "2026-10-25", 56, 96.5, 20.0, 0.4, 0.1, False, False, "prairie", "tower"),
    ("mexico", "mx-1962", "GP da Cidade do México", "Autódromo Hermanos Rodríguez", "Cidade do México", "México", "Cidade do México", "2026-11-01", 71, 80.0, 22.0, 0.45, 0.1, False, False, "city", "stadium"),
    ("interlagos", "br-1940", "GP de São Paulo", "Autódromo José Carlos Pace", "Interlagos", "Brasil", "São Paulo", "2026-11-08", 71, 72.0, 21.0, 0.35, 0.35, False, False, "lake", "skyline"),
    ("lasvegas", "us-2023", "GP de Las Vegas", "Las Vegas Strip Circuit", "Las Vegas", "Estados Unidos", "Las Vegas", "2026-11-21", 50, 95.5, 20.0, 0.3, 0.02, False, True, "strip", "sphere"),
    ("lusail", "qa-2004", "GP do Catar", "Lusail International Circuit", "Lusail", "Catar", "Lusail", "2026-11-29", 57, 84.5, 26.0, 0.55, 0.01, False, True, "desert", "lights"),
    ("yasmarina", "ae-2009", "GP de Abu Dhabi", "Yas Marina Circuit", "Yas Marina", "Emirados Árabes Unidos", "Abu Dhabi", "2026-12-06", 58, 87.0, 22.0, 0.5, 0.01, False, True, "marina", "hotel"),
]


# Relevo APROXIMADO (fração da volta, altura relativa em metros), modelado à mão a partir das
# subidas/descidas conhecidas. Pistas sem entrada aqui ficam planas por enquanto.
ELEVATION = {
    "interlagos": [[0.0, 0.0], [0.064, -9.0], [0.17, -16.0], [0.314, -22.0], [0.4, -25.0], [0.461, -27.0],
                   [0.6, -21.0], [0.75, -29.0], [0.86, -35.0], [0.93, -18.0], [1.0, 0.0]],
}


def project(coords):
    lat0 = sum(c[1] for c in coords) / len(coords)
    lon0 = sum(c[0] for c in coords) / len(coords)
    k = math.pi / 180 * R
    pts = [((c[0] - lon0) * math.cos(math.radians(lat0)) * k, -(c[1] - lat0) * k) for c in coords]
    if math.dist(pts[0], pts[-1]) < 0.5:
        pts = pts[:-1]
    return pts


def straights(pts, total):
    cum = [0.0]
    for i in range(len(pts)):
        cum.append(cum[-1] + math.dist(pts[i], pts[(i + 1) % len(pts)]))
    head = [math.atan2(pts[(i + 1) % len(pts)][1] - pts[i][1], pts[(i + 1) % len(pts)][0] - pts[i][0]) for i in range(len(pts))]
    runs, start = [], 0
    for i in range(1, len(head)):
        if abs((head[i] - head[start] + math.pi) % (2 * math.pi) - math.pi) > math.radians(12):
            runs.append((cum[start], cum[i]))
            start = i
    runs.append((cum[start], cum[-1]))
    # junta a última reta com a primeira se forem contínuas (reta que cruza a linha de chegada)
    if len(runs) > 1 and abs((head[0] - head[-1] + math.pi) % (2 * math.pi) - math.pi) < math.radians(12):
        a0, b0 = runs[0]
        a1, b1 = runs.pop()
        runs[0] = (a1 - total, b0)
    return sorted(runs, key=lambda r: r[1] - r[0], reverse=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    calendar = []
    for rnd, row in enumerate(CAL, start=1):
        (cid, geo, gp, name, short, country, city, date, laps, base, pit, diff, rain,
         sprint, night, theme, landmark) = row
        g = json.loads((SRC / "circuits" / f"{geo}.geojson").read_text(encoding="utf-8"))
        props = g["features"][0]["properties"]
        length = float(props["length"])
        pts = project(g["features"][0]["geometry"]["coordinates"])
        src_len = sum(math.dist(pts[i], pts[(i + 1) % len(pts)]) for i in range(len(pts)))
        s = length / src_len
        pts = [(x * s, y * s) for x, y in pts]
        runs = straights(pts, length)[:3]
        names = ["Reta principal", "Segunda reta", "Terceira reta"]
        zones = [{"name": names[i], "braking_frac": round((b % length) / length, 3), "strength": [1.0, 0.8, 0.4][i]}
                 for i, (a, b) in enumerate(runs)]
        data = {
            "id": cid, "name": name, "short_name": short, "grand_prix": gp, "country": country, "city": city,
            "round": rnd, "date": date, "sprint": sprint, "night": night,
            "length_m": length, "laps": laps, "base_lap_time_s": base, "pit_lane_loss_s": pit,
            "pit_entry_frac": 0.95, "pit_box_frac": 0.0, "pit_exit_frac": 0.05,
            "tyre_wear_factor": 1.0, "overtaking_difficulty": diff, "overtaking_zones": zones,
            "rain_probability": rain, "scenery": {"theme": theme, "landmark": landmark},
            "elevation": ELEVATION.get(cid, []),
            "_notas": {
                "tracado": f"bacinger/f1-circuits {geo}.geojson (MIT), escalado para {int(length)} m",
                "provisorio": "base_lap_time_s, pit_lane_loss_s, overtaking_difficulty, rain_probability e posição do box são PROVISÓRIOS",
                "zonas": "pontos de freada ao fim das 3 maiores retas, calculados pela geometria",
                "relevo": "elevation = [fração, metros] APROXIMADO, modelado à mão; vazio = plana",
            },
            "points": [[round(x, 1), round(y, 1)] for x, y in pts],
        }
        if cid == "interlagos":  # mantém os valores já calibrados no Marco 1
            data.update({"pit_entry_frac": 0.905, "pit_exit_frac": 0.065})
        (OUT / f"{cid}.json").write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding="utf-8")
        calendar.append({"round": rnd, "id": cid, "grand_prix": gp, "date": date, "sprint": sprint, "night": night})
    (ROOT / "game/data/calendar_2026.json").write_text(json.dumps({
        "season": 2026,
        "_notas": "22 GPs: Bahrein e Arábia Saudita cancelados (confirmado por busca em 2026-11-01). Datas aproximadas.",
        "rounds": calendar}, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"{len(calendar)} circuitos")


if __name__ == "__main__":
    main()
