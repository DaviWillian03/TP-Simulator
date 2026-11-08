"""Engenheiros de corrida de 2026 (1 por carro) e mercado de engenheiros genéricos (decisão do usuário, 2026-11-08).
Nomes reais com fonte (pesquisa de 08/11/2026: motorsport.com "Every race engineer in F1 2026", Motor Sport Magazine,
GPFans, RacingNews365). Notas = ESTIMATIVA do projeto (experiência e reputação), PROVISÓRIO. Hamilton: Carlo Santi interino
(Ferrari não anunciou um efetivo). Genéricos: nomes do name_pool.json.
Uso: python tools/make_race_engineers.py  ->  game/data/race_engineers_2026.json
"""
import json
import pathlib
import random

ROOT = pathlib.Path(__file__).resolve().parent.parent
REAL = [  # piloto, equipe, engenheiro, nota
    ("norris", "mclaren", "Will Joseph", 88), ("piastri", "mclaren", "Tom Stallard", 86),
    ("verstappen", "redbull", "Gianpiero Lambiase", 93), ("hadjar", "redbull", "Richard Wood", 80),
    ("leclerc", "ferrari", "Bryan Bozzi", 85), ("hamilton", "ferrari", "Carlo Santi", 76),
    ("russell", "mercedes", "Marcus Dudley", 84), ("antonelli", "mercedes", "Peter Bonnington", 91),
    ("albon", "williams", "James Urwin", 82), ("sainz", "williams", "Gaëtan Jago", 82),
    ("alonso", "astonmartin", "Chris Cronin", 81), ("stroll", "astonmartin", "Gary Gannon", 79),
    ("lawson", "racingbulls", "Alexandre Iliopoulos", 76), ("lindblad", "racingbulls", "Pierre Hamelin", 78),
    ("gasly", "alpine", "Josh Peckett", 79), ("colapinto", "alpine", "Stuart Barlow", 78),
    ("ocon", "haas", "Laura Mueller", 80), ("bearman", "haas", "Ronan O'Hare", 78),
    ("perez", "cadillac", "Carlo Pasetti", 80), ("bottas", "cadillac", "John Howard", 79),
    ("hulkenberg", "audi", "Steven Petrik", 79), ("bortoleto", "audi", "José Manuel López", 79),
]
SOURCES = ["https://au.motorsport.com/f1/news/every-race-engineer-f1-2026/10807005/",
           "https://www.motorsportmagazine.com/articles/single-seaters/f1/who-are-all-the-f1-race-engineers-in-2026/",
           "https://www.gpfans.com/en/f1-news/1076588/f1-race-engineers/",
           "https://www.gpfans.com/en/f1-news/1075867/lewis-hamilton-ferrari-f1-race-engineer-carlo-santi-interim/"]

names = json.loads((ROOT / "game/data/name_pool.json").read_text(encoding="utf-8"))["nationalities"]
rng = random.Random(2026)
people = []
for drv, team, name, skill in REAL:
    pid = "re_" + name.lower().replace(" ", "_").replace("'", "").replace("é", "e").replace("ë", "e").replace("ó", "o")
    people.append({"id": pid, "name": name, "role": "race_engineer", "team": team, "driver": drv, "skill": skill, "real": True})
used = set()
for i in range(14):  # mercado: engenheiros genéricos sem equipe
    nat = rng.choice(sorted(names))
    pool = names[nat]
    while True:
        n = f'{rng.choice(pool["first"])} {rng.choice(pool["last"])}'
        if n not in used:
            used.add(n)
            break
    people.append({"id": f"re_gen_{i}", "name": n, "nationality": nat, "role": "race_engineer", "team": "", "driver": "",
                   "skill": rng.randint(62, 84), "real": False})
out = {"_notas": __doc__.strip().split("\n")[1] + " Notas estimadas (PROVISÓRIO).", "sources": SOURCES, "people": people}
(ROOT / "game/data/race_engineers_2026.json").write_text(json.dumps(out, ensure_ascii=False, indent=1), encoding="utf-8")
print("ok", len(people))
