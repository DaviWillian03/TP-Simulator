#!/usr/bin/env python3
"""Gera o pacote de equipes, pilotos e forma real da temporada 2012 (game/data/seasons/2012/).

Fontes e status (2026-11-12):
- Grid, números, motores, chefes de equipe, pontos finais de construtores e pódios das 20 corridas: fatos da
  temporada 2012 (conhecimento do projeto, conferido por busca: vencedores de cada GP batem com
  simple.wikipedia.org/wiki/2012_Formula_One_World_Championship e formulaonehistory.com).
- Carreira até o fim de 2011 (career), atributos (attrs), potencial e habilidade de largada: ESTIMATIVA do projeto.
- Sem pilotos substitutos (d'Ambrosio correu Monza no lugar do Grosjean): o jogo usa o grid titular.
- Cores e emblemas: ORIGINAIS (sem logos oficiais).

Força dos carros (mesma ideia de tools/make_real_form.py, um pouco mais equilibrada):
1. nota base pelos pontos finais de construtores: 79 + 11 * (pontos / maior) ** 0.5;
2. BALANCE = 0.48 (2026 usa 0.40): a distância ao centro do grid cai 48%;
3. desvio por pista pelos pontos de pódio de cada equipe na corrida (25/18/15) em relação à média da equipe,
   limitado a +-MAX_OFFSET e pesado por TRACK_WEIGHT (pódio é só parte do ritmo).

Uso: python3 tools/make_season_2012.py
"""
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "game/data/seasons/2012"
WEIGHTS = {"pace": 0.30, "quali": 0.15, "consistency": 0.15, "racecraft": 0.20, "wet": 0.10, "tyres": 0.10}
BALANCE = 0.48
PTS_PER_RATING = 9.0
TRACK_WEIGHT = 0.5
MAX_OFFSET = 4.0
# As três novatas de 2010 marcaram zero; na pista a Caterham vinha à frente da Marussia, e a HRT atrás de todas.
CALIBRATION = {"caterham": 0.0, "marussia": -0.6, "hrt": -1.3}

# id, nome, motor, cor, cor2, chefe, diretor técnico, estreia, títulos até 2011, pontos 2012, sede, fundação,
# características (reta, lenta, rápida, confiabilidade), emblema (forma, texto), história
TEAMS = [
    ("redbull", "Red Bull Racing", "Renault", "#1E2A5A", "#E8C21A", "Christian Horner", "Adrian Newey", 2005, 2, 460,
     "Milton Keynes, Reino Unido", 2005, (-1.5, 1.5, 2.0, 80), ("peak", "RB"),
     "Bicampeã em 2010 e 2011; carro de Adrian Newey com escapamento soprando o difusor."),
    ("ferrari", "Ferrari", "Ferrari", "#D40000", "#F5D000", "Stefano Domenicali", "Pat Fry", 1950, 16, 400,
     "Maranello, Itália", 1929, (0.5, 0.5, 0.0, 88), ("shield", "F"),
     "A equipe mais antiga do grid; o F2012 começou lento e virou carro de pódio nas mãos do Alonso."),
    ("mclaren", "McLaren", "Mercedes", "#A8AFB8", "#D11A1A", "Martin Whitmarsh", "Paddy Lowe", 1966, 8, 378,
     "Woking, Reino Unido", 1963, (1.0, 0.5, 1.0, 78), ("chevron", "Mc"),
     "Carro mais rápido em várias etapas de 2012, mas com quebras e paradas lentas no box."),
    ("lotus", "Lotus", "Renault", "#151515", "#C9A646", "Éric Boullier", "James Allison", 2012, 0, 303,
     "Enstone, Reino Unido", 1981, (-0.5, 0.5, 1.0, 86), ("diamond", "LT"),
     "A antiga Renault de Enstone com o nome Lotus; volta de Kimi Räikkönen e muitos pódios."),
    ("mercedes", "Mercedes", "Mercedes", "#BFC5CC", "#00B5A5", "Ross Brawn", "Bob Bell", 2010, 0, 142,
     "Brackley, Reino Unido", 2010, (1.5, -0.5, -0.5, 82), ("ring", "M"),
     "Primeira vitória da fase moderna (Rosberg, China); última temporada de Michael Schumacher."),
    ("sauber", "Sauber", "Ferrari", "#EDEFF2", "#2A3550", "Peter Sauber", "James Key", 1993, 0, 126,
     "Hinwil, Suíça", 1970, (0.0, 0.5, 0.0, 86), ("octagon", "S"),
     "Carro gentil com os pneus: quatro pódios entre Pérez e Kobayashi."),
    ("forceindia", "Force India", "Mercedes", "#F28C28", "#1B8A3A", "Vijay Mallya", "Andrew Green", 2008, 0, 109,
     "Silverstone, Reino Unido", 1991, (1.0, -0.5, 0.0, 86), ("hex", "FI"),
     "Herdeira da Jordan; Hülkenberg chegou a liderar o GP do Brasil."),
    ("williams", "Williams", "Renault", "#F2F4F7", "#123C7A", "Frank Williams", "Mike Coughlan", 1977, 9, 76,
     "Grove, Reino Unido", 1977, (0.0, 0.5, 0.5, 80), ("chevron", "W"),
     "Vitória do Maldonado em Barcelona, a primeira da equipe desde 2004."),
    ("tororosso", "Toro Rosso", "Ferrari", "#1B3A8C", "#D0102E", "Franz Tost", "Giorgio Ascanelli", 2006, 0, 26,
     "Faenza, Itália", 1985, (0.5, 0.0, -0.5, 84), ("peak", "TR"),
     "A antiga Minardi; equipe-escola da Red Bull com dois estreantes de 2012 (Ricciardo e Vergne)."),
    ("caterham", "Caterham", "Renault", "#0B5D3A", "#F0C200", "Tony Fernandes", "Mike Gascoyne", 2010, 0, 0,
     "Leafield, Reino Unido", 2010, (0.0, 0.0, 0.0, 82), ("pill", "CT"),
     "Ex-Lotus Racing; a melhor das novatas de 2010, mas ainda sem pontos."),
    ("marussia", "Marussia", "Cosworth", "#202020", "#C8102E", "John Booth", None, 2010, 0, 0,
     "Banbury, Reino Unido", 2010, (0.0, -0.5, -0.5, 80), ("square", "MR"),
     "Ex-Virgin; primeiro carro desenhado com túnel de vento, ainda no fim do grid."),
    ("hrt", "HRT", "Cosworth", "#E4E2DC", "#B3122E", "Luis Pérez-Sala", "Toni Cuquerella", 2010, 0, 0,
     "Madri, Espanha", 2010, (0.0, -1.0, -1.0, 76), ("hex", "H"),
     "Equipe espanhola de orçamento curto; 2012 foi sua última temporada."),
]

# id, nome, sigla, nº, nacionalidade, equipe, nascimento, títulos até 2011,
# carreira até 2011 (largadas, vitórias, pódios, poles, voltas mais rápidas),
# atributos (ritmo, quali, constância, disputa, chuva, pneus), potencial, altura, peso, largada (0-100)
DRIVERS = [
    ("vettel", "Sebastian Vettel", "VET", 1, "Alemanha", "redbull", "1987-07-03", 2, (81, 21, 36, 30, 9), (93, 96, 88, 85, 88, 87), 95, 175, 62, 52),
    ("webber", "Mark Webber", "WEB", 2, "Austrália", "redbull", "1976-08-27", 0, (176, 7, 27, 9, 12), (87, 89, 84, 82, 82, 83), 87, 184, 75, 28),
    ("button", "Jenson Button", "BUT", 3, "Reino Unido", "mclaren", "1980-01-19", 1, (208, 12, 43, 7, 6), (88, 86, 90, 86, 92, 93), 88, 182, 72, 60),
    ("hamilton", "Lewis Hamilton", "HAM", 4, "Reino Unido", "mclaren", "1985-01-07", 1, (90, 17, 43, 19, 11), (95, 96, 85, 93, 92, 84), 96, 174, 66, 62),
    ("alonso", "Fernando Alonso", "ALO", 5, "Espanha", "ferrari", "1981-07-29", 2, (177, 27, 72, 20, 19), (95, 91, 94, 95, 91, 90), 95, 171, 68, 74),
    ("massa", "Felipe Massa", "MAS", 6, "Brasil", "ferrari", "1981-04-25", 0, (152, 11, 33, 15, 14), (84, 84, 81, 80, 77, 80), 84, 166, 59, 66),
    ("schumacher", "Michael Schumacher", "MSC", 7, "Alemanha", "mercedes", "1969-01-03", 7, (287, 91, 154, 68, 76), (86, 86, 82, 85, 90, 84), 86, 174, 74, 70),
    ("rosberg", "Nico Rosberg", "ROS", 8, "Alemanha", "mercedes", "1985-06-27", 0, (108, 0, 5, 0, 2), (88, 90, 85, 83, 84, 82), 91, 178, 71, 56),
    ("raikkonen", "Kimi Räikkönen", "RAI", 9, "Finlândia", "lotus", "1979-10-17", 1, (156, 18, 62, 16, 35), (91, 85, 92, 88, 86, 91), 91, 175, 70, 60),
    ("grosjean", "Romain Grosjean", "GRO", 10, "França", "lotus", "1986-04-17", 0, (7, 0, 0, 0, 0), (88, 89, 74, 76, 78, 82), 89, 180, 71, 44),
    ("diresta", "Paul di Resta", "DIR", 11, "Reino Unido", "forceindia", "1986-04-16", 0, (19, 0, 0, 0, 0), (83, 82, 85, 79, 80, 84), 85, 178, 70, 50),
    ("hulkenberg", "Nico Hülkenberg", "HUL", 12, "Alemanha", "forceindia", "1987-08-19", 0, (19, 0, 0, 1, 0), (86, 87, 84, 82, 86, 83), 89, 184, 74, 40),
    ("kobayashi", "Kamui Kobayashi", "KOB", 14, "Japão", "sauber", "1986-09-13", 0, (49, 0, 0, 0, 0), (82, 81, 78, 88, 78, 85), 84, 170, 64, 62),
    ("perez", "Sergio Pérez", "PER", 15, "México", "sauber", "1990-01-26", 0, (17, 0, 0, 0, 0), (84, 79, 80, 83, 78, 90), 88, 173, 63, 50),
    ("ricciardo", "Daniel Ricciardo", "RIC", 16, "Austrália", "tororosso", "1989-07-01", 0, (11, 0, 0, 0, 0), (82, 85, 79, 82, 78, 79), 91, 180, 71, 54),
    ("vergne", "Jean-Éric Vergne", "VER", 17, "França", "tororosso", "1990-04-25", 0, (0, 0, 0, 0, 0), (80, 77, 80, 80, 80, 81), 85, 175, 63, 48),
    ("maldonado", "Pastor Maldonado", "MAL", 18, "Venezuela", "williams", "1985-03-09", 0, (19, 0, 0, 0, 0), (85, 87, 70, 74, 74, 79), 85, 173, 68, 46),
    ("senna", "Bruno Senna", "SEN", 19, "Brasil", "williams", "1983-10-15", 0, (26, 0, 0, 0, 0), (80, 77, 80, 79, 80, 81), 81, 182, 72, 52),
    ("kovalainen", "Heikki Kovalainen", "KOV", 20, "Finlândia", "caterham", "1981-10-19", 0, (89, 1, 4, 1, 2), (83, 84, 83, 80, 81, 80), 83, 172, 63, 52),
    ("petrov", "Vitaly Petrov", "PET", 21, "Rússia", "caterham", "1984-09-08", 0, (38, 0, 1, 0, 0), (80, 78, 79, 81, 77, 79), 81, 185, 75, 56),
    ("delarosa", "Pedro de la Rosa", "DLR", 22, "Espanha", "hrt", "1971-02-24", 0, (86, 0, 1, 0, 1), (77, 76, 84, 76, 78, 80), 77, 177, 70, 50),
    ("karthikeyan", "Narain Karthikeyan", "KAR", 23, "Índia", "hrt", "1977-01-14", 0, (27, 0, 0, 0, 0), (73, 72, 74, 72, 74, 74), 73, 176, 73, 46),
    ("glock", "Timo Glock", "GLO", 24, "Alemanha", "marussia", "1982-03-18", 0, (72, 0, 3, 0, 1), (81, 80, 84, 79, 80, 80), 81, 168, 66, 54),
    ("pic", "Charles Pic", "PIC", 25, "França", "marussia", "1990-02-15", 0, (0, 0, 0, 0, 0), (76, 76, 78, 75, 75, 77), 80, 180, 68, 48),
]

# Pódio real de cada GP de 2012 (1º, 2º, 3º).
PODIUMS = {
    "albertpark": ("button", "vettel", "hamilton"),
    "sepang": ("alonso", "perez", "hamilton"),
    "shanghai": ("rosberg", "button", "hamilton"),
    "bahrain": ("vettel", "raikkonen", "grosjean"),
    "barcelona": ("maldonado", "alonso", "raikkonen"),
    "monaco": ("webber", "rosberg", "alonso"),
    "montreal": ("hamilton", "grosjean", "perez"),
    "valencia": ("alonso", "raikkonen", "schumacher"),
    "silverstone": ("webber", "alonso", "vettel"),
    "hockenheim": ("alonso", "raikkonen", "kobayashi"),
    "hungaroring": ("hamilton", "raikkonen", "grosjean"),
    "spa": ("button", "vettel", "raikkonen"),
    "monza": ("hamilton", "perez", "alonso"),
    "singapore": ("vettel", "button", "alonso"),
    "suzuka": ("vettel", "massa", "kobayashi"),
    "yeongam": ("vettel", "webber", "alonso"),
    "buddh": ("vettel", "alonso", "webber"),
    "yasmarina": ("raikkonen", "alonso", "vettel"),
    "austin": ("hamilton", "vettel", "alonso"),
    "interlagos": ("button", "alonso", "massa"),
}
POD_PTS = (25, 18, 15)


# Nota geral de 2012 definida pelo usuário (2026-11-12). Os atributos saem do PERFIL abaixo (desvios em relação à nota,
# na ordem ritmo, quali, constância, disputa, chuva, pneus) e são acertados para a média ponderada bater exatamente.
TARGET = {"alonso": 96, "hamilton": 95, "vettel": 93, "raikkonen": 89, "rosberg": 89, "button": 88, "schumacher": 86,
          "perez": 84, "hulkenberg": 83, "massa": 83, "webber": 82, "kovalainen": 81, "ricciardo": 81, "kobayashi": 80,
          "glock": 79, "grosjean": 78, "maldonado": 76, "vergne": 76, "petrov": 75, "diresta": 73, "senna": 71,
          "delarosa": 71, "pic": 70, "karthikeyan": 70}
# Perfil pela temporada real (ESTIMATIVA do projeto):
PROFILE = {
    "alonso": (0, -3, 2, 2, 0, 1),        # o mais completo; poucas poles com a Ferrari, mas máximo em corrida
    "hamilton": (1, 3, -3, 0, 1, -2),     # mais poles do ano (7); erros e um carro que quebrava; gasta mais pneu
    "vettel": (0, 3, 0, -2, -1, 0),       # sábado forte, domínio na reta final; menos à vontade no meio do pelotão
    "raikkonen": (0, -4, 5, 0, -1, 3),    # completou todas as corridas, pontuou em quase todas; quali era o ponto fraco
    "rosberg": (0, 3, 0, -2, 0, -2),      # pole e vitória na China; batia o Schumacher no sábado; pneus traseiros
    "button": (-1, -2, -2, 1, 4, 4),      # mestre da chuva e do pneu; oscilou no meio do ano por acerto
    "schumacher": (0, 0, -2, 1, 3, -1),   # mais rápido no sábado em Mônaco; batidas (Barcelona); excelente na chuva
    "perez": (0, -4, -1, 1, -1, 6),       # pódios com uma parada só e pneu poupado; classificação fraca
    "hulkenberg": (0, 1, 1, 1, 2, -1),    # liderou no molhado em Interlagos; regular
    "massa": (-1, 0, -2, 0, -1, 1),       # primeira metade ruim, reta final forte
    "webber": (0, 2, 0, 1, -1, -1),       # venceu Mônaco e Silverstone; bom no sábado (largada ruim está na habilidade de largada)
    "kovalainen": (0, 1, 2, 0, 0, -1),    # tirava o máximo da Caterham
    "ricciardo": (0, 4, 0, -1, -2, -1),   # batia o Vergne na classificação com folga
    "kobayashi": (0, 1, -2, 4, -1, 1),    # o grande ultrapassador; pódio em Suzuka; alguns toques
    "glock": (0, 0, 3, 0, 1, 0),          # regular, líder da Marussia
    "grosjean": (3, 4, -8, -3, -1, 1),    # muito rápido, mas acidentes de 1ª volta (suspenso após Spa)
    "maldonado": (3, 5, -8, -3, -2, 0),   # pole e vitória em Barcelona; muitas batidas e punições
    "vergne": (0, -2, 1, 1, 1, 2),        # melhor no domingo que no sábado
    "petrov": (0, -1, 1, 1, 0, 0),        # cresceu no fim do ano
    "diresta": (0, 0, 2, -1, -1, 1),      # constante, sem brilho no ataque
    "senna": (0, -3, 1, 1, 0, 2),         # perdia muito na classificação para o Maldonado; corrida razoável
    "delarosa": (-1, -1, 3, 0, 0, 2),     # experiente e limpo
    "pic": (0, 0, 1, 0, 0, 1),            # estreante regular
    "karthikeyan": (0, 0, -1, 1, 0, 0),
}


def attrs_of(did):
    """Atributos que somam (média ponderada) exatamente a nota escolhida pelo usuário."""
    target = TARGET[did]
    prof = dict(zip(WEIGHTS, PROFILE[did]))
    bias = sum(WEIGHTS[k] * v for k, v in prof.items())
    a = {k: min(99, round(target + v - bias)) for k, v in prof.items()}
    for _ in range(20):  # acerta o arredondamento no ritmo (peso maior)
        err = sum(WEIGHTS[k] * a[k] for k in WEIGHTS) - target
        if abs(err) < 0.5:
            break
        a["pace"] -= round(err / WEIGHTS["pace"]) or (1 if err > 0 else -1)
    return a


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    top = max(t[9] for t in TEAMS)
    raw = {t[0]: 79.0 + 11.0 * (t[9] / top) ** 0.5 for t in TEAMS}
    centre = sum(raw.values()) / len(raw)
    base = {k: round(centre + (v - centre) * (1.0 - BALANCE) + CALIBRATION.get(k, 0.0), 2) for k, v in raw.items()}

    team_of = {d[0]: d[5] for d in DRIVERS}
    ids = [t[0] for t in TEAMS]
    per = {cid: {t: 0.0 for t in ids} for cid in PODIUMS}
    for cid, pod in PODIUMS.items():
        for i, d in enumerate(pod):
            per[cid][team_of[d]] += POD_PTS[i]
    mean = {t: sum(per[c][t] for c in PODIUMS) / len(PODIUMS) for t in ids}
    rounds = {cid: {t: round(max(-MAX_OFFSET, min(MAX_OFFSET, (per[cid][t] - mean[t]) / PTS_PER_RATING)) * TRACK_WEIGHT, 2)
                    for t in ids} for cid in PODIUMS}

    teams = []
    for (tid, name, pu, c1, c2, boss, td, debut, titles, pts, hq, founded, tr, emb, story) in TEAMS:
        teams.append({"id": tid, "name": name, "power_unit": pu, "color": c1, "color2": c2, "emblem_bg": c1,
                      "car_rating": base[tid], "emblem": {"shape": emb[0], "text": emb[1]}, "principal": boss,
                      "technical_director": td, "debut": debut, "constructors_titles": titles, "points_2012": pts,
                      "car_traits": {"straight": tr[0], "slow": tr[1], "fast": tr[2], "rel": tr[3]},
                      "hq": hq, "founded": founded, "heritage": story, "era": "2012"})
    drivers = []
    for (did, name, code, num, nat, team, birth, titles, car, _at, _pot, h, w, _start) in DRIVERS:
        a = attrs_of(did)
        rating = round(sum(a[k] * wt for k, wt in WEIGHTS.items()))
        assert rating == TARGET[did], (did, rating)
        age = 2012 - int(birth[:4])
        pot = min(97, rating + max(0, 27 - age))  # jovens ainda crescem (Ricciardo, Pérez, Vergne, Pic…)
        drivers.append({"id": did, "name": name, "code": code, "number": num, "nationality": nat, "team": team,
                        "rating": rating, "birth": birth, "titles": titles,
                        "attrs": a, "potential": pot,
                        "career": dict(zip(("starts", "wins", "podiums", "poles", "fastest_laps"), car)),
                        "height_cm": h, "weight_kg": w})

    note_t = ("Grid de 2012 (tools/make_season_2012.py). Nomes reais; cores e emblemas ORIGINAIS (sem logos oficiais). "
              "car_rating = forma real (pontos de construtores de 2012, equilíbrio 0.48). car_traits: ESTIMATIVA.")
    note_d = ("Grid titular de 2012, sem substitutos. career = carreira até o FIM DE 2011 (aproximada). rating: definido pelo "
              "usuário em 2026-11-12; attrs: perfil da temporada real (ESTIMATIVA) acertado para a média ponderada = rating.")
    (OUT / "teams.json").write_text(json.dumps({"season": 2012, "_notas": note_t, "teams": teams}, ensure_ascii=False, indent=1), encoding="utf-8")
    (OUT / "drivers.json").write_text(json.dumps({"season": 2012, "_notas": note_d, "drivers": drivers}, ensure_ascii=False, indent=1), encoding="utf-8")
    (OUT / "real_form.json").write_text(json.dumps({
        "_notas": "Gerado por tools/make_season_2012.py: 'base' pelos pontos finais de construtores de 2012 (equilíbrio 0.48); "
                  "'rounds' pelo pódio real de cada GP.",
        "balance": BALANCE, "base": base, "rounds": rounds}, ensure_ascii=False, indent=1), encoding="utf-8")

    skill_path = ROOT / "game/data/start_skill.json"
    sk = json.loads(skill_path.read_text(encoding="utf-8"))
    for d in DRIVERS:
        sk["skill"].setdefault(d[0], d[13])  # quem já está na lista (2026) mantém a nota atual
    skill_path.write_text(json.dumps(sk, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print("nota base:", dict(sorted(base.items(), key=lambda x: -x[1])))
    print("pilotos:", {d["id"]: d["rating"] for d in drivers})


if __name__ == "__main__":
    main()
