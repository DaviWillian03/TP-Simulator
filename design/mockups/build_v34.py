"""V34 · Campeonato Mundial: tabelas completas que rolam, tela do campeonato ampliada e estatísticas clicáveis (pedido de 2026-11-10).
1) Painel do Mundial: a tabela rola (todos os pilotos/equipes) e tem o botão de ampliar.
2) Campeonato ampliado: tela cheia com a tabela completa (vitórias, pódios, poles, pontos).
3) Estatísticas: quatro quadros clicáveis (vitórias, poles, pódios, abandonos).  4) Ranking completo de uma estatística.
Uso: python design/mockups/build_v34.py   (V26_FACES=<pasta> para a versão local com fotos)"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402
import build_v26 as W  # noqa: E402
import build_v30 as P30  # noqa: E402

HERE = B.HERE
g = W.g
W.P["expand"] = '<path d="M4 9V4h5M20 9V4h-5M4 15v5h5M20 15v5h-5"/>'
W.P["shrink"] = '<path d="M9 4v5H4M15 4v5h5M9 20v-5H4M15 20v-5h5"/>'
emb = P30.emb
TEAM, TC = P30.TEAM, P30.TC
GOLD, GREEN, VIOLET, RED = "#F5C542", "#7fe0b1", "#C77DFF", "#ff8a80"

CSS = P30.CSS + """
.m4s{position:absolute;right:8px;width:6px;border-radius:3px;background:rgba(255,255,255,.28)}
.m4f{position:absolute;left:0;right:0;bottom:0;height:70px;background:linear-gradient(transparent,#171a21)}
.m4h{display:flex;gap:12px;padding:0 12px;font-size:11px;letter-spacing:2px;color:#8f98a7;font-weight:900;margin-top:8px}
.m4q{position:absolute;border-radius:20px;background:#171a21;padding:16px 18px;box-shadow:0 10px 30px rgba(0,0,0,.35)}
.m4g{margin-left:auto;display:flex;align-items:center;gap:6px;font-size:12px;font-weight:900;color:#a8b0bd}
.chip svg,.tabs svg,.m4h svg,.lr svg,.m4q svg,.m4x svg,.m4g svg,.mini svg{position:static;opacity:1;inset:auto}
.m4x{width:44px;height:44px;border-radius:50%;background:rgba(255,255,255,.1);display:grid;place-items:center}
"""

# pontos fictícios só para o mockup (ordem e tamanho de uma tabela real de 22 pilotos)
_FIRST = ["ANT", "VER", "RUS", "NOR", "LEC", "HAM", "PIA", "HAD"]
CODES = _FIRST + [c for c in B.drivers if c not in _FIRST]
PTS = [276, 217, 189, 171, 158, 151, 118, 87, 74, 66, 58, 51, 44, 39, 31, 27, 19, 14, 9, 6, 3, 0]


def rows_drivers(n, cols=True, h=50):
    out = ""
    for i, c in enumerate(CODES[:n]):
        d = B.drivers[c]
        t = B.teams[d["team"]]
        w, pod, pol = max(0, 6 - i), max(0, 9 - i), max(0, 5 - i)
        gap = "LÍDER" if i == 0 else f"−{PTS[0] - PTS[i]}"
        extra = ""
        if cols:
            extra = "".join(f'<span style="width:62px;text-align:center;font-weight:900;font-size:16px;color:{col}">{v}</span>'
                            for v, col in [(w, GOLD), (pod, GREEN), (pol, VIOLET)])
        out += (f'<div class="lr{" me" if d["team"] == TEAM else ""}" style="height:{h}px"><span class="p">{i + 1}</span>{W.face(c, 38, t["color"])}'
                f'<div class="nm" style="min-width:230px">{d["name"].upper()}<small>{emb(d["team"], 14)} {t["name"].upper()}</small></div>'
                f'{extra}<span class="pt" style="margin-left:auto">{PTS[i]}<small>{gap}</small></span></div>')
    return out


def top(title, sub, back=True):
    return P30.top(title, sub)


def painel():
    card = (f'<div class="card" style="left:620px;top:96px;width:620px;height:436px;padding:16px 20px">'
            f'<div style="display:flex;align-items:center;gap:8px"><div class="tabs"><b class="on">PILOTOS</b><b>CONSTRUTORES</b></div><span style="flex:1"></span>'
            f'<span class="m4x">{g("expand", 22)}</span></div>'
            f'<div style="margin-top:6px;height:350px;overflow:hidden;position:relative">{rows_drivers(8, cols=False, h=46)}<div class="m4f"></div></div>'
            f'<span class="m4s" style="top:70px;height:90px"></span></div>')
    left = (f'<div class="card" style="left:40px;top:96px;width:560px;height:330px"></div><div class="card" style="left:40px;top:440px;width:560px;height:244px"></div>'
            f'<div class="card" style="left:620px;top:546px;width:620px;height:138px"></div>')
    return V.page("V34 · Painel do Mundial", CSS, f'<div class="scene"><div class="bgx"></div>{top("CAMPEONATO MUNDIAL F1", "TEMPORADA 2026")}{left}{card}</div>')


def ampliado():
    head = (f'<div class="m4h"><span style="width:26px"></span><span style="width:38px"></span><span style="min-width:230px">PILOTO</span>'
            f'<span style="width:62px;text-align:center">{g("trophy", 14, GOLD)}</span><span style="width:62px;text-align:center">{g("up", 14, GREEN)}</span>'
            f'<span style="width:62px;text-align:center">{g("flag", 14, VIOLET)}</span><span style="margin-left:auto;width:70px;text-align:right">PTS</span></div>')
    card = (f'<div class="card" style="left:40px;top:150px;width:1200px;height:540px;padding:16px 24px">'
            f'<div style="display:flex;align-items:center;gap:8px"><div class="tabs"><b class="on">PILOTOS</b><b>CONSTRUTORES</b><b>ESTATÍSTICAS</b></div><span style="flex:1"></span>'
            f'<span class="chip">{g("trophy", 16, GOLD)}APÓS 6 GPs</span></div>{head}'
            f'<div style="height:410px;overflow:hidden;position:relative">{rows_drivers(8)}<div class="m4f"></div></div><span class="m4s" style="top:110px;height:120px;right:10px"></span></div>')
    return V.page("V34 · Campeonato ampliado", CSS, f'<div class="scene"><div class="bgx"></div>{top("CAMPEONATO", "MUNDIAL F1 · TELA CHEIA")}{card}</div>')


STATS = [("VITÓRIAS", "trophy", GOLD, [("ANT", 6), ("VER", 2), ("RUS", 2)]), ("POLES", "flag", VIOLET, [("ANT", 5), ("RUS", 3), ("NOR", 2)]),
         ("PÓDIOS", "up", GREEN, [("ANT", 9), ("VER", 8), ("HAM", 7)]), ("ABANDONOS", "lock", RED, [("LEC", 3), ("VER", 2), ("RUS", 2)])]


def estatisticas():
    out = ""
    for k, (title, icon, col, data) in enumerate(STATS):
        mx = data[0][1]
        rows = "".join(f'<div style="display:flex;align-items:center;gap:10px;margin-top:10px">{W.face(c, 34, B.teams[B.drivers[c]["team"]]["color"])}'
                       f'<div style="width:140px;font-weight:900;font-size:14px;line-height:1.05">{B.drivers[c]["name"].upper()}</div>'
                       f'<span class="bar"><u style="width:{100 * v / mx:.0f}%;background:{col}"></u></span><b style="width:28px;text-align:right;font-size:18px">{v}</b></div>'
                       for c, v in data)
        out += (f'<div class="m4q" style="left:{40 + (k % 2) * 610}px;top:{150 + (k // 2) * 270}px;width:590px;height:250px">'
                f'<div style="display:flex;align-items:center;gap:8px;font-weight:900;font-size:16px;letter-spacing:1.5px">{g(icon, 22, col)}{title}'
                f'<span class="m4g">{g("chev", 18)}</span></div>{rows}</div>')
    tabs = f'<div style="position:absolute;left:40px;top:96px"><div class="tabs"><b>PILOTOS</b><b>CONSTRUTORES</b><b class="on">ESTATÍSTICAS</b></div></div>'
    seg = f'<div style="position:absolute;right:40px;top:96px"><div class="tabs"><b class="on">PILOTOS</b><b>EQUIPES</b></div></div>'
    return V.page("V34 · Estatísticas clicáveis", CSS, f'<div class="scene"><div class="bgx"></div>{top("CAMPEONATO", "MUNDIAL F1 · ESTATÍSTICAS")}{tabs}{seg}{out}</div>')


def detalhe():
    title, icon, col, _ = STATS[0]
    vals = [6, 2, 2, 2, 1, 1, 0]
    rows = ""
    mx = 6
    for i, c in enumerate(CODES[:7]):
        d = B.drivers[c]
        v = vals[i]
        rows += (f'<div class="lr" style="height:52px"><span class="p">{i + 1}</span>{W.face(c, 38, B.teams[d["team"]]["color"])}'
                 f'<div class="nm" style="min-width:230px">{d["name"].upper()}<small>{emb(d["team"], 14)} {B.teams[d["team"]]["name"].upper()}</small></div>'
                 f'<span class="bar" style="margin:0 20px"><u style="width:{100 * v / mx:.0f}%;background:{col}"></u></span><b style="width:36px;text-align:right;font-size:22px">{v}</b></div>')
    tabs = "".join(f'<b class="{"on" if i == 0 else ""}">{g(ic, 15, "#11141a" if i == 0 else cl)} {t}</b>' for i, (t, ic, cl, _) in enumerate(STATS))
    card = (f'<div class="card" style="left:40px;top:150px;width:1200px;height:540px;padding:16px 24px">'
            f'<div style="display:flex;align-items:center;gap:8px"><div class="tabs">{tabs}</div><span style="flex:1"></span>'
            f'<div class="tabs"><b class="on">PILOTOS</b><b>EQUIPES</b></div></div>'
            f'<div style="height:430px;overflow:hidden;position:relative;margin-top:6px">{rows}<div class="m4f"></div></div><span class="m4s" style="top:90px;height:150px;right:10px"></span></div>')
    back = f'<div style="position:absolute;left:40px;top:96px"><span class="chip">{g("chev", 16).replace("M9 5l7 7-7 7", "M15 5l-7 7 7 7")}ESTATÍSTICAS</span></div>'
    return V.page("V34 · Ranking de vitórias", CSS, f'<div class="scene"><div class="bgx"></div>{top("VITÓRIAS", "MUNDIAL F1 · RANKING COMPLETO")}{back}{card}</div>')


if __name__ == "__main__":
    for name, fn in {"v34-1-painel": painel, "v34-2-ampliado": ampliado, "v34-3-estatisticas": estatisticas, "v34-4-ranking": detalhe}.items():
        (HERE / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
