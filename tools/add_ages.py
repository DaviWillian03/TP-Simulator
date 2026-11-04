"""Acrescenta ano de nascimento e potencial às categorias de base e aos agentes livres (campanha: idade e aposentadoria).

- Agentes livres (IndyCar/WEC/Fórmula E): datas de nascimento públicas e conhecidas.
- F2/F3: ano de nascimento conhecido quando o Claude tinha segurança; nos demais, ESTIMADO pela categoria
  (F2 ≈ 2004, F3 ≈ 2007) e marcado com "birth_estimated": true (conferir na pesquisa de atributos).
- potential (teto de evolução): ESTIMATIVA do projeto = nota + espaço pela idade (quanto mais novo, mais espaço).
Idempotente. Uso: python tools/add_ages.py
"""
import json
import pathlib

DATA = pathlib.Path(__file__).resolve().parent.parent / "game" / "data"
AGENTS = {"alex_palou": "1997-04-01", "pato_oward": "1999-05-06", "colton_herta": "2000-03-30", "felix_rosenqvist": "1991-11-07",
          "mick_schumacher": "1999-03-22", "antonio_giovinazzi": "1993-12-14", "stoffel_vandoorne": "1992-03-26", "nyck_de_vries": "1995-02-06"}
KNOWN_YEAR = {
    "rafael_camara": 2005, "gabriele_mini": 2005, "alexander_dunne": 2005, "nikola_tsolov": 2006, "joshua_durksen": 2003,
    "ritomo_miyata": 1999, "martinius_stenshorne": 2005, "dino_beganovic": 2004, "sebastian_montoya": 2005, "noel_leon": 2004,
    "kush_maini": 2000, "oliver_goethe": 2004, "mari_boya": 2005, "rafael_villagomez": 2001, "emerson_fittipaldi": 2007,
    "ugo_ugochukwu": 2007, "freddie_slater": 2008, "tuukka_taponen": 2006, "theophile_nael": 2006, "mattia_colnaghi": 2007,
    "james_wharton": 2006, "fernando_barrichello": 2005,
}
DEFAULT_YEAR = {"F2": 2004, "F3": 2007}


def potential(rating, birth_year, season=2026):
    age = season - birth_year
    room = max(0, 27 - age) * 2.6 + 3
    return int(min(95, round(rating + room)))


f = DATA / "drivers_feeder_2026.json"
d = json.loads(f.read_text(encoding="utf-8"))
for x in d["drivers"]:
    y = KNOWN_YEAR.get(x["id"], DEFAULT_YEAR[x["category"]])
    x["birth"] = "%d-01-01" % y
    x["birth_estimated"] = x["id"] not in KNOWN_YEAR
    x["potential"] = potential(x["rating"], y)
d["_notas"]["idades"] = "birth: ano conhecido ou ESTIMADO pela categoria (birth_estimated = true); dia e mês não pesquisados. potential: estimativa do projeto (tools/add_ages.py)."
f.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding="utf-8")

a = DATA / "free_agents.json"
d = json.loads(a.read_text(encoding="utf-8"))
for x in d["drivers"]:
    x["birth"] = AGENTS[x["id"]]
    x["potential"] = max(x["rating"], potential(x["rating"], int(AGENTS[x["id"]][:4])))
a.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding="utf-8")
print("ok")
