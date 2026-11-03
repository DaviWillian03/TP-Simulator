"""Reescala as notas das categorias de base e dos agentes livres (pedido do usuário, 2026-11-03).

- F2: de 64 a 78 (os melhores um pouco acima do pior da F1, Stroll/Colapinto = 74).
- F3: de 50 a 70.
- Outras categorias (IndyCar, WEC, Fórmula E): topo 84, mediana parecida com Albon/Ocon (78-79) e os piores abaixo do Stroll (74).
- Colton Herta saiu da lista da F2: ele corre de IndyCar e já está nos agentes livres.
A ordem dentro de cada categoria é a que o projeto já avaliava (campeonatos de base, regularidade e potencial); AJUSTES dá
retoques pontuais por currículo. Idempotente: grava _notas.rescalado e não reescala duas vezes.
Uso: python tools/rescale_feeder_ratings.py
"""
import json
import pathlib

DATA = pathlib.Path(__file__).resolve().parent.parent / "game" / "data"
F = DATA / "drivers_feeder_2026.json"
A = DATA / "free_agents.json"
F2_RANGE, F3_RANGE = (64, 78), (50, 70)
# retoques por currículo (nota final)
AJUSTES = {
    "rafael_camara": 78,  # campeão da F3 em 2025, favorito ao título da F2
    "gabriele_mini": 77,  # campeão da F3 em 2024, já faz pódios na F2
    "ugo_ugochukwu": 70,  # melhor da F3 pelo histórico
}
EXTRAS = {  # IndyCar/WEC/Fórmula E: notas finais
    "alex_palou": 84, "pato_oward": 82, "colton_herta": 79, "stoffel_vandoorne": 78, "felix_rosenqvist": 77,
    "mick_schumacher": 73, "nyck_de_vries": 72, "antonio_giovinazzi": 71,
}


def remap(values, lo, hi):
    a, b = min(values), max(values)
    return lambda v: round(lo + (v - a) * (hi - lo) / (b - a))


d = json.loads(F.read_text(encoding="utf-8"))
if not d["_notas"].get("rescalado"):
    d["drivers"] = [x for x in d["drivers"] if x["id"] != "colton_herta"]
    for cat, rng in (("F2", F2_RANGE), ("F3", F3_RANGE)):
        grp = [x for x in d["drivers"] if x["category"] == cat]
        f = remap([x["rating"] for x in grp], *rng)
        for x in grp:
            x["rating"] = AJUSTES.get(x["id"], f(x["rating"]))
    d["_notas"]["rescalado"] = "2026-11-03: F2 64-78, F3 50-70 (pedido do usuário); ordem por avaliação do projeto."
    d["_notas"]["provisorio"] = "nacionalidades e equipes são PROVISÓRIOS (conferir na pesquisa de atributos); notas reescaladas em 2026-11-03."
    F.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding="utf-8")
a = json.loads(A.read_text(encoding="utf-8"))
for x in a["drivers"]:
    x["rating"] = EXTRAS[x["id"]]
a["_notas"] = "Pilotos de outras categorias no radar da F1 como agentes livres (nomes reais). Notas definidas em 2026-11-03: topo 84, mediana ~78, piores abaixo de 74."
A.write_text(json.dumps(a, ensure_ascii=False, indent=1), encoding="utf-8")
for cat in ("F2", "F3"):
    r = sorted((x["rating"] for x in d["drivers"] if x["category"] == cat), reverse=True)
    print(cat, len(r), r)
print("extras", sorted(EXTRAS.values(), reverse=True))
