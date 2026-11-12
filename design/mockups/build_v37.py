"""V37 · Seletor de temporada 2026 | 2012 (decisão de 2026-11-12): no Grande Prêmio e na escolha de equipe do Mundial.
Em 2012 somem F2/F3 (só existe a F1 daquele ano), a lista de pistas vira o calendário de 2012 e o grid vira o de 2012
com as cores da época. Emblemas ORIGINAIS (sem logos oficiais). Uso: python design/mockups/build_v37.py"""
import json
import pathlib

HERE = pathlib.Path(__file__).parent
ROOT = HERE.parent.parent
T12 = json.loads((ROOT / "game/data/seasons/2012/teams.json").read_text(encoding="utf-8"))["teams"]
CAL = json.loads((ROOT / "game/data/seasons/2012/calendar.json").read_text(encoding="utf-8"))["rounds"]

CSS = """
*{box-sizing:border-box;margin:0;padding:0}
body{background:#0b0d12;font-family:Kanit,system-ui,sans-serif;color:#fff;text-transform:uppercase;padding:24px;display:flex;flex-direction:column;gap:28px;align-items:center}
.cap{color:#8f98a7;font-weight:800;letter-spacing:2px;font-size:13px;align-self:flex-start;margin-left:calc(50% - 640px)}
.f{width:1280px;height:720px;position:relative;overflow:hidden;border-radius:6px}
.gp{background:radial-gradient(ellipse at 50% 40%,#4a3420,#24180f 70%)}
.ts{background:linear-gradient(#1c2740,#101624)}
.seg{display:flex;background:rgba(255,255,255,.08);border-radius:26px;padding:4px;gap:2px}
.seg span{min-width:76px;height:44px;border-radius:22px;display:grid;place-items:center;font-weight:900;font-size:17px;color:#a2a9b5;padding:0 14px}
.seg span.on{background:#f2f3f5;color:#111}
.seg span.off{opacity:.25}
.back{position:absolute;left:40px;top:30px;width:46px;height:46px;border-radius:50%;background:rgba(255,255,255,.1);display:grid;place-items:center;font-size:22px}
.title{position:absolute;left:104px;top:20px}
.title small{display:block;color:#8f98a7;font-weight:800;letter-spacing:3px;font-size:13px}
.title b{font-size:34px;font-weight:900;color:#4f8ef7}
.cards{position:absolute;left:28px;right:0;top:86px;display:flex;gap:16px}
.card{width:232px;height:338px;flex:none;border-radius:14px;position:relative;overflow:hidden;background:linear-gradient(#6fa06a,#2f5a2c)}
.card.sel{outline:4px solid #fff}
.card .d{position:absolute;left:12px;top:12px;background:rgba(0,0,0,.6);border-radius:8px;padding:2px 8px;font-size:12px;font-weight:900;letter-spacing:2px}
.card .n{position:absolute;left:16px;bottom:40px;font-size:22px;font-weight:900;text-shadow:0 2px 6px #000}
.card .ty{position:absolute;left:16px;bottom:14px;display:flex;gap:6px}
.card .ty i{width:18px;height:18px;border-radius:50%;border:3px solid;font-style:normal}
.panel{position:absolute;left:40px;right:40px;bottom:18px;height:238px;border-radius:22px;background:#191c24;padding:22px}
.h{color:#8f98a7;font-weight:900;letter-spacing:2.5px;font-size:13px;margin-bottom:12px}
.grid{display:grid;grid-template-columns:repeat(6,56px);gap:10px}
.em{width:56px;height:56px;border-radius:14px;display:grid;place-items:center;font-weight:900;font-size:17px}
.em.on{outline:3px solid #fff;outline-offset:3px}
.go{position:absolute;right:22px;bottom:22px;width:392px;height:60px;border-radius:12px;background:#e10600;display:flex;align-items:center;justify-content:center;font-size:22px;font-weight:900;clip-path:polygon(0 0,95% 0,100% 22%,100% 100%,0 100%)}
.new{position:absolute;background:#ffd24a;color:#111;font-weight:900;font-size:12px;border-radius:8px;padding:3px 8px;letter-spacing:1px}
.ts .tag{position:absolute;left:44px;top:26px;background:#e10600;border-radius:6px;padding:4px 10px;font-size:13px;font-weight:900}
.ts .nm{position:absolute;left:44px;top:66px;font-size:42px;font-weight:900}
.ts .big{position:absolute;left:0;right:0;top:170px;text-align:center;font-size:150px;font-weight:900;color:transparent;-webkit-text-stroke:2px rgba(255,255,255,.4)}
.car{position:absolute;left:330px;top:370px;width:620px;height:110px;border-radius:60px 30px 20px 20px}
.box{position:absolute;border-radius:22px;background:rgba(8,10,16,.85);padding:16px}
.drv{display:flex;align-items:center;gap:12px;background:rgba(255,255,255,.05);border-radius:14px;padding:10px;margin-top:10px}
.av{width:54px;height:54px;border-radius:50%;display:grid;place-items:center;font-weight:900}
.row{display:flex;justify-content:space-between;font-weight:800;font-size:15px;margin-top:10px;color:#c3c9d3}
.row b{color:#fff}
.bar{position:absolute;left:44px;bottom:24px;display:flex;gap:10px}
.btns{position:absolute;right:44px;bottom:24px;display:flex;gap:10px}
.btn{height:60px;border-radius:14px;display:grid;place-items:center;font-weight:900;padding:0 26px;font-size:18px}
"""


def ink(c):
    c = c.lstrip("#")
    r, g, b = (int(c[i:i + 2], 16) for i in (0, 2, 4))
    return "#111" if 0.299 * r + 0.587 * g + 0.114 * b > 160 else "#fff"


def emblem(t, on=False, size=56):
    return (f'<span class="em{" on" if on else ""}" style="width:{size}px;height:{size}px;background:{t["color"]};'
            f'color:{ink(t["color"])};box-shadow:inset 0 -6px 0 {t["color2"]}">{t["emblem"]["text"]}</span>')


def gp_frame():
    cards = ""
    for rd in CAL[13:18]:
        name = rd.get("grand_prix", rd["id"]).replace("GP da ", "").replace("GP do ", "").replace("GP de ", "").replace("GP dos ", "")
        miss = rd["id"] in ("yeongam", "buddh", "valencia")
        cards += (f'<div class="card{" sel" if rd["id"] == "suzuka" else ""}" style="{"background:#2a2d35;opacity:.5" if miss else ""}">'
                  f'<span class="d">{rd.get("date", "")[8:10]}/{rd.get("date", "")[5:7]}</span>'
                  f'<span class="n">{name}</span><span class="ty">'
                  + "".join(f'<i style="border-color:{c}"></i>' for c in ("#e10600", "#ffd24a")) + "</span></div>")
    teams = "".join(emblem(t, t["id"] == "lotus") for t in T12)
    return f"""<div class="f gp"><span class="back">‹</span>
<div class="title"><small>Grande Prêmio</small><div style="display:flex;gap:14px;align-items:center;margin-top:4px">
<div class="seg"><span>2026</span><span class="on">2012</span></div></div></div>
<div style="position:absolute;right:40px;top:22px" class="seg"><span class="on">F1</span><span class="off">F2</span><span class="off">F3</span></div>
<div class="cards" style="top:100px;height:300px">{cards.replace('height:338px', '')}</div>
<div class="panel"><div style="display:flex;gap:60px"><div><div class="h">Equipe</div><div class="grid">{teams}</div></div>
<div><div class="h">Duração</div><div class="seg"><span class="on">25%</span><span>50%</span><span>100%</span></div>
<div class="h" style="margin-top:22px">Clima</div><div class="seg"><span class="on">Realista</span><span>Seco</span><span>Chuva</span></div></div></div>
<div class="go">Começar fim de semana ›</div></div></div>"""


def ts_frame():
    t = next(x for x in T12 if x["id"] == "mclaren")
    bar = "".join(emblem(x, x["id"] == "mclaren", 52) for x in T12)
    return f"""<div class="f ts"><span class="tag">Escolha de equipe</span><span class="nm">McLaren</span>
<div style="position:absolute;left:44px;top:126px;color:#c3c9d3;font-weight:800">Campeonato Mundial</div>
<div style="position:absolute;right:44px;top:30px" class="seg"><span>2026</span><span class="on">2012</span></div>
<div class="big">McLaren</div>
<div class="car" style="background:linear-gradient(90deg,{t["color"]} 60%,{t["color2"]} 60% 64%,{t["color"]} 64%)"></div>
<div class="box" style="left:44px;top:306px;width:286px;height:300px"><div class="h">Carro 2012</div>
<div style="font-size:34px;font-weight:900">87 <small style="font-size:14px;color:#c3c9d3">3º carro do grid</small></div>
<div class="row">Chefe de equipe<b>Martin Whitmarsh</b></div><div class="row">Diretor técnico<b>Paddy Lowe</b></div>
<div class="row">Motor<b>Mercedes</b></div><div class="row">Sede<b>Woking</b></div></div>
<div class="box" style="right:44px;top:306px;width:318px"><div class="h">Pilotos</div>
<div class="drv"><b style="font-size:30px">3</b><span class="av" style="background:{t["color"]};color:#111">JB</span><div><b>Jenson Button</b><div style="color:#8f98a7;font-size:13px">Reino Unido · 32 anos · 1 título</div></div></div>
<div class="drv"><b style="font-size:30px">4</b><span class="av" style="background:{t["color"]};color:#111">LH</span><div><b>Lewis Hamilton</b><div style="color:#8f98a7;font-size:13px">Reino Unido · 27 anos · 1 título</div></div></div></div>
<div class="bar">{bar}</div>
<div class="btns"><span class="btn" style="background:#11141b">‹ Voltar</span><span class="btn" style="background:#e10600">Confirmar ›</span></div></div>"""


def main():
    html = (f'<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>V37 · Seletor de temporada</title><style>{CSS}</style><body>'
            f'<div class="cap">1 · Grande Prêmio com 2012: F2/F3 apagados, calendário e grid de 2012 (pistas sem traçado ficam apagadas)</div>{gp_frame()}'
            f'<div class="cap">2 · Mundial: o ano no canto, onde ficaria F1/F2/F3; grid e cores de 2012 (McLaren prateada)</div>{ts_frame()}</body></html>')
    (HERE / "v37-seletor-temporada.html").write_text(html, encoding="utf-8")
    print("ok")


if __name__ == "__main__":
    main()
