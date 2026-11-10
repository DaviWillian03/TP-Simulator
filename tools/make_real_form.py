#!/usr/bin/env python3
"""Converte tools/real_results_2026.json (top 10 reais por corrida) em game/data/real_form_2026.json:
a força de cada carro por pista para o modo Campeonato Mundial F1 (decisão de 2026-11-10).

Método (simples e explicável):
1. pontos de cada equipe na corrida = soma dos pontos dos seus carros no top 10 (25,18,15,12,10,8,6,4,2,1);
   carro que abandonou não entra na conta (quebra não é falta de ritmo: o jogo sorteia as quebras à parte);
   equipe com os dois carros fora fica sem dado nessa pista (offset 0).
2. média da temporada por equipe -> nota base: 79 + 11 * (média / maior média) ** 0.5 (o melhor chega a 90).
3. EQUILÍBRIO: a nota base é puxada para a média do grid (BALANCE = 0.40 -> distância ao centro cai 40%).
4. desvio da pista = (pontos da corrida - média da equipe) / PTS_PER_RATING, limitado a +-MAX_OFFSET e
   multiplicado por TRACK_WEIGHT (0.6: a corrida real mistura ritmo, estratégia e sorte).
"""
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
PTS = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]
BALANCE = 0.40
PTS_PER_RATING = 7.0
TRACK_WEIGHT = 0.6
MAX_OFFSET = 5.0


def main() -> None:
    raw = json.loads((ROOT / "tools/real_results_2026.json").read_text(encoding="utf-8"))["rounds"]
    drivers = json.loads((ROOT / "game/data/drivers_2026.json").read_text(encoding="utf-8"))
    drivers = drivers if isinstance(drivers, list) else drivers.get("drivers", drivers)
    team_of = {d["id"]: d["team"] for d in drivers}
    teams = sorted(set(team_of.values()))
    score = {}  # circuito -> equipe -> pontos por carro que correu (None = sem dado)
    for cid, r in raw.items():
        dnf = set(r.get("dnf", [])) | set(r.get("slow", []))
        per = {t: 0.0 for t in teams}
        ran = {t: 0 for t in teams}
        for t in teams:
            ran[t] = sum(1 for d, tt in team_of.items() if tt == t and d not in r.get("dnf", []))
        for i, d in enumerate(r["top10"]):
            if d:
                per[team_of[d]] += PTS[i]
        score[cid] = {t: (per[t] / ran[t] if ran[t] else None) for t in teams}  # pontos por carro que correu
    mean = {}
    for t in teams:
        vals = [s[t] for s in score.values() if s[t] is not None]
        mean[t] = sum(vals) / len(vals) if vals else 0.0
    top = max(mean.values())
    base = {t: 79.0 + 11.0 * (mean[t] / top) ** 0.5 for t in teams}
    centre = sum(base.values()) / len(base)
    base = {t: round(centre + (v - centre) * (1.0 - BALANCE), 2) for t, v in base.items()}
    rounds = {}
    for cid, s in score.items():
        rounds[cid] = {}
        for t in teams:
            if s[t] is None:
                off = 0.0
            else:
                off = max(-MAX_OFFSET, min(MAX_OFFSET, (s[t] - mean[t]) / PTS_PER_RATING)) * TRACK_WEIGHT
            rounds[cid][t] = round(off, 2)
    out = {"_notas": "Gerado por tools/make_real_form.py a partir de tools/real_results_2026.json. 'base' = nota do carro (já equilibrada); "
                     "'rounds' = desvio de cada equipe em cada pista; pista sem dado (rodadas ainda não disputadas) = só a base.",
           "balance": BALANCE, "base": base, "rounds": rounds}
    (ROOT / "game/data/real_form_2026.json").write_text(json.dumps(out, ensure_ascii=False, indent=1), encoding="utf-8")
    print("média de pontos por carro/corrida:", {t: round(v, 1) for t, v in sorted(mean.items(), key=lambda x: -x[1])})
    print("nota base:", dict(sorted(base.items(), key=lambda x: -x[1])))


if __name__ == "__main__":
    main()
