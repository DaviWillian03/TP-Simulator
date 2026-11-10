"""V35 · Duelo de companheiros no Campeonato Mundial (pedido de 2026-11-10): aba "Companheiros" da tela cheia do campeonato.
Cada equipe é um cartão: os dois pilotos nas pontas e, no meio, o placar de classificação (com a vantagem média de tempo),
de corrida e de pontos, mais vitórias, pódios e abandonos de cada um.
Uso: python design/mockups/build_v35.py   (V26_FACES=<pasta> para a versão local com fotos)"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402
import build_v26 as W  # noqa: E402
import build_v34 as P  # noqa: E402

HERE = B.HERE
g = W.g
GOLD, GREEN, VIOLET, RED = P.GOLD, P.GREEN, P.VIOLET, P.RED
TEAM = P.TEAM

CSS = P.CSS + """
.m5c{display:flex;align-items:center;gap:18px;height:128px;border-radius:20px;background:rgba(255,255,255,.05);padding:0 20px;margin-top:8px}
.m5c.me{background:%s2e;box-shadow:inset 5px 0 0 %s}
.m5d{width:250px;display:flex;align-items:center;gap:12px}.m5d.r{flex-direction:row-reverse;text-align:right}
.m5d b{display:block;font-weight:900;font-size:18px;line-height:1.05}.m5d small{display:block;font-size:12px;color:#8f98a7;font-weight:800;margin-top:3px}
.m5m{flex:1;display:flex;flex-direction:column;gap:7px}
.m5r{display:flex;align-items:center;gap:10px;font-weight:900}.m5r i{font-style:normal;width:22px;text-align:center}
.m5r em{font-style:normal;width:46px;text-align:center;font-size:20px}
.m5b{flex:1;height:10px;border-radius:5px;background:rgba(255,255,255,.12);display:flex;overflow:hidden}.m5b u{display:block;height:100%%;text-decoration:none}
.m5s{display:flex;gap:12px;font-size:12px;font-weight:900;color:#c3c9d3;margin-top:5px}.m5s.r{justify-content:flex-end}
.m5s span{display:inline-flex;align-items:center;gap:3px}
.m5t{width:120px;text-align:center;font-size:12px;font-weight:900;letter-spacing:1px;color:#8f98a7}
.m5v{font-size:12px;font-weight:900;color:#c3c9d3;min-width:96px;text-align:center}
.chip svg,.tabs svg,.m5r svg,.m5s svg,.m5t svg{position:static;opacity:1;inset:auto}
""" % (P.TC, P.TC)

# (equipe, piloto A, piloto B, quali A-B, vantagem média s (+ = A), corrida A-B, pts A, pts B, (v,p,ab) A, (v,p,ab) B)
DUELS = [("mercedes", "ANT", "RUS", (4, 2), +0.182, (4, 2), 145, 92, (3, 5, 0), (1, 5, 0)),
         ("redbull", "VER", "HAD", (5, 1), +0.341, (5, 1), 116, 45, (2, 4, 0), (0, 1, 1)),
         ("williams", "ALB", "SAI", (2, 4), -0.094, (3, 3), 31, 33, (0, 0, 0), (0, 0, 1))]


def card(team, a, b, q, adv, r, pa, pb, sa, sb):
    ta = B.teams[team]
    col = ta["color"]
    da, db = B.drivers[a], B.drivers[b]

    def split(x, y, c1):
        t = (x + y) or 1
        return f'<span class="m5b"><u style="width:{100 * x / t:.0f}%;background:{c1}"></u><u style="width:{100 * y / t:.0f}%;background:rgba(255,255,255,.32)"></u></span>'

    def side(code, name, d, stats, right):
        v, p, ab = stats
        row = (f'<div class="m5s{" r" if right else ""}"><span>{g("trophy", 13, GOLD)}{v}</span><span>{g("up", 13, GREEN)}{p}</span><span>{g("lock", 13, RED)}{ab}</span></div>')
        return (f'<div class="m5d{" r" if right else ""}">{W.face(code, 52, col)}<div><b>{name}</b>{row}</div></div>')

    adv_txt = f'{a if adv >= 0 else b} +{abs(adv):.3f} s'.replace(".", ",")
    mid = (f'<div class="m5m">'
           f'<div class="m5r"><em>{q[0]}</em>{split(q[0], q[1], col)}<em>{q[1]}</em></div>'
           f'<div class="m5r"><em>{r[0]}</em>{split(r[0], r[1], col)}<em>{r[1]}</em></div>'
           f'<div class="m5r"><em>{pa}</em>{split(pa, pb, col)}<em>{pb}</em></div></div>')
    labels = (f'<div class="m5t" style="display:flex;flex-direction:column;gap:7px;line-height:20px"><span>{g("flag", 14, VIOLET)} QUALI</span>'
              f'<span>{g("cal", 14)} CORRIDA</span><span>{g("trophy", 14, GOLD)} PONTOS</span></div>')
    right = f'<div class="m5v">{adv_txt}<div style="font-size:11px;color:#8f98a7;margin-top:4px">MÉDIA NA QUALI</div></div>'
    return (f'<div class="m5c{" me" if team == TEAM else ""}">{side(a, da["name"].upper(), da, sa, False)}'
            f'{mid.replace("m5m", "m5m")}{labels}{right}{side(b, db["name"].upper(), db, sb, True)}</div>')


def aba():
    cards = "".join(card(*d) for d in DUELS)
    tabs = ('<div class="tabs"><b>PILOTOS</b><b>CONSTRUTORES</b><b class="on">COMPANHEIROS</b><b>ESTATÍSTICAS</b></div>')
    panel = (f'<div class="card" style="left:40px;top:84px;width:1200px;height:610px;padding:16px 24px">'
             f'<div style="display:flex;align-items:center">{tabs}<span style="flex:1"></span><span class="chip">{g("trophy", 16, GOLD)}APÓS 6 GPs</span></div>'
             f'<div style="margin-top:8px;height:520px;overflow:hidden;position:relative">{cards}<div class="m4f"></div></div>'
             f'<span class="m4s" style="top:80px;height:140px;right:10px"></span></div>')
    return V.page("V35 · Duelo de companheiros", CSS, f'<div class="scene"><div class="bgx"></div>{P.top("CAMPEONATO", "MUNDIAL F1 · COMPANHEIROS")}{panel}</div>')


if __name__ == "__main__":
    (HERE / "v35-1-companheiros.html").write_text(aba(), encoding="utf-8")
    print("ok")
