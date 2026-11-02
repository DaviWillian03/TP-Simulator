"""Acrescenta dados reais às equipes de game/data/teams_2026.json: chefe de equipe, diretor técnico, ano de
fundação (estreia na F1 com este nome/estrutura) e títulos de construtores até o fim de 2025.
Só entra o que é confirmado por duas fontes ou é fato público bem estabelecido; o resto fica null (aparece "—" no jogo)
até a pesquisa em fontes confiáveis. Uso: python tools/enrich_teams.py
"""
import json
import pathlib

P = pathlib.Path(__file__).resolve().parent.parent / "game" / "data" / "teams_2026.json"
# id: (chefe de equipe, diretor técnico, estreia, títulos de construtores)
T = {
    "mclaren": ("Andrea Stella", None, 1966, 10),
    "mercedes": ("Toto Wolff", "James Allison", 2010, 8),
    "ferrari": ("Frédéric Vasseur", None, 1950, 16),
    "redbull": ("Laurent Mekies", "Pierre Waché", 2005, 6),
    "williams": ("James Vowles", "Pat Fry", 1978, 9),
    "racingbulls": ("Alan Permane", None, 2006, 0),
    "astonmartin": (None, None, 2021, 0),
    "haas": ("Ayao Komatsu", None, 2016, 0),
    "alpine": (None, None, 2021, None),
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
d["_notas"] = d.get("_notas", "") + " principal/technical_director/debut/constructors_titles: só dados confirmados; null = a verificar."
P.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding="utf-8")
print("ok")
