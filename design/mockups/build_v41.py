"""V41 · Estratégia pré-corrida no estilo do gráfico de estratégias da transmissão (pedido de 2026-11-18): linhas
horizontais por estratégia (cor do pneu em cada stint), pneus nas janelas de parada ("VOLTA 18 A 24"), rótulo à direita
(UMA / DUAS / TRÊS PARADAS) e legenda dos compostos embaixo. Sempre as três opções, em qualquer pista; a escolhida pode
ser ajustada. Tudo em português, sem logos oficiais (F1/Pirelli), desenho original.
Quadros: 1 escolha da estratégia, 2 ajustando a escolhida (janela da parada e pneu do stint).
Uso: python design/mockups/build_v41.py"""
import pathlib

HERE = pathlib.Path(__file__).parent
TC = "#1347F5"  # Williams
TYRE = {"S": ("#e8392e", "MACIO"), "M": ("#f5c400", "MÉDIO"), "H": ("#f2f2f2", "DURO")}

CSS = """
*{box-sizing:border-box;margin:0;padding:0}
body{background:#07080b;font-family:Kanit,system-ui,sans-serif;color:#fff;text-transform:uppercase;padding:24px;display:flex;flex-direction:column;gap:28px;align-items:center}
.cap{color:#8f98a7;font-weight:800;letter-spacing:2px;font-size:13px;align-self:flex-start;margin-left:calc(50% - 640px)}
.f{width:1280px;height:720px;position:relative;overflow:hidden;border-radius:6px;
  background:repeating-linear-gradient(115deg,rgba(255,255,255,.025) 0 2px,transparent 2px 22px),radial-gradient(circle at 1px 1px,rgba(255,255,255,.07) 1px,transparent 1.5px) 0 0/26px 26px,#0b0c10}
.top{position:absolute;left:40px;right:40px;top:22px;border-bottom:1px solid rgba(255,255,255,.18);padding-bottom:10px}
.small{font-weight:600;letter-spacing:1px;font-size:15px;color:#e8eaee}
.small b{font-weight:900}
.title{position:absolute;left:40px;top:74px;font-weight:900;font-style:italic;font-size:44px;letter-spacing:-1px;line-height:1}
.title span{display:inline-block;width:4px;height:36px;background:#fff;margin:0 18px;vertical-align:-4px;transform:skewX(-12deg)}
.who{position:absolute;right:40px;top:72px;display:flex;gap:8px}
.who div{height:48px;padding:0 16px;border-radius:12px;background:rgba(255,255,255,.08);display:flex;align-items:center;gap:10px;font-weight:900;font-size:15px}
.who div.on{background:#fff;color:#111}
.who i{width:8px;height:26px;border-radius:3px;background:TC}
.hr{position:absolute;left:40px;right:40px;top:140px;height:1px;background:rgba(255,255,255,.18)}
.row{position:absolute;left:40px;right:40px;height:96px;border-radius:16px}
.row.sel{background:linear-gradient(90deg,rgba(19,71,245,.20),rgba(19,71,245,.05));outline:2px solid rgba(255,255,255,.85)}
.line{position:absolute;top:66px;height:5px;border-radius:3px}
.tyre{position:absolute;top:45px;width:46px;height:46px;border-radius:50%;background:#15171c;border:5px solid #333;box-shadow:inset 0 0 0 4px #222,0 4px 10px rgba(0,0,0,.6);display:grid;place-items:center;font-weight:900;font-size:15px}
.lab{position:absolute;top:24px;font-weight:600;font-size:21px;letter-spacing:.5px;white-space:nowrap}
.lab b{font-weight:900}
.name{position:absolute;right:62px;top:20px;font-weight:900;font-style:italic;font-size:26px;letter-spacing:.5px}
.tag{position:absolute;left:14px;top:8px;font-size:11px;font-weight:900;letter-spacing:2px;padding:3px 8px;border-radius:6px;background:#fff;color:#111}
.legend{position:absolute;left:40px;right:40px;top:520px;border-top:1px solid rgba(255,255,255,.18);border-bottom:1px solid rgba(255,255,255,.18);height:96px;display:flex;align-items:center;gap:56px}
.lg{display:flex;align-items:center;gap:14px}
.lg .w{font-weight:600;font-size:20px;line-height:1}
.lg .big{font-weight:900;font-style:italic;font-size:44px}
.lg small{display:block;font-size:12px;letter-spacing:2px;color:#a2a9b5;margin-top:4px;font-weight:800}
.lg .tyre{position:static}
.go{position:absolute;right:40px;bottom:30px;height:58px;padding:0 30px;border-radius:12px;background:#e10600;display:flex;align-items:center;font-weight:900;font-size:21px;clip-path:polygon(0 0,94% 0,100% 25%,100% 100%,0 100%)}
.ghost{position:absolute;bottom:34px;height:50px;padding:0 20px;border-radius:12px;background:rgba(255,255,255,.08);display:flex;align-items:center;font-weight:900;font-size:16px}
.note{position:absolute;background:#ffd24a;color:#111;font-weight:900;font-size:11px;border-radius:8px;padding:4px 8px;text-transform:none;max-width:250px;z-index:5}
.pop{position:absolute;background:#15181f;border:1px solid rgba(255,255,255,.14);border-radius:18px;padding:14px;box-shadow:0 18px 40px rgba(0,0,0,.6);z-index:4}
.pop h4{font-size:12px;letter-spacing:2px;color:#a2a9b5;margin-bottom:10px}
.opt{display:flex;align-items:center;gap:12px;height:52px;padding:0 12px;border-radius:12px;font-weight:900;font-size:16px}
.opt.on{background:rgba(255,255,255,.1)}
.opt .tyre{position:static;width:38px;height:38px;border-width:4px;font-size:13px}
.opt small{color:#a2a9b5;font-size:12px;margin-left:auto;font-weight:800}
.step{display:flex;align-items:center;gap:10px}
.step i{font-style:normal;width:44px;height:44px;border-radius:12px;background:rgba(255,255,255,.1);display:grid;place-items:center;font-size:24px;font-weight:900}
"""


def tyre(letter, left=None, extra=""):
    col = TYRE[letter][0]
    pos = f"left:{left}px;" if left is not None else ""
    return f'<div class="tyre" style="{pos}border-color:{col};{extra}">{letter}</div>'


def row(top, stints, name, sel=False, tag=""):
    """stints: [(letra, voltas)] — desenha a linha colorida por stint, pneus nas paradas e no fim."""
    w = 1200 - 50  # a linha vai até o pneu do fim
    total = sum(n for _, n in stints)
    html = f'<div class="row{" sel" if sel else ""}" style="top:{top}px">'
    if tag:
        html += f'<span class="tag">{tag}</span>'
    x = 0
    lap = 0
    for i, (letter, n) in enumerate(stints):
        seg = w * n / total
        col = TYRE[letter][0]
        nxt = TYRE[stints[i + 1][0]][0] if i + 1 < len(stints) else col
        html += f'<div class="line" style="left:{x:.0f}px;width:{seg:.0f}px;background:linear-gradient(90deg,{col} 70%,{nxt})"></div>'
        lap += n
        x += seg
        if i + 1 < len(stints):
            a, b = lap - 3, lap + 3
            html += f'<div class="lab" style="right:{1200 - x + 30:.0f}px">VOLTA <b>{a}</b> A <b>{b}</b></div>'
            html += tyre(letter, x - 23)
    html += f'<div class="name">{name}</div>' + tyre(stints[-1][0], 1200 - 50)
    return html + "</div>"


def legend():
    items = "".join(
        f'<div class="lg"><div class="w" style="color:{c}">{n}<small>{k} jogo(s) novos</small></div>{tyre(l)}</div>'
        for l, (c, n), k in [("H", TYRE["H"], 2), ("M", TYRE["M"], 3), ("S", TYRE["S"], 1)])
    return f'<div class="legend">{items}<div class="lg" style="margin-left:auto"><div class="w" style="color:#a2a9b5">71 VOLTAS<small>corrida completa</small></div></div></div>'


def head():
    return (f'<div class="top"><span class="small">🇧🇷 <b>BRASIL</b> | GRANDE PRÊMIO DE SÃO PAULO 2026</span></div>'
            f'<div class="title">INTERLAGOS<span></span>ESTRATÉGIAS POSSÍVEIS</div>'
            f'<div class="who"><div class="on"><i style="background:{TC}"></i>ALBON · P9</div><div><i style="background:{TC}"></i>SAINZ · P12</div></div>'
            f'<div class="hr"></div>')


def frame1():
    return f"""<div class="f">{head()}
{row(160, [("M", 22), ("H", 49)], "UMA PARADA")}
{row(272, [("S", 16), ("M", 26), ("H", 29)], "DUAS PARADAS", sel=True, tag="ESCOLHIDA")}
{row(384, [("S", 13), ("M", 18), ("S", 15), ("M", 25)], "TRÊS PARADAS")}
{legend()}
<div class="ghost" style="left:40px">‹ VOLTAR</div>
<div class="ghost" style="left:190px">REFAZER PLANOS</div>
<div class="go">CONFIRMAR ESTRATÉGIA ›</div>
<span class="note" style="left:420px;top:150px">sempre as 3 opções (1, 2 e 3 paradas), em qualquer pista; toque numa linha para escolher</span>
<span class="note" style="left:720px;top:640px">legenda: cor do composto + jogos novos que o piloto ainda tem</span>
</div>"""


def frame2():
    return f"""<div class="f">{head()}
{row(160, [("M", 22), ("H", 49)], "UMA PARADA")}
{row(272, [("S", 18), ("M", 26), ("H", 27)], "DUAS PARADAS", sel=True, tag="ESCOLHIDA · AJUSTADA")}
{row(384, [("S", 13), ("M", 18), ("S", 15), ("M", 25)], "TRÊS PARADAS")}
{legend()}
<div class="pop" style="left:250px;top:356px;width:300px"><h4>PARADA 1 · JANELA</h4>
<div class="step"><i>−</i><div style="flex:1;text-align:center;font-weight:900;font-size:22px">VOLTA 18</div><i>+</i></div>
<div style="margin-top:8px;font-size:12px;color:#a2a9b5;font-weight:800">o box avisa entre a volta 15 e 21</div></div>
<div class="pop" style="left:610px;top:356px;width:300px"><h4>PNEU DO 2º STINT</h4>
<div class="opt">{tyre("S")}MACIO<small>1 NOVO</small></div>
<div class="opt on">{tyre("M")}MÉDIO<small>3 NOVOS</small></div>
<div class="opt">{tyre("H")}DURO<small>2 NOVOS</small></div></div>
<div class="ghost" style="left:40px">‹ VOLTAR</div>
<div class="ghost" style="left:190px">REFAZER PLANOS</div>
<div class="go">CONFIRMAR ESTRATÉGIA ›</div>
<span class="note" style="left:40px;top:330px">toque no pneu da parada: muda a volta (− / +) — no PC, arrastar com o mouse ou setas</span>
<span class="note" style="left:930px;top:360px">toque no trecho da linha: troca o composto (com o estoque de cada um)</span>
</div>"""


def main():
    html = (f'<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>V41 · Estratégias possíveis</title><style>{CSS.replace("TC", TC)}</style><body>'
            f'<div class="cap">1 · Estratégias possíveis (escolher)</div>{frame1()}'
            f'<div class="cap">2 · Ajustando a escolhida (janela da parada e pneu)</div>{frame2()}</body></html>')
    (HERE / "v41-estrategias.html").write_text(html, encoding="utf-8")
    print("ok")


if __name__ == "__main__":
    main()
