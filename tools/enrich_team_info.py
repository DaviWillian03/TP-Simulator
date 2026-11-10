#!/usr/bin/env python3
"""Acrescenta a game/data/teams_2026.json: sede (hq), ano de fundação da equipe atual (founded), herança (heritage) e preenche
o diretor técnico (technical_director) a partir de staff_2026.json (cargo "director", nomes reais) e o chefe de equipe do Alpine.
Fatos estáveis (cidade-sede, origem da equipe); chefes de 2026 conferidos por busca na web em 2026-11-10.
Uso: python tools/enrich_team_info.py"""
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
INFO = {
    "mclaren": ("Woking, Reino Unido", 1963, "Fundada por Bruce McLaren; uma das equipes mais vitoriosas da história."),
    "mercedes": ("Brackley, Reino Unido", 2010, "Herdeira da Tyrrell, BAR, Honda e Brawn GP; equipe oficial Mercedes desde 2010."),
    "ferrari": ("Maranello, Itália", 1950, "A única equipe presente em todas as temporadas do Mundial desde 1950."),
    "redbull": ("Milton Keynes, Reino Unido", 2005, "Comprou a Jaguar e estreou em 2005; motor próprio, com a Ford, a partir de 2026."),
    "williams": ("Grove, Reino Unido", 1977, "Fundada por Frank Williams e Patrick Head; nove títulos de construtores."),
    "racingbulls": ("Faenza, Itália", 2006, "Herdeira da Minardi e da Toro Rosso; equipe-irmã da Red Bull."),
    "astonmartin": ("Silverstone, Reino Unido", 2021, "Herdeira da Jordan, Midland, Spyker, Force India e Racing Point; motor Honda em 2026."),
    "haas": ("Kannapolis, EUA", 2016, "Primeira equipe americana em décadas; parceira técnica da Ferrari."),
    "alpine": ("Enstone, Reino Unido", 2021, "Herdeira da Toleman, Benetton, Renault e Lotus; motor Mercedes em 2026."),
    "audi": ("Hinwil, Suíça", 2026, "A montadora alemã assumiu a Sauber e estreia como Audi em 2026."),
    "cadillac": ("Fishers, EUA", 2026, "A 11ª equipe do grid, estreando em 2026 com motores Ferrari."),
}


def main() -> None:
    p = ROOT / "game/data/teams_2026.json"
    raw = json.loads(p.read_text(encoding="utf-8"))
    teams = raw["teams"] if isinstance(raw, dict) else raw
    staff = json.loads((ROOT / "game/data/staff_2026.json").read_text(encoding="utf-8"))["people"]
    director = {s["team"]: s["name"] for s in staff if s["role"] == "director" and s.get("real")}
    for t in teams:
        hq, founded, heritage = INFO[t["id"]]
        t["hq"], t["founded"], t["heritage"] = hq, founded, heritage
        if t.get("technical_director") is None and t["id"] in director:
            t["technical_director"] = director[t["id"]]
        if t["id"] == "alpine" and t.get("principal") is None:
            t["principal"] = "Steve Nielsen"
            t["principal_title"] = "Diretor-geral (Flavio Briatore é o consultor executivo)"
    p.write_text(json.dumps(raw, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print("ok:", sum(1 for t in teams if t.get("technical_director")), "equipes com diretor técnico")


if __name__ == "__main__":
    main()
