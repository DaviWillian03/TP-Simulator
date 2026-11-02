"""Gera game/data/staff_pool.json: diretores técnicos e engenheiros FICTÍCIOS para o mercado da campanha.
Combina nomes e sobrenomes de várias nacionalidades (nada de pessoas reais). Habilidade 45-92, semente fixa.
Uso: python tools/make_staff_pool.py
"""
import json
import pathlib
import random

OUT = pathlib.Path(__file__).resolve().parent.parent / "game" / "data" / "staff_pool.json"
rng = random.Random(2026)
NAMES = {
    "Brasil": (["Marcos", "Dario", "Camila", "Rui", "Bianca", "Tiago"], ["Veloso", "Quintal", "Arruda", "Lacerda", "Furtado", "Mendes"]),
    "Reino Unido": (["Oliver", "Harriet", "Callum", "Nigel", "Imogen", "Rhys"], ["Whitlock", "Pemberton", "Ashdown", "Thorne", "Calloway", "Hargreaves"]),
    "Alemanha": (["Lukas", "Helena", "Jonas", "Greta", "Matthias", "Katrin"], ["Voss", "Brandt", "Falk", "Neumann", "Lindner", "Roth"]),
    "Itália": (["Matteo", "Giulia", "Enzo", "Chiara", "Paolo", "Elisa"], ["Ferrante", "Colombo", "Rinaldi", "Bellini", "Moretti", "Serra"]),
    "França": (["Julien", "Camille", "Étienne", "Margaux", "Hugo", "Inès"], ["Delorme", "Vasseur", "Marchand", "Lefèvre", "Girard", "Roussel"]),
    "Noruega": (["Ingrid", "Henrik", "Sigrid", "Magnus", "Astrid", "Leif"], ["Solheim", "Berg", "Haugen", "Lund", "Strand", "Dahl"]),
    "Japão": (["Haruto", "Yuna", "Kenji", "Aiko", "Daichi", "Rina"], ["Takeda", "Morita", "Ishikawa", "Hayashi", "Nakano", "Ogawa"]),
    "Espanha": (["Javier", "Lucía", "Andrés", "Marta", "Álvaro", "Irene"], ["Calderón", "Montoya", "Salazar", "Ibarra", "Cortés", "Navarro"]),
}
ROLES = {"director": 8, "aero": 10, "chassis": 10, "durability": 10, "engine": 8}
used = set()
people = []
for role, count in ROLES.items():
    for _ in range(count):
        while True:
            nat = rng.choice(list(NAMES))
            first = rng.choice(NAMES[nat][0])
            last = rng.choice(NAMES[nat][1])
            name = f"{first} {last}"
            if name not in used:
                used.add(name)
                break
        skill = rng.randint(45, 92)
        pid = (first + "_" + last).lower().replace(" ", "_").replace("é", "e").replace("è", "e").replace("á", "a").replace("í", "i").replace("ó", "o").replace("ú", "u").replace("ã", "a").replace("ç", "c").replace("ñ", "n").replace("ï", "i")
        people.append({"id": "staff_" + pid, "name": name, "nationality": nat, "role": role, "skill": skill})
OUT.write_text(json.dumps({"_notas": "FICTÍCIO e PROVISÓRIO. Gerado por tools/make_staff_pool.py (semente fixa). Funções: director, aero, chassis, durability, engine.",
                           "people": people}, ensure_ascii=False, indent=1), encoding="utf-8")
print("ok", len(people))
