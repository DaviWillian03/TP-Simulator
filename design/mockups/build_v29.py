"""V29 · Modo Campeonato Mundial F1 (pedido de 2026-11-10): entrada no menu e painel da temporada.
Uso: python design/mockups/build_v29.py (V26_FACES=<pasta> para a versão local com rostos)."""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402
import build_v26 as W  # noqa: E402

HERE = B.HERE
g = W.g
EMB = W.EMB
IMG = W.IMG
TEAM = "williams"
TC = B.teams[TEAM]["color"]

CSS = W.CSS + """
.card{position:absolute;border-radius:22px;background:#171a21;box-shadow:0 10px 30px rgba(0,0,0,.35);overflow:hidden}
.row2{display:flex;align-items:center;gap:10px;height:38px;border-radius:12px;background:rgba(255,255,255,.05);padding:0 12px;font-weight:900;font-size:15px;margin-top:5px}
.row2 .p{width:24px;text-align:center;color:#a8b0bd}.row2 .t{margin-left:auto}
.row2.me{background:%s33;box-shadow:inset 4px 0 0 %s}
.tabs{display:inline-flex;border-radius:20px;background:rgba(255,255,255,.08);padding:3px;gap:2px}
.tabs b{padding:6px 16px;border-radius:17px;font-size:13px;letter-spacing:1px;color:#a8b0bd}.tabs b.on{background:#f3f4f6;color:#11141a}
.dots{display:inline-flex;gap:5px;flex:none}.dots i{width:14px;height:14px;border-radius:50%%;background:rgba(255,255,255,.14)}.dots i.u{background:#F5C542}.dots i.w{background:#E10600}
.rr{display:flex;align-items:center;gap:8px;font-size:12px;font-weight:900;color:#a8b0bd}
.rr .k{display:grid;place-items:center;width:38px;height:44px;border-radius:10px;background:rgba(255,255,255,.06);line-height:1.1;text-align:center}
.rr .k.nx{background:#f3f4f6;color:#11141a}.rr .k small{display:block;font-size:10px;color:inherit;opacity:.7}
""" % (TC, TC)


def emb(t, s=26):
    return f'<img src="{EMB.format(t)}" style="width:{s}px;height:{s}px;border-radius:{s // 4}px;flex:none">'


def menu():
    camp = (f'<div class="tile" style="left:40px;top:110px;width:700px;height:570px;background:linear-gradient(135deg,#0f3d3a,#0b1916)">'
            f'<div class="big" style="position:absolute;left:28px;top:26px;font-size:64px">MERCEDES</div>'
            f'<span class="chip" style="position:absolute;left:28px;top:96px;background:#E10600">{g("trophy", 16, "#fff")}CAMPANHA</span></div>')
    gp = (f'<div class="tile" style="left:760px;top:110px;width:480px;height:186px">'
          f'<img src="{IMG.format("spa")}" style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover"><div class="shade"></div>'
          f'<div style="position:absolute;left:22px;bottom:16px"><span class="chip" style="background:#4C8DFF">{g("flag", 16, "#fff")}GRANDE PRÊMIO</span>'
          f'<div class="big" style="font-size:34px;margin-top:8px">1 FIM DE SEMANA</div></div></div>')
    wc = (f'<div class="tile" style="left:760px;top:308px;width:480px;height:112px;background:linear-gradient(110deg,#3b2a05,#171a21 70%);box-shadow:0 0 0 3px #F5C542 inset">'
          f'<span style="position:absolute;left:18px;top:18px;width:60px;height:60px;border-radius:18px;background:#F5C542;display:grid;place-items:center">{g("globe", 34, "#11141a")}</span>'
          f'<div style="position:absolute;left:94px;top:16px"><div class="big" style="font-size:25px">CAMPEONATO MUNDIAL F1</div>'
          f'<div style="font-size:14px;color:#c9b27a;font-weight:800;margin-top:8px">22 GPs · SEM DESENVOLVIMENTO</div></div>'
          f'<div style="position:absolute;left:94px;bottom:12px;display:flex;gap:8px"><span class="chip" style="height:26px;font-size:12px">{g("cal", 14)}RD 7/22</span>'
          f'<span class="chip" style="height:26px;font-size:12px">{g("trophy", 14, "#F5C542")}3º</span></div>'
          f'<span style="position:absolute;right:18px;top:36px;width:46px;height:46px;border-radius:50%;background:#fff;display:grid;place-items:center">{g("play", 22, "#11141a")}</span></div>')
    small = [("crown", "HISTÓRIA", "#F5C542", "15 lendas"), ("plus", "NOVA EQUIPE", "#2FD38A", "12ª do grid"), ("lock", "CAÓTICA", "#6c7380", "em breve")]
    sm = "".join(f'<div class="tile" style="left:{760 + i * 164}px;top:432px;width:152px;height:248px;background:linear-gradient(160deg,{c}33,#171a21 60%)">'
                 f'<span style="position:absolute;left:18px;top:20px;width:52px;height:52px;border-radius:16px;background:{c};display:grid;place-items:center">{g(ic, 28, "#11141a")}</span>'
                 f'<div style="position:absolute;left:18px;bottom:20px"><div class="big" style="font-size:20px">{n}</div>'
                 f'<div style="font-size:13px;color:#a8b0bd;font-weight:800;margin-top:4px">{sub}</div></div></div>' for i, (ic, n, c, sub) in enumerate(small))
    body = f'<div class="scene"><div class="bgx"></div><div style="position:absolute;right:44px;top:44px" class="cap">TEMPORADA 2026</div>{camp}{gp}{wc}{sm}</div>'
    return V.page("V29 · Entrada do Mundial no menu", CSS, body)


DR = [("ANT", 276), ("VER", 217), ("RUS", 189), ("NOR", 171), ("LEC", 158), ("HAM", 151), ("PIA", 118), ("HAD", 87), ("ALB", 44)]


def painel():
    gpcard = (f'<div class="card" style="left:40px;top:96px;width:560px;height:330px">'
              f'<img src="{IMG.format("silverstone")}" style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover"><div class="shade"></div>'
              f'<div style="position:absolute;left:22px;top:18px;display:flex;gap:8px"><span class="chip" style="background:#E10600">{g("flag", 16, "#fff")}PRÓXIMO GP</span>'
              f'<span class="chip">{g("cal", 16)}14 JUN</span><span class="chip">{g("tyre", 16)}CHUVA 20%</span></div>'
              f'<div style="position:absolute;left:22px;bottom:84px">{W.flag("silverstone", 30).replace("gb","es")}</div>'
              f'<div class="big" style="position:absolute;left:22px;bottom:30px;font-size:44px;text-shadow:0 2px 12px #000">GP DA ESPANHA</div>'
              f'<span class="cta" style="position:absolute;right:20px;bottom:20px;height:60px;font-size:20px;padding:0 20px">JOGAR FIM DE SEMANA {g("chev", 22, "#fff")}</span></div>')
    cars = ""
    for i, (code, pos, pts, pu, gb, warn) in enumerate([("ALB", 9, 44, 2, 1, False), ("SAI", 10, 38, 2, 1, True)]):
        d = B.drivers[code]
        dots = lambda n, w: "".join(f'<i class="{"w" if (w and k == 4) else ("u" if k < n else "")}"></i>' for k in range(5 if w else 4))
        cars += (f'<div style="display:flex;align-items:center;gap:12px;margin-top:{12 if i else 0}px">{W.face(code, 54, TC)}'
                 f'<div style="width:150px"><div style="font-weight:900;font-size:18px">{d["name"].split()[-1].upper()}</div>'
                 f'<div style="font-size:13px;color:#a8b0bd;font-weight:800">P{pos} · {pts} PTS</div></div>'
                 f'<div style="flex:1"><div class="rr" style="gap:10px"><b style="width:62px;font-size:12px;letter-spacing:1px">MOTOR</b><span class="dots">{dots(pu, warn)}</span></div>'
                 f'<div class="rr" style="gap:10px;margin-top:6px"><b style="width:62px;font-size:12px;letter-spacing:1px">CÂMBIO</b><span class="dots">{dots(gb, False)}</span></div></div>'
                 + (f'<span class="chip" style="background:rgba(225,6,0,.25);color:#ff8a80;height:26px;font-size:12px">{g("up", 14, "#ff8a80")}5º MOTOR: −10 NO GRID</span>' if warn else '') + '</div>')
    parts = (f'<div class="card" style="left:40px;top:440px;width:560px;height:244px;padding:16px 20px">'
             f'<div class="cap" style="margin-bottom:12px">SEUS CARROS · MOTOR E CÂMBIO (LIMITE: 4 NA TEMPORADA)</div>{cars}'
             f'<div style="font-size:12px;color:#8f98a7;font-weight:800;margin-top:14px">{g("bell", 14)} A troca é automática; passou do limite, o carro larga atrás.</div></div>')
    rows = "".join(f'<div class="row2{" me" if B.drivers[c]["team"] == TEAM else ""}"><span class="p">{i + 1}</span>{emb(B.drivers[c]["team"])}'
                   f'<span>{c}</span><span class="t">{p}</span></div>' for i, (c, p) in enumerate(DR))
    stand = (f'<div class="card" style="left:620px;top:96px;width:620px;height:436px;padding:16px 20px">'
             f'<div style="display:flex;align-items:center"><div class="tabs"><b class="on">PILOTOS</b><b>CONSTRUTORES</b></div><span style="flex:1"></span>'
             f'<span class="chip">{g("trophy", 16, "#F5C542")}APÓS 6 GPs</span></div>{rows}</div>')
    strip = "".join(f'<span class="k"><div>{c}</div><small>{n}</small></span>' for c, n in [("ANT", "AUS"), ("ANT", "CHN"), ("ANT", "JPN"), ("ANT", "MIA"), ("ANT", "CAN"), ("ANT", "MON")])
    strip += '<span class="k nx"><div>ESP</div><small>HOJE</small></span>' + "".join(f'<span class="k"><div>·</div><small>{n}</small></span>' for n in ["AUT", "GBR", "BEL"])
    hist = (f'<div class="card" style="left:620px;top:546px;width:620px;height:138px;padding:14px 20px">'
            f'<div class="cap" style="margin-bottom:10px">VENCEDORES · CALENDÁRIO</div><div class="rr">{strip}</div></div>')
    top = (f'<div class="top"><span style="width:48px;height:48px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center">{g("chev", 22).replace("M9 5l7 7-7 7", "M15 5l-7 7 7 7")}</span>'
           f'<div><div class="cap" style="font-size:12px">TEMPORADA 2026 · {B.teams[TEAM]["name"].upper()}</div><div class="big" style="font-size:28px;color:#F5C542">CAMPEONATO MUNDIAL F1</div></div>'
           f'<span style="flex:1"></span><span class="pill">{g("cal", 18)}RD 7/22</span><span class="pill">{g("trophy", 18, "#F5C542")}9º · 44 PTS</span></div>')
    return V.page("V29 · Painel do Campeonato Mundial F1", CSS, f'<div class="scene"><div class="bgx"></div>{top}{gpcard}{parts}{stand}{hist}</div>')


if __name__ == "__main__":
    for name, fn in {"v29-1-menu": menu, "v29-2-painel": painel}.items():
        (HERE / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
