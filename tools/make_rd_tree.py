"""Gera game/data/rd_tree.json: a árvore de P&D do carro (estilo F1 2017, aprovada no mockup v9).

4 departamentos × 4 braços (categorias). Em cada braço: nós menor (m), importante (i) e definitiva (d)
com a posição (distância ao centro `d` e deslocamento lateral `l`, em px do mockup) e o nó-pai.
Os valores de custo, prazo e efeito por tipo de nó ficam em "kinds" (PROVISÓRIOS, balancear depois).
Uso: python tools/make_rd_tree.py
"""
import json
import pathlib

OUT = pathlib.Path(__file__).resolve().parent.parent / "game" / "data" / "rd_tree.json"

# (distância, lateral, tipo, índice do pai); pai -1 = centro. Igual ao mockup v9.
SHAPES = [
    [(100, 0, "m", -1), (142, -46, "m", 0), (142, 46, "m", 0), (184, 0, "i", 0), (226, -46, "m", 3), (226, 46, "m", 3), (268, 0, "d", 3)],
    [(100, 0, "m", -1), (142, -46, "m", 0), (142, 46, "m", 0), (184, 0, "i", 0), (226, 0, "m", 3), (268, 0, "d", 4)],
    [(100, 0, "m", -1), (142, -40, "m", 0), (142, 40, "m", 0), (190, 0, "i", 0), (240, 0, "d", 3)],
    [(100, 0, "m", -1), (142, -40, "m", 0), (142, 40, "m", 0), (190, 0, "i", 0), (240, 0, "d", 3)],
]

EFF = ["Equipe dedicada", "Ferramentas de produção", "Gestão de projetos", "Banco de dados técnico", "Centro de simulação"]
QUAL = ["Inspeção de peças", "Controle de tolerâncias", "Testes de fadiga", "Auditoria de fornecedores", "Certificação total"]

DEPTS = [
    {"id": "engine", "name": "Motor", "color": "#ff6a5a", "needs_own_engine": True,
     "desc": "Potência e consumo da unidade de potência. Só quem fabrica o próprio motor desenvolve aqui.",
     "arms": [
         ("Potência do motor", "perf", ["Mapeamento de ignição", "Turbo de maior fluxo", "Pistões leves", "Câmara de combustão v2", "Sistema ERS-K", "Admissão otimizada", "Unidade de potência Mk2"]),
         ("Consumo de combustível", "perf", ["Injeção de precisão", "Mistura pobre", "Recuperação térmica", "Bomba de baixo atrito", "Combustível sustentável v2", "Ciclo de energia Mk2"]),
         ("Eficiência do departamento", "eff", EFF),
         ("Controle de qualidade", "qual", QUAL)]},
    {"id": "aero", "name": "Aerodinâmica", "color": "#ffd24a", "needs_own_engine": False,
     "desc": "Pressão = curvas mais rápidas · menos arrasto = retas mais rápidas.",
     "arms": [
         ("Pressão aerodinâmica", "perf", ["Aerofólio dianteiro v2", "Aleta do bico", "Assoalho com túneis", "Difusor v2", "Defletores laterais", "Asa traseira de alta carga", "Pacote aerodinâmico Mk2"]),
         ("Arrasto", "perf", ["Asa móvel eficiente", "Carenagem do cockpit", "Entradas de ar compactas", "Fendas de arrasto", "Perfil de baixo arrasto", "Pacote de retas Mk2"]),
         ("Eficiência do departamento", "eff", ["Túnel de vento ampliado", "Fluidodinâmica (CFD)", "Modelos em escala", "Equipe de aerodinâmicos", "Correlação pista-túnel"]),
         ("Controle de qualidade", "qual", ["Acabamento de superfície", "Moldes de carbono", "Medição a laser", "Testes de estrutura", "Certificação de peças"])]},
    {"id": "chassis", "name": "Chassi", "color": "#5c93ea", "needs_own_engine": False,
     "desc": "Aderência mecânica e peso do carro: suspensão, freios e estrutura.",
     "arms": [
         ("Aderência mecânica", "perf", ["Suspensão dianteira v2", "Barra estabilizadora", "Amortecedores de precisão", "Geometria traseira", "Freios de maior potência", "Diferencial ativo", "Pacote mecânico Mk2"]),
         ("Peso e estrutura", "perf", ["Fibra de carbono leve", "Parafusos de titânio", "Monobloco mais leve", "Painéis finos", "Lastro móvel", "Pacote de peso Mk2"]),
         ("Eficiência do departamento", "eff", EFF),
         ("Controle de qualidade", "qual", QUAL)]},
    {"id": "durability", "name": "Durabilidade", "color": "#3c9d5d", "needs_own_engine": False,
     "desc": "Confiabilidade: menos quebras no motor, no câmbio e na hidráulica durante a corrida.",
     "arms": [
         ("Confiabilidade do motor", "rel", ["Refrigeração reforçada", "Rolamentos reforçados", "Selos de longa vida", "Controle térmico", "Óleo de alta resistência", "Monitor de vibração", "Motor de longa duração"]),
         ("Confiabilidade do câmbio", "rel", ["Engrenagens reforçadas", "Embreagem durável", "Hidráulica robusta", "Eixos de transmissão", "Câmbio de cartucho", "Câmbio de longa vida"]),
         ("Eficiência do departamento", "eff", EFF),
         ("Controle de qualidade", "qual", QUAL)]},
]

# Efeito e custo por tipo de nó (PROVISÓRIO). perf = nota do carro; rel = redução de quebras;
# eff = redução dos dias dos projetos do departamento; qual = pontos de chance de acerto.
KINDS = {
    "m": {"name": "Menor", "cost_musd": 2.5, "days": 3, "perf": 0.12, "rel": 0.04, "eff": 0.03, "qual": 1.5},
    "i": {"name": "Importante", "cost_musd": 8.0, "days": 7, "perf": 0.35, "rel": 0.10, "eff": 0.06, "qual": 3.0},
    "d": {"name": "Definitiva", "cost_musd": 22.0, "days": 14, "perf": 0.90, "rel": 0.24, "eff": 0.12, "qual": 6.0},
}


def build() -> dict:
    depts = []
    for dep in DEPTS:
        arms = []
        for a, (name, effect, names) in enumerate(dep["arms"]):
            shape = SHAPES[a]
            assert len(names) == len(shape), (dep["id"], name, len(names), len(shape))
            nodes = [{"n": names[i], "k": k, "p": par, "d": d, "l": l} for i, (d, l, k, par) in enumerate(shape)]
            arms.append({"name": name, "effect": effect, "nodes": nodes})
        depts.append({"id": dep["id"], "name": dep["name"], "color": dep["color"], "desc": dep["desc"],
                      "needs_own_engine": dep["needs_own_engine"], "arms": arms})
    return {"_notas": "PROVISÓRIO. Gerado por tools/make_rd_tree.py. Custo do nó = cost_musd do tipo × (1 + 0,06 × posição no braço).",
            "kinds": KINDS, "cost_step": 0.06, "departments": depts}


if __name__ == "__main__":
    OUT.write_text(json.dumps(build(), ensure_ascii=False, indent=1), encoding="utf-8")
    print("ok", OUT)
