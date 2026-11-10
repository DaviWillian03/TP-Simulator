#!/usr/bin/env python3
"""Atualização a cada GP (item 11): acrescenta o resultado real de uma corrida de 2026 e regenera a força dos carros por pista.

Uso:
  python tools/add_real_round.py <circuito> <p1,p2,...,p10> [--dnf=id,id] [--slow=id]
Exemplo (ids de game/data/drivers_2026.json; use "-" para posição não confirmada):
  python tools/add_real_round.py lasvegas verstappen,norris,leclerc,russell,antonelli,hamilton,piastri,-,hadjar,gasly --dnf=bortoleto
Se o circuito já existe, o resultado é substituído. Depois roda tools/make_real_form.py (grava game/data/real_form_2026.json).
Os resultados vêm de fontes públicas (busca na web); confira a classificação oficial antes de acrescentar."""
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
RES = ROOT / "tools/real_results_2026.json"


def main(argv: list[str]) -> int:
    pos = [a for a in argv if not a.startswith("--")]
    if len(pos) < 2:
        print(__doc__)
        return 1
    circuit, top = pos[0], [None if x in ("-", "") else x for x in pos[1].split(",")]
    opt = {a.split("=")[0]: a.split("=", 1)[1] for a in argv if a.startswith("--") and "=" in a}
    drivers = json.loads((ROOT / "game/data/drivers_2026.json").read_text(encoding="utf-8"))
    ids = {d["id"] for d in (drivers if isinstance(drivers, list) else drivers["drivers"])}
    calendar = {r["id"] for r in json.loads((ROOT / "game/data/calendar_2026.json").read_text(encoding="utf-8"))["rounds"]}
    if circuit not in calendar:
        print("circuito fora do calendário:", circuit)
        return 1
    if len(top) != 10:
        print("informe exatamente 10 posições (use - para as desconhecidas)")
        return 1
    dnf = [x for x in opt.get("--dnf", "").split(",") if x]
    slow = [x for x in opt.get("--slow", "").split(",") if x]
    bad = [x for x in top + dnf + slow if x and x not in ids]
    if bad:
        print("pilotos desconhecidos:", bad)
        return 1
    data = json.loads(RES.read_text(encoding="utf-8"))
    data["rounds"][circuit] = {"top10": top, "dnf": dnf, **({"slow": slow} if slow else {})}
    RES.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    subprocess.run([sys.executable, str(ROOT / "tools/make_real_form.py")], check=True)
    print("resultado de", circuit, "gravado; real_form_2026.json atualizado")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
