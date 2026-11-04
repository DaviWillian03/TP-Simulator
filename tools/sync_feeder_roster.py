"""Alinha a base F2/F3 de 2026 com o elenco oficial enviado pelo usuário (zip com fotos e logos, fontes fiaformula2.com e
fiaformula3.com, conferido em 2026-11-04): equipe de cada piloto (series_team) e pilotos que faltavam.
Notas dos que entram: ESTIMATIVA do projeto (estreantes da F3 ~52–60; Herta = topo da F2). Idempotente.
Uso: python tools/sync_feeder_roster.py   (depois: python tools/add_ages.py)
"""
import json
import pathlib

DATA = pathlib.Path(__file__).resolve().parent.parent / "game" / "data"
TEAMS = {"invictaracing": "Invicta Racing", "damslucasoil": "DAMS Lucas Oil", "premaracing": "Prema Racing", "artgrandprix": "ART Grand Prix",
         "hitech": "Hitech", "aixracing": "AIX Racing", "camposracing": "Campos Racing", "trident": "Trident", "mpmotorsport": "MP Motorsport",
         "vanamersfoortracing": "Van Amersfoort Racing", "rodinmotorsport": "Rodin Motorsport"}
# id: (categoria, equipe, nome, nacionalidade, nota)
ROSTER = {
 "F2": {"invictaracing": ["rafael_camara", "joshua_durksen"], "damslucasoil": ["roman_bilinski", "dino_beganovic"],
        "premaracing": ["sebastian_montoya", "mari_boya"], "artgrandprix": ["kush_maini", "tasanapol_inthraphuvasak"],
        "hitech": ["ritomo_miyata", "colton_herta"], "aixracing": ["cian_shields", "emerson_fittipaldi"],
        "camposracing": ["noel_leon", "nikola_tsolov"], "trident": ["john_bennett", "laurens_van_hoepen"],
        "mpmotorsport": ["oliver_goethe", "gabriele_mini"], "vanamersfoortracing": ["rafael_villagomez", "nico_varrone"],
        "rodinmotorsport": ["alexander_dunne", "martinius_stenshorne"]},
 "F3": {"aixracing": ["yevan_david", "brad_benavides", "fernando_barrichello", "salim_hanna", "ricardo_escotto"],
        "damslucasoil": ["nandhavud_bhirombhakdi", "nicola_lacorte", "gerrard_xie"],
        "rodinmotorsport": ["niccolo_maccagnani", "pedro_clerot", "brando_badoer", "christian_ho"],
        "mpmotorsport": ["alessandro_giusti", "tuukka_taponen", "mattia_colnaghi"],
        "artgrandprix": ["maciej_gadysz", "kanato_le", "taito_kato"],
        "premaracing": ["louis_sharp", "james_wharton", "jose_garfias", "alex_powell"],
        "hitech": ["michael_shin", "jin_nakamura", "fionn_mclaughlin"],
        "trident": ["matteo_de_palo", "noah_strmsted", "freddie_slater"],
        "vanamersfoortracing": ["hiyu_yamakoshi", "bruno_del_pino", "enzo_deligny"],
        "camposracing": ["patrick_heuzenroeder", "ernesto_rivera", "theophile_nael", "ugo_ugochukwu"]},
}
NEW = {  # pilotos que faltavam: nome, nacionalidade, nota (estimativa)
 "colton_herta": ("Colton Herta", "Estados Unidos", 78), "nico_varrone": ("Nicolás Varrone", "Argentina", 68),
 "louis_sharp": ("Louis Sharp", "Nova Zelândia", 60), "christian_ho": ("Christian Ho", "Singapura", 57),
 "alex_powell": ("Alex Powell", "Jamaica", 58), "patrick_heuzenroeder": ("Patrick Heuzenroeder", "Austrália", 55),
 "niccolo_maccagnani": ("Niccolò Maccagnani", "Itália", 56), "brad_benavides": ("Brad Benavides", "Estados Unidos", 55),
 "ricardo_escotto": ("Ricardo Escotto", "México", 54), "salim_hanna": ("Salim Hanna", "Colômbia", 52),
}
f = DATA / "drivers_feeder_2026.json"
d = json.loads(f.read_text(encoding="utf-8"))
by_id = {x["id"]: x for x in d["drivers"]}
for cat, teams in ROSTER.items():
    for team, ids in teams.items():
        for i in ids:
            if i not in by_id:
                name, nat, rating = NEW[i]
                by_id[i] = {"id": i, "name": name, "nationality": nat, "category": cat, "rating": rating}
                d["drivers"].append(by_id[i])
            x = by_id[i]
            x["category"] = cat
            x["series_team"] = TEAMS[team]
            x["series_team_id"] = team
d["_notas"]["elenco"] = "Equipes e pilotos de 2026 conferidos com o elenco oficial enviado pelo usuário (2026-11-04); notas dos novos = estimativa."
f.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding="utf-8")
a = DATA / "free_agents.json"
fa = json.loads(a.read_text(encoding="utf-8"))
fa["drivers"] = [x for x in fa["drivers"] if x["id"] != "colton_herta"]  # está na F2 (Hitech) em 2026
a.write_text(json.dumps(fa, ensure_ascii=False, indent=1), encoding="utf-8")
print("F2", sum(1 for x in d["drivers"] if x["category"] == "F2"), "F3", sum(1 for x in d["drivers"] if x["category"] == "F3"))
