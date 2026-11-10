"""V30 · Campeonato Mundial F1: tabela com fotos e nome completo, resultado de cada corrida e estatísticas da temporada
(pedido de 2026-11-10). Uso: python design/mockups/build_v30.py (V26_FACES=<pasta> para a versão local com fotos)."""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402
import build_v26 as W  # noqa: E402

HERE = B.HERE
g = W.g
EMB = W.EMB
TEAM = "williams"
TC = B.teams[TEAM]["color"]

CSS = W.CSS + """
.card{position:absolute;border-radius:22px;background:#171a21;box-shadow:0 10px 30px rgba(0,0,0,.35);overflow:hidden}
.tabs{display:inline-flex;border-radius:20px;background:rgba(255,255,255,.08);padding:3px;gap:2px}
.tabs b{padding:7px 18px;border-radius:17px;font-size:13px;letter-spacing:1px;color:#a8b0bd}.tabs b.on{background:#f3f4f6;color:#11141a}
.lr{display:flex;align-items:center;gap:12px;height:50px;border-radius:14px;background:rgba(255,255,255,.05);padding:0 12px;margin-top:5px}
.lr.me{background:%s2e;box-shadow:inset 4px 0 0 %s}
.lr .p{width:26px;text-align:center;font-weight:900;color:#a8b0bd;font-size:16px}
.lr .nm{font-weight:900;font-size:16px;line-height:1.05}.lr .nm small{display:block;font-size:12px;color:#8f98a7;font-weight:800;margin-top:2px}
.lr .pt{margin-left:auto;font-weight:900;font-size:20px;text-align:right;line-height:1}.lr .pt small{display:block;font-size:11px;color:#8f98a7;margin-top:3px}
.mini{display:inline-flex;align-items:center;gap:4px;font-size:12px;font-weight:900;color:#c3c9d3;margin-left:10px}
.podium{position:absolute;border-radius:20px;text-align:center;padding-top:14px;display:flex;flex-direction:column;align-items:center}
.stat{border-radius:20px;background:#171a21;position:absolute;padding:14px 16px;box-shadow:0 10px 30px rgba(0,0,0,.35)}
.bar{height:8px;border-radius:4px;background:rgba(255,255,255,.1);flex:1;overflow:hidden}.bar u{display:block;height:100%%;text-decoration:none}
""" % (TC, TC)


def emb(t, s=26):
    return f'<img src="{EMB.format(t)}" style="width:{s}px;height:{s}px;border-radius:{s // 4}px;flex:none">'


def top(title, sub):
    return (f'<div class="top"><span style="width:48px;height:48px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center">'
            f'{g("chev", 22).replace("M9 5l7 7-7 7", "M15 5l-7 7 7 7")}</span><div><div class="cap" style="font-size:12px">{sub}</div>'
            f'<div class="big" style="font-size:28px;color:#F5C542">{title}</div></div><span style="flex:1"></span>'
            f'<span class="pill">{g("cal", 18)}RD 7/22</span><span class="pill">{g("trophy", 18, "#F5C542")}9º · 44 PTS</span></div>')


D = [("ANT", "Kimi Antonelli", 276, 6, 9, 5), ("VER", "Max Verstappen", 217, 2, 8, 1), ("RUS", "George Russell", 189, 2, 6, 1),
     ("NOR", "Lando Norris", 171, 2, 5, 0), ("LEC", "Charles Leclerc", 158, 1, 5, 1), ("HAM", "Lewis Hamilton", 151, 1, 7, 0),
     ("PIA", "Oscar Piastri", 118, 0, 3, 0), ("HAD", "Isack Hadjar", 87, 0, 3, 0)]


def tabela():
    rows = ""
    for i, (c, name, pts, w, pod, pol) in enumerate(D):
        d = B.drivers[c]
        t = B.teams[d["team"]]["name"]
        gap = "LÍDER" if i == 0 else f"−{D[0][2] - pts}"
        rows += (f'<div class="lr{" me" if d["team"] == TEAM else ""}"><span class="p">{i + 1}</span>{W.face(c, 38, B.teams[d["team"]]["color"])}'
                 f'<div class="nm">{name.upper()}<small>{emb(d["team"], 14)} {t.upper()}</small></div>'
                 f'<span class="mini">{g("trophy", 13, "#F5C542")}{w}</span><span class="mini">{g("up", 13, "#7fe0b1")}{pod}</span>'
                 f'<span class="pt">{pts}<small>{gap}</small></span></div>')
    card = (f'<div class="card" style="left:300px;top:96px;width:680px;height:590px;padding:16px 20px">'
            f'<div style="display:flex;align-items:center"><div class="tabs"><b class="on">PILOTOS</b><b>CONSTRUTORES</b></div><span style="flex:1"></span>'
            f'<span class="chip">{g("trophy", 16, "#F5C542")}APÓS 6 GPs</span></div>{rows}'
            f'<div style="font-size:12px;color:#8f98a7;font-weight:800;margin-top:10px">{g("trophy", 13, "#F5C542")} VITÓRIAS · {g("up", 13, "#7fe0b1")} PÓDIOS · toque num piloto para ver a temporada dele</div></div>')
    return V.page("V30 · Tabela com fotos", CSS, f'<div class="scene"><div class="bgx"></div>{top("CAMPEONATO MUNDIAL F1", "TEMPORADA 2026 · TABELA")}{card}</div>')


def resultado():
    pod = ""
    for k, (c, left, h, col) in enumerate([("VER", 60, 250, "#C0C6D0"), ("ANT", 250, 290, "#F5C542"), ("RUS", 440, 230, "#C98A4B")]):
        d = B.drivers[c]
        pos = {"VER": 2, "ANT": 1, "RUS": 3}[c]
        pod += (f'<div class="podium" style="left:{left}px;bottom:0;width:180px;height:{h}px;background:linear-gradient(#232733,{B.teams[d["team"]]["color"]}55)">'
                f'<div style="font-weight:900;font-size:30px;color:{col}">{pos}</div>{W.face(c, 84 if pos == 1 else 70, col)}'
                f'<div style="font-weight:900;font-size:15px;margin-top:8px;line-height:1.05">{d["name"].upper()}</div>'
                f'<div style="font-size:12px;color:#a8b0bd;font-weight:800;margin-top:3px">{emb(d["team"], 14)} {pos == 1 and "1:32:08.4" or "+4,3 s" if pos == 2 else "+9,8 s"}</div></div>')
    order = ["LEC", "HAM", "NOR", "PIA", "HAD", "LAW", "ALB", "SAI", "BEA", "GAS"]
    pts = [12, 10, 8, 6, 4, 2, 1, 0, 0, 0]
    rows = ""
    for i, c in enumerate(order):
        d = B.drivers[c]
        delta = ["▲2", "▲1", "▼1", "▲3", "—", "▼2", "▲1", "▼3", "—", "▲4"][i]
        col = "#7fe0b1" if "▲" in delta else ("#ff8a80" if "▼" in delta else "#8f98a7")
        rows += (f'<div class="lr{" me" if d["team"] == TEAM else ""}" style="height:38px;margin-top:3px"><span class="p">{i + 4}</span>{W.face(c, 28, B.teams[d["team"]]["color"])}'
                 f'<div class="nm" style="font-size:14px">{d["name"].upper()}</div><span style="font-size:12px;font-weight:900;color:{col}">{delta}</span>'
                 f'<span class="pt" style="font-size:15px">+{pts[i]}</span></div>')
    left = (f'<div class="card" style="left:30px;top:150px;width:640px;height:470px;background:linear-gradient(160deg,#1c2030,#12141a)">'
            f'<div style="position:absolute;left:20px;top:14px;display:flex;gap:8px"><span class="chip" style="background:#F5C542;color:#11141a">{g("trophy", 16, "#11141a")}POLE: ANTONELLI 1:08,912</span>'
            f'<span class="chip">{g("timer", 16)}MELHOR VOLTA: VERSTAPPEN 1:12,4</span></div>'
            f'<div style="position:absolute;left:0;right:0;bottom:0;height:380px">{pod}</div></div>')
    right = (f'<div class="card" style="left:690px;top:150px;width:560px;height:470px;padding:12px 16px"><div class="cap" style="margin-bottom:6px">DO 4º AO 13º · POSIÇÕES GANHAS NA LARGADA</div>{rows}</div>')
    tabs = (f'<div style="position:absolute;left:30px;top:96px"><div class="tabs"><b class="on">RESULTADO</b><b>CAMPEONATO</b><b>ESTATÍSTICAS</b></div></div>'
            f'<span class="chip" style="position:absolute;right:30px;top:100px;height:34px">{W.flag("silverstone", 22)} GP DA ESPANHA · FIM DE SEMANA ENCERRADO</span>')
    cta = f'<div class="cta" style="position:absolute;right:30px;bottom:30px;height:56px;font-size:20px;min-width:260px">CONTINUAR{g("chev", 22, "#fff")}</div>'
    return V.page("V30 · Resultado do GP", CSS, f'<div class="scene"><div class="bgx"></div>{top("RESULTADO DO GP", "CAMPEONATO MUNDIAL F1 · RODADA 7")}{tabs}{left}{right}{cta}</div>')


def estatisticas():
    def block(title, icon, col, data, x, y, unit):
        mx = max(v for _, v in data)
        rows = "".join(f'<div style="display:flex;align-items:center;gap:10px;margin-top:8px">{W.face(c, 32, B.teams[B.drivers[c]["team"]]["color"])}'
                       f'<div style="width:130px;font-weight:900;font-size:14px;line-height:1.05">{B.drivers[c]["name"].upper()}</div>'
                       f'<span class="bar"><u style="width:{100 * v / mx:.0f}%;background:{col}"></u></span><b style="width:28px;text-align:right;font-size:18px">{v}</b></div>'
                       for c, v in data)
        return (f'<div class="stat" style="left:{x}px;top:{y}px;width:590px;height:270px"><div style="display:flex;align-items:center;gap:8px;font-weight:900;font-size:15px;letter-spacing:1.5px">'
                f'{g(icon, 20, col)}{title}<span style="flex:1"></span><span class="cap">{unit}</span></div>{rows}</div>')
    b1 = block("VITÓRIAS", "trophy", "#F5C542", [("ANT", 6), ("VER", 2), ("RUS", 2), ("NOR", 2), ("LEC", 1)], 30, 150, "NA TEMPORADA")
    b2 = block("POLES", "flag", "#C77DFF", [("ANT", 5), ("RUS", 3), ("NOR", 2), ("VER", 1), ("LEC", 1)], 660, 150, "NA TEMPORADA")
    b3 = block("PÓDIOS", "up", "#7fe0b1", [("ANT", 9), ("VER", 8), ("HAM", 7), ("RUS", 6), ("LEC", 5)], 30, 436, "NA TEMPORADA")
    b4 = block("ABANDONOS", "lock", "#ff8a80", [("LEC", 3), ("VER", 2), ("RUS", 2), ("HAM", 1), ("NOR", 1)], 660, 436, "NA TEMPORADA")
    tabs = f'<div style="position:absolute;left:30px;top:96px"><div class="tabs"><b>RESULTADO</b><b>CAMPEONATO</b><b class="on">ESTATÍSTICAS</b></div></div>'
    note = f'<span class="chip" style="position:absolute;right:30px;top:100px;height:34px">{g("bell", 16)}pilotos · construtores · por GP (toque)</span>'
    return V.page("V30 · Estatísticas da temporada", CSS, f'<div class="scene"><div class="bgx"></div>{top("ESTATÍSTICAS", "CAMPEONATO MUNDIAL F1 · APÓS 6 GPs")}{tabs}{note}{b1}{b2}{b3}{b4}</div>')


if __name__ == "__main__":
    for name, fn in {"v30-1-tabela": tabela, "v30-2-resultado": resultado, "v30-3-estatisticas": estatisticas}.items():
        (HERE / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
