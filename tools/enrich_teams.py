"""Acrescenta dados reais às equipes de game/data/teams_2026.json: chefe de equipe, diretor técnico, ano de
fundação (estreia na F1 com este nome/estrutura) e títulos de construtores até o fim de 2025.
Chefes de equipe: RacingNews365 (14/01/2026). Diretor técnico: só onde há fonte recente (RacingNews365/PlanetF1/ESPN em 2026).
Nota do carro (car_rating) = 74 + 19 * raiz(pontos / pontos do líder) com os pontos de construtores da ESPN após 20 rodadas
(tools/research/snapshot_2026-11-02.json). O que não tem fonte fica null ("—" no jogo). Uso: python tools/enrich_teams.py
"""
import json
import math
import pathlib

SNAP = json.loads((pathlib.Path(__file__).resolve().parent / "research" / "snapshot_2026-11-02.json").read_text(encoding="utf-8"))

P = pathlib.Path(__file__).resolve().parent.parent / "game" / "data" / "teams_2026.json"
# id: (chefe de equipe, diretor técnico, estreia, títulos de construtores)
T = {
    "mclaren": ("Andrea Stella", None, 1966, 10),
    "mercedes": ("Toto Wolff", None, 2010, 8),
    "ferrari": ("Frédéric Vasseur", None, 1950, 16),
    "redbull": ("Laurent Mekies", "Pierre Waché", 2005, 6),
    "williams": ("James Vowles", None, 1978, 9),
    "racingbulls": ("Alan Permane", "Dan Fallows", 2006, 0),
    "astonmartin": ("Adrian Newey", None, 2021, 0),
    "haas": ("Ayao Komatsu", None, 2016, 0),
    "alpine": (None, "Mike Elliott", 2021, None),
    "audi": ("Jonathan Wheatley", None, 2026, 0),
    "cadillac": ("Graeme Lowdon", "Nick Chester", 2026, 0),
}
d = json.loads(P.read_text(encoding="utf-8"))
for t in d["teams"]:
    tp, td, debut, titles = T[t["id"]]
    t["principal"] = tp
    t["technical_director"] = td
    t["debut"] = debut
    t["constructors_titles"] = titles
    lead = max(SNAP["team_points"].values())
    t["car_rating"] = round(74 + 19 * math.sqrt(SNAP["team_points"][t["id"]] / lead), 1)
    t["points_2026"] = SNAP["team_points"][t["id"]]
d["_notas"] = ("Nomes reais por decisão do usuário; sem logos oficiais. car_rating = função dos pontos de construtores de 2026 após 20 rodadas (pesquisa 02/11/2026). "
               "principal/technical_director/debut/constructors_titles: só dados com fonte; null = a verificar. 'emblem' = emblema ORIGINAL.")
P.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding="utf-8")
print("ok")
