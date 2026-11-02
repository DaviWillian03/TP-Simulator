"""Acrescenta atributos e dados biográficos aos pilotos de game/data/drivers_2026.json (reprodutível).
- birth, titles: fatos públicos (data de nascimento; títulos mundiais até o fim de 2025).
- attrs (0-100): pace, quali, consistency, racecraft, wet, tyres e potential: ESTIMATIVA do projeto a partir dos
  resultados de 2024-2025 e da reputação (PROVISÓRIO; substituir após a pesquisa em sites especializados).
- rating = média ponderada dos atributos (nota geral usada em todo o jogo).
Altura, peso, vitórias, pódios e poles ficam fora até serem confirmados em fonte confiável (nada inventado).
Uso: python tools/enrich_drivers.py
"""
import json
import pathlib

P = pathlib.Path(__file__).resolve().parent.parent / "game" / "data" / "drivers_2026.json"
WEIGHTS = {"pace": 0.30, "quali": 0.15, "consistency": 0.15, "racecraft": 0.20, "wet": 0.10, "tyres": 0.10}
# id: (nascimento, títulos, pace, quali, consistency, racecraft, wet, tyres, potential)
T = {
    "verstappen": ("1997-09-30", 4, 97, 97, 92, 96, 95, 88, 97),
    "norris": ("1999-11-13", 1, 94, 94, 86, 90, 88, 88, 95),
    "piastri": ("2001-04-06", 0, 93, 92, 92, 92, 86, 88, 94),
    "russell": ("1998-02-15", 0, 93, 95, 90, 89, 90, 85, 93),
    "antonelli": ("2006-08-25", 0, 88, 88, 78, 84, 86, 80, 94),
    "leclerc": ("1997-10-16", 0, 94, 97, 82, 90, 91, 80, 94),
    "hamilton": ("1985-01-07", 7, 91, 90, 86, 92, 96, 90, 90),
    "hadjar": ("2004-09-28", 0, 85, 84, 76, 82, 80, 80, 90),
    "albon": ("1996-03-23", 0, 87, 85, 86, 86, 84, 88, 87),
    "sainz": ("1994-09-01", 0, 89, 91, 87, 86, 85, 86, 88),
    "lawson": ("2002-02-11", 0, 82, 82, 76, 80, 78, 78, 86),
    "lindblad": ("2007-08-08", 0, 81, 80, 72, 78, 78, 76, 90),
    "alonso": ("1981-07-29", 2, 90, 90, 90, 95, 93, 92, 88),
    "stroll": ("1998-10-29", 0, 79, 76, 76, 76, 82, 78, 80),
    "ocon": ("1996-09-17", 0, 83, 84, 82, 84, 82, 82, 84),
    "bearman": ("2005-05-08", 0, 84, 83, 78, 83, 80, 80, 90),
    "gasly": ("1996-02-07", 0, 86, 85, 84, 85, 86, 84, 86),
    "colapinto": ("2003-05-27", 0, 81, 80, 74, 80, 76, 76, 86),
    "hulkenberg": ("1987-08-19", 0, 84, 88, 86, 82, 84, 84, 84),
    "bortoleto": ("2004-10-14", 0, 84, 83, 76, 82, 78, 78, 90),
    "perez": ("1990-01-26", 0, 82, 80, 76, 84, 82, 86, 82),
    "bottas": ("1989-08-28", 0, 82, 82, 84, 80, 80, 84, 82),
}

d = json.loads(P.read_text(encoding="utf-8"))
for drv in d["drivers"]:
    birth, titles, pace, quali, cons, race, wet, tyres, pot = T[drv["id"]]
    attrs = {"pace": pace, "quali": quali, "consistency": cons, "racecraft": race, "wet": wet, "tyres": tyres}
    drv["birth"] = birth
    drv["titles"] = titles
    drv["attrs"] = attrs
    drv["potential"] = pot
    drv["rating"] = round(sum(attrs[k] * w for k, w in WEIGHTS.items()))
d["_notas"] = ("Grid oficial de 2026. birth/titles: fatos públicos até o fim de 2025. attrs/potential: ESTIMATIVA do projeto "
               "(PROVISÓRIO, tools/enrich_drivers.py). rating = média ponderada dos atributos. Altura, peso, vitórias e pódios "
               "entram só com fonte confirmada.")
P.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding="utf-8")
print("ok", [(x["id"], x["rating"]) for x in d["drivers"]][:6])
