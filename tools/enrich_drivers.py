"""Acrescenta atributos e dados biográficos aos pilotos de game/data/drivers_2026.json (reprodutível).
- birth: conferido com a PlanetF1. height_cm/weight_kg: RacingNews365 (altura de 10 pilotos conferida com a PlanetF1; Bearman
  tem fontes em conflito -> null). career (largadas, vitórias, pódios, poles, voltas mais rápidas, títulos): Wikipedia,
  retrato de 02/11/2026 (após o GP do México). Ver tools/research/snapshot_2026-11-02.json.
- attrs (0-100): pace, quali, consistency, racecraft, wet, tyres e potential: ESTIMATIVA do projeto. A nota geral de cada piloto
  é definida pelo usuário (PROFILE); os atributos seguem o perfil de cada um (reputação e estatísticas de carreira).
- rating = média ponderada dos atributos (nota geral usada em todo o jogo).
Altura, peso, vitórias, pódios e poles ficam fora até serem confirmados em fonte confiável (nada inventado).
Uso: python tools/enrich_drivers.py
"""
import json
import pathlib

SNAP = json.loads((pathlib.Path(__file__).resolve().parent / "research" / "snapshot_2026-11-02.json").read_text(encoding="utf-8"))
TEAM_OF = {}  # preenchido a partir do arquivo de pilotos

P = pathlib.Path(__file__).resolve().parent.parent / "game" / "data" / "drivers_2026.json"
WEIGHTS = {"pace": 0.30, "quali": 0.15, "consistency": 0.15, "racecraft": 0.20, "wet": 0.10, "tyres": 0.10}
# id: (nascimento, nota geral ALVO, potencial, perfil)
# perfil = (ritmo, classificação, regularidade, ultrapassagem/defesa, chuva, pneus): pontos acima (+) ou abaixo (-) da nota geral.
# A nota geral é a escolhida pelo usuário (2026-11-03); o perfil vem de reputação pública e das estatísticas de carreira
# (poles, vitórias, pódios em tools/research/snapshot_2026-11-02.json). O código distribui os atributos para que a
# média ponderada (WEIGHTS) bata exatamente com a nota. Continua sendo estimativa do projeto, não dado oficial.
PROFILE = {
    # 4x campeão, 29% de vitórias: ritmo e classificação no topo; gestão de pneus é o ponto "menos" dele
    "verstappen": ("1997-09-30", 96, 97, (3, 3, 1, 3, 2, -4)),
    # 14% de poles (27): a melhor volta de sábado do grid, mas erros em corrida e pneus castigados
    "leclerc": ("1997-10-16", 93, 94, (1, 6, -5, 0, 2, -5)),
    # 7x campeão, 105 poles, rei da chuva; aos 41 perdeu um pouco de ritmo puro
    "hamilton": ("1985-01-07", 92, 92, (-2, -2, 0, 3, 6, 3)),
    # campeão de 2026 com 9 vitórias e 7 poles em 43 largadas, mas ainda comete erros de novato
    "antonelli": ("2006-08-25", 90, 95, (2, 3, -4, -2, 0, -2)),
    # 2x campeão, 444 largadas: o maior racecraft do grid, regular e cuidadoso com pneus; ritmo puro caiu aos 45
    "alonso": ("1981-07-29", 89, 89, (-3, -3, 3, 6, 4, 4)),
    # campeão de 2025: ritmo e classificação de elite, mas deixou pontos por erros
    "norris": ("1999-11-13", 88, 92, (4, 4, -3, -2, 0, 0)),
    # 12 poles, rápido no sábado; defende bem e é regular
    "russell": ("1998-02-15", 87, 90, (0, 4, 1, 0, 2, -2)),
    # estreante de talento, ritmo alto e algum erro; bom em pneus de chuva
    "bearman": ("2005-05-08", 85, 90, (3, 2, -3, 0, -1, -1)),
    # regular e inteligente com pneus; bom em corrida, um pouco atrás no ritmo puro
    "sainz": ("1994-09-01", 84, 85, (-2, 1, 3, 1, 0, 2)),
    # 9 vitórias, muito regular e forte em disputa de posição
    "piastri": ("2001-04-06", 83, 90, (0, 0, 6, 4, -2, 1)),
    # sólido e regular, bom na chuva
    "gasly": ("1996-02-07", 81, 82, (2, 1, 2, 1, 2, 0)),
    # rápido de sábado mas ainda inconstante
    "hadjar": ("2004-09-28", 80, 88, (2, 2, -4, 0, 0, 0)),
    # "Hülk": especialista em classificação e regular
    "hulkenberg": ("1987-08-19", 80, 80, (-2, 6, 4, -2, 1, 2)),
    # famoso por poupar pneus; ritmo de sábado fraco e erros de ritmo
    "perez": ("1990-01-26", 80, 80, (-2, -4, -4, 3, 1, 6)),
    # muito regular e bom em pneus; muito bom na chuva
    "albon": ("1996-03-23", 79, 80, (0, -1, 4, 3, 2, 5)),
    # rápido de ritmo e classificação, mas ainda com erros
    "bortoleto": ("2004-10-14", 78, 88, (4, 4, -3, 0, -2, 0)),
    # defensor duro, regular e bom com pneus; ritmo puro um pouco abaixo
    "ocon": ("1996-09-17", 78, 80, (-3, -2, 3, 5, 2, 3)),
    # rápido em volta lançada, inconsistente
    "lawson": ("2002-02-11", 77, 84, (4, 4, -3, 0, -2, -1)),
    # estreante, ritmo promissor e erros de novato
    "lindblad": ("2007-08-08", 75, 90, (2, 2, -4, 2, 2, 0)),
    # 20 poles com Mercedes, regular e cuidadoso com pneus; racecraft apagado
    "bottas": ("1989-08-28", 75, 75, (0, 1, 5, -3, -1, 4)),
    # corajoso nas disputas, mas inconsistente
    "colapinto": ("2003-05-27", 74, 82, (3, 1, -4, 4, 0, -2)),
    # bom na chuva (vitórias de pódio nela), mas ritmo e classificação modestos
    "stroll": ("1998-10-29", 74, 75, (1, -2, 0, -2, 6, 0)),
}


def distribute(target, profile):
    """Atributos = nota + perfil, com média ponderada exata igual à nota (corrige arredondamento no ritmo/regularidade)."""
    keys = list(WEIGHTS)
    mean = sum(WEIGHTS[k] * v for k, v in zip(keys, profile))
    vals = {k: target + v - mean for k, v in zip(keys, profile)}
    attrs = {k: round(x) for k, x in vals.items()}
    for _ in range(40):
        err = sum(WEIGHTS[k] * attrs[k] for k in keys) - target
        if abs(err) < 0.5:
            break
        k = max(keys, key=lambda kk: (vals[kk] - attrs[kk]) * (1 if err < 0 else -1))
        attrs[k] += 1 if err < 0 else -1
    return attrs


d = json.loads(P.read_text(encoding="utf-8"))
for drv in d["drivers"]:
    birth, target, pot, profile = PROFILE[drv["id"]]
    attrs = distribute(target, profile)
    drv["birth"] = birth
    c = SNAP["career"][drv["id"]]
    drv["titles"] = c["titles"]
    drv["career"] = {"starts": c["starts"], "wins": c["wins"], "podiums": c["podiums"], "poles": c["poles"], "fastest_laps": c["fastest_laps"]}
    hw = SNAP["height_weight"][drv["id"]]
    drv["height_cm"] = hw["height_cm"]
    drv["weight_kg"] = hw["weight_kg"]
    drv["attrs"] = attrs
    drv["potential"] = pot
    drv["rating"] = round(sum(attrs[k] * w for k, w in WEIGHTS.items()))
    assert drv["rating"] == target, (drv["id"], drv["rating"], target)
d["_notas"] = ("Grid oficial de 2026. birth/height/weight/career/titles: pesquisa de 02/11/2026 (tools/research/snapshot_2026-11-02.json, "
               "fontes citadas lá). rating: notas definidas pelo usuário em 2026-11-03. attrs/potential: ESTIMATIVA do projeto (perfil por "
               "reputação e estatísticas de carreira, tools/enrich_drivers.py). rating = média ponderada dos atributos.")
P.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding="utf-8")
print("ok", [(x["id"], x["rating"]) for x in d["drivers"]][:6])
