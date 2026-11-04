"""Gera game/data/staff_2026.json: os 4 cargos técnicos de cada equipe do grid de 2026 (decisão do usuário, 2026-11-04).

Cargos (escolha do Claude: os que mais pesam num time real e que o jogo usa):
  director  = Diretor técnico (comanda todo o desenvolvimento)
  aero      = Chefe de aerodinâmica (atualizações aerodinâmicas)
  designer  = Projetista-chefe (chassi, peças, confiabilidade e integração do motor)
  trackside = Diretor de engenharia de pista (treinos livres e acerto do carro)

Nomes REAIS quando encontrados em fonte (pesquisa de 2026-11-04, lista em SOURCES); "real_title" guarda o cargo como a
equipe chama. Sem fonte: nome GENÉRICO fictício ("real": false). skill (nota 0-100) é ESTIMATIVA do projeto pela
reputação e resultados. Uso: python tools/make_staff_2026.py
"""
import json
import pathlib

OUT = pathlib.Path(__file__).resolve().parent.parent / "game" / "data" / "staff_2026.json"
SOURCES = [
    "https://en.wikipedia.org/wiki/Mercedes_W17", "https://www.mercedesamgf1.com/team/person/james-allison",
    "https://www.planetf1.com/news/ferrari-announce-new-technical-director-seven-person-structure-revealed",
    "https://en.wikipedia.org/wiki/Ferrari_SF-26", "https://en.wikipedia.org/wiki/Red_Bull_Racing_RB22",
    "https://www.gpfans.com/en/f1-news/1076325/red-bull-f1-craig-skinner-chief-designer-exit/",
    "https://en.wikipedia.org/wiki/McLaren", "https://racingnews365.com/meet-the-2026-f1-race-engineers",
    "https://www.espn.com/f1/story/_/id/45899353/enrico-cardile-starts-aston-martin-ferrari-dispute",
    "https://en.wikipedia.org/wiki/Williams_FW48", "https://en.wikipedia.org/wiki/Matt_Harman",
    "https://www.formula1.com/en/latest/article/alpine-announce-mike-elliott-as-chief-technical-officer.1ZFQGVhmwtjyec9icP1YHr",
    "https://en.wikipedia.org/wiki/Alpine_A526", "https://en.wikipedia.org/wiki/Haas_VF-26",
    "https://www.haasf1team.com/news/vf-26-launch-andrea-de-zordo-qa", "https://en.wikipedia.org/wiki/Audi_R26",
    "https://racingnews365.com/breaking-racing-bulls-appoint-new-technical-director", "https://en.wikipedia.org/wiki/Racing_Bulls_VCARB_03",
    "https://en.wikipedia.org/wiki/Cadillac_MAC-26", "https://en.wikipedia.org/wiki/Andrew_Shovlin",
]
# equipe: {cargo: (nome, nacionalidade, cargo real, nota) ou (nome genérico, nacionalidade, None, nota)}
T = {
    "mercedes": {"director": ("James Allison", "Reino Unido", "Technical Director", 93),
                 "aero": ("Jarrod Murphy", "Reino Unido", "Aerodynamics Director", 87),
                 "designer": ("John Owen", "Reino Unido", "Car Design Director", 85),
                 "trackside": ("Andrew Shovlin", "Reino Unido", "Trackside Engineering Director", 90)},
    "ferrari": {"director": ("Loïc Serra", "França", "Technical Director, Chassis", 86),
                "aero": ("Diego Tondi", "Itália", "Head of Aerodynamics", 83),
                "designer": ("Fabio Montecchi", "Itália", "Head of Chassis Project Engineering", 82),
                "trackside": ("Matteo Togninalli", "Itália", "Head of Track Engineering", 82)},
    "redbull": {"director": ("Pierre Waché", "França", "Technical Director", 91),
                "aero": ("Enrico Balbo", "Itália", "Head of Aerodynamics", 86),
                "designer": ("Edward Pickering", "Reino Unido", None, 78),  # Craig Skinner saiu em fev/2026; substituto não encontrado
                "trackside": ("Gianpiero Lambiase", "Reino Unido", "Head of Racing / Race Engineering", 90)},
    "mclaren": {"director": ("Rob Marshall", "Reino Unido", "Chief Technical Officer & Chief Designer", 91),
                "aero": ("Peter Prodromou", "Reino Unido", "Chief Technical Officer, Aerodynamics", 91),
                "designer": ("Mark Ingham", "Reino Unido", "Technical Director, Engineering Delivery", 82),
                "trackside": ("Will Joseph", "Reino Unido", "Head of Race Engineering", 84)},
    "astonmartin": {"director": ("Enrico Cardile", "Itália", "Chief Technical Officer", 86),
                    "aero": ("Oliver Whitcombe", "Reino Unido", None, 81),
                    "designer": ("Harriet Ashdown", "Reino Unido", None, 80),
                    "trackside": ("Lukas Brandt", "Alemanha", None, 78)},
    "williams": {"director": ("Pat Fry", "Reino Unido", "Chief Technical Officer", 85),
                 "aero": ("Adam Kenyon", "Reino Unido", "Head of Aerodynamics", 80),
                 "designer": ("Matt Harman", "Reino Unido", "Technical Director, Engineering", 82),
                 "trackside": ("Rhys Calloway", "Reino Unido", None, 77)},
    "alpine": {"director": ("Mike Elliott", "Reino Unido", "Chief Technical Officer (desde set/2026)", 86),
               "aero": ("Kristopher Midgley", "Reino Unido", "Head of Aerodynamics", 78),
               "designer": ("David Sanchez", "França", "Executive Technical Director", 83),
               "trackside": ("Julien Marchand", "França", None, 76)},
    "haas": {"director": ("Andrea De Zordo", "Itália", "Technical Director", 79),
             "aero": ("Davide Paganelli", "Itália", "Head of Aerodynamics", 76),
             "designer": ("Tom Coupland", "Reino Unido", "Chief Designer", 75),
             "trackside": ("Kenji Takeda", "Japão", None, 75)},
    "audi": {"director": ("James Key", "Reino Unido", "Technical Director", 85),
             "aero": ("Alessandro Cinelli", "Itália", "Head of Aerodynamics", 79),
             "designer": ("Eric Gandelin", "França", "Chief Designer, Chassis", 77),
             "trackside": ("Matthias Falk", "Alemanha", None, 76)},
    "racingbulls": {"director": ("Dan Fallows", "Reino Unido", "Technical Director", 84),
                    "aero": ("Guru Johl", "Reino Unido", "Head of Aerodynamics", 80),
                    "designer": ("Paolo Marabini", "Itália", "Chief Designer", 78),
                    "trackside": ("Giulia Bellini", "Itália", None, 77)},
    "cadillac": {"director": ("Nick Chester", "Reino Unido", "Chief Technical Officer", 80),
                 "aero": ("Jon Tomlinson", "Reino Unido", "Head of Aerodynamics", 76),
                 "designer": ("John McQuilliam", "Reino Unido", "Chief Designer", 79),
                 "trackside": ("Nigel Pemberton", "Reino Unido", None, 74)},
}


def slug(name):
    rep = {"é": "e", "è": "e", "ï": "i", "ç": "c", "á": "a", "ó": "o", "í": "i"}
    s = name.lower()
    for a, b in rep.items():
        s = s.replace(a, b)
    return "staff_" + "".join(ch if ch.isalnum() else "_" for ch in s)


people = []
for team, roles in T.items():
    for role, (name, nat, title, skill) in roles.items():
        p = {"id": slug(name), "name": name, "nationality": nat, "role": role, "skill": skill, "team": team, "real": title is not None}
        if title:
            p["real_title"] = title
        people.append(p)
assert len({p["id"] for p in people}) == len(people)
OUT.write_text(json.dumps({"_notas": "4 cargos por equipe (2026). Nomes reais com fonte quando 'real' = true (cargo da equipe em real_title); "
                                     "demais FICTÍCIOS. skill = ESTIMATIVA do projeto. tools/make_staff_2026.py",
                           "sources": SOURCES, "people": people}, ensure_ascii=False, indent=1), encoding="utf-8")
print("ok", len(people), "reais:", sum(p["real"] for p in people))
