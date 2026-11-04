"""Equipes e calendários da F2 e da F3 de 2026 para a campanha em 3 categorias (fase 1, 2026-11-04).
Nomes reais das equipes (decisão do usuário); emblemas ORIGINAIS no jogo (forma + cores); logos oficiais só em game/local/.
Cores aproximadas de cada equipe; nota do carro quase igual (carros iguais na F2/F3: ~30% carro). Calendários: rodadas da F1
de 2026 em que F2/F3 correm juntas — PROVISÓRIO (aproximação com as pistas do jogo).
Uso: python tools/make_feeder_teams.py  ->  game/data/feeder_teams_2026.json
"""
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
FEED = json.loads((ROOT / "game/data/drivers_feeder_2026.json").read_text(encoding="utf-8"))["drivers"]
COLORS = {  # cor principal, cor secundária, forma do emblema
    "aixracing": ("#7B2CBF", "#FFFFFF", "hex"), "artgrandprix": ("#1B1D22", "#F2F2F2", "square"), "camposracing": ("#E10600", "#FFFFFF", "shield"),
    "damslucasoil": ("#1E5BC6", "#FFD24A", "circle"), "hitech": ("#C0C6CF", "#11141A", "diamond"), "invictaracing": ("#0B0C0F", "#D4A017", "shield"),
    "mpmotorsport": ("#FF8000", "#11141A", "hex"), "premaracing": ("#D4001A", "#FFFFFF", "square"), "rodinmotorsport": ("#00A3E0", "#FFFFFF", "circle"),
    "trident": ("#0A2A6E", "#FFFFFF", "diamond"), "vanamersfoortracing": ("#FF6A00", "#0B0C0F", "hex"),
}
RATING = {"F2": 60.0, "F3": 55.0}  # base do carro; pequenas diferenças por equipe (o piloto pesa mais)
SPREAD = {"premaracing": 1.5, "artgrandprix": 1.2, "camposracing": 1.0, "invictaracing": 1.2, "hitech": 0.8, "mpmotorsport": 0.6,
          "rodinmotorsport": 0.4, "damslucasoil": 0.0, "trident": -0.4, "vanamersfoortracing": -0.6, "aixracing": -1.0}
CALENDAR = {  # índices das rodadas da F1 (game/data/calendar_2026.json)
    "F2": [0, 3, 5, 6, 7, 8, 9, 10, 12, 13, 14, 15, 20, 21],
    "F3": [0, 5, 6, 7, 8, 9, 10, 12, 13, 14],
}

out = {"_notas": __doc__.strip().split("\n")[1], "series": {}}
for cat in ("F2", "F3"):
    teams = {}
    for d in FEED:
        if d["category"] == cat and d.get("series_team_id"):
            teams[d["series_team_id"]] = d["series_team"]
    rows = []
    for tid in sorted(teams):
        c1, c2, shape = COLORS[tid]
        short = "".join(w[0] for w in teams[tid].split()[:2]).upper()
        rows.append({"id": f"{cat.lower()}_{tid}", "base_id": tid, "name": teams[tid], "color": c1, "color2": c2, "shape": shape,
                     "short_name": short, "car_rating": RATING[cat] + SPREAD.get(tid, 0.0)})
    out["series"][cat] = {"seats": 2 if cat == "F2" else 3, "teams": rows, "rounds": CALENDAR[cat],
                          "points_feature": [25, 18, 15, 12, 10, 8, 6, 4, 2, 1], "points_sprint": [10, 8, 6, 5, 4, 3, 2, 1]}
(ROOT / "game/data/feeder_teams_2026.json").write_text(json.dumps(out, ensure_ascii=False, indent=1), encoding="utf-8")
print("ok", {k: len(v["teams"]) for k, v in out["series"].items()})
