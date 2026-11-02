"""Campanha — Finanças e Patrocínios (direção Garagem).
Uso: python design/mockups/build_v11.py   (gera v11-*.html nesta pasta)
Equipe criada de exemplo (Aurora Racing, fictícia). Marcas reais só como TEXTO, sem logos (decisão do usuário);
sem tabaco/apostas. Valores, ofertas e prazos são EXEMPLOS PROVISÓRIOS.
Decisões: 5 zonas do carro com valor (asa traseira, laterais, bico, halo, asa dianteira), um patrocinador por
zona, contrato de 1 a 3 anos com valor por corrida e bônus por pódio; as marcas fazem ofertas conforme a
influência e o jogador aceita, recusa ou pede mais; Finanças = resumo (receitas × despesas, projeção, histórico).
"""
import math
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402
import build_v6 as S6  # noqa: E402
import build_v9 as N  # noqa: E402

HERE = B.HERE
ico = V.ico
C1, C2 = S6.C1, S6.C2

CSS = N.CSS + """
.card2{position:absolute;border-radius:22px;background:rgba(255,255,255,.06);padding:16px 20px}
.fr{display:flex;align-items:center;gap:10px;height:30px;font-size:15px}.fr .n{width:200px;font-weight:700;color:#e3e6eb}.fr .b{flex:1;height:10px;border-radius:5px;background:rgba(255,255,255,.08);position:relative}.fr .b i{position:absolute;inset:0 auto 0 0;border-radius:5px}
.fr .v{width:92px;text-align:right;font-weight:900;font-size:16px}
.tot{display:flex;justify-content:space-between;align-items:baseline;border-top:1px solid rgba(255,255,255,.12);margin-top:6px;padding-top:8px;font-size:15px;color:#c3c9d3}.tot b{font-size:22px;font-weight:900;color:#fff}
.hist{width:100%;border-collapse:collapse;font-size:14px}.hist td,.hist th{padding:7px 6px;text-align:right;border-bottom:1px solid rgba(255,255,255,.07)}.hist th{font-size:11px;letter-spacing:2px;color:#8f98a7;font-weight:700}.hist td:first-child,.hist th:first-child{text-align:left}
.zone{display:flex;align-items:center;gap:12px;height:48px;border-radius:16px;background:rgba(255,255,255,.07);padding:0 14px;margin-bottom:6px;position:relative}
.zone.sel{background:#f3f4f6;color:#11141a}.zone .num{width:30px;height:30px;border-radius:50%;background:#E10600;color:#fff;display:grid;place-items:center;font-weight:900;font-size:15px;flex:none}
.zone b{display:block;font-size:16px;font-weight:900;line-height:1.1}.zone small{font-size:12px;color:#a8b0bd;font-weight:700}.zone.sel small{color:#4b5260}
.zone .rt{margin-left:auto;text-align:right}.zone .rt b{font-size:17px}
.brand{display:inline-block;height:30px;line-height:30px;padding:0 12px;border-radius:8px;background:#fff;color:#11141a;font-weight:900;font-size:15px;letter-spacing:.3px}
.offer{display:flex;align-items:center;gap:12px;height:60px;border-radius:16px;background:rgba(255,255,255,.07);padding:0 14px;margin-bottom:6px}
.offer .t{flex:1}.offer .t small{display:block;font-size:12px;color:#a8b0bd;font-weight:700;margin-top:2px}
.offer .v{text-align:right}.offer .v b{display:block;font-size:19px;font-weight:900}.offer .v small{font-size:12px;color:#7fe0b1;font-weight:700}
.pin{position:absolute;width:30px;height:30px;border-radius:50%;background:#E10600;color:#fff;display:grid;place-items:center;font-weight:900;font-size:15px;border:3px solid #fff;box-shadow:0 4px 12px rgba(0,0,0,.5)}
.pin.free{background:#2b2f38;border-color:#8f98a7;color:#c3c9d3}
.inf{display:flex;gap:5px}.inf i{width:22px;height:10px;border-radius:5px;background:rgba(255,255,255,.14)}.inf i.f{background:#ffd24a}
"""


def topbar(sub, title, chips):
    cs = "".join(f'<div class="chipm"><div><small>{k}</small>{v}</div></div>' for k, v in chips)
    return (f'<div class="top"><span class="round">{ico("back", 26, "#eef0f3", 2.6)}</span>'
            f'<svg width="46" height="46" viewBox="0 0 24 24"><path d="M7 2h10l5 10-5 10H7L2 12z" fill="{C1}" stroke="{C2}" stroke-width="1.4"/></svg>'
            f'<div class="tm"><b>{sub}</b><h1>{title}</h1></div><div style="margin-left:auto;display:flex;gap:10px">{cs}</div></div>')


def nav(on):
    items = ["Início", "Campeonatos", "Pessoal", "Carro", "Fábrica", "Patrocínios", "Finanças"]
    return '<div class="nav">' + "".join(f'<span class="{"on" if k == on else ""}">{i}</span>' for k, i in enumerate(items)) + "</div>"


def frow(name, value, pct, color):
    return f'<div class="fr"><span class="n">{name}</span><span class="b"><i style="width:{pct}%;background:{color}"></i></span><span class="v">{value}</span></div>'


def chart():
    # caixa após cada rodada (linha cheia) e projeção até o fim (tracejada)
    real = [176, 181, 178, 183, 186, 180, 184, 190]
    proj = [190, 196, 201, 207, 212, 205, 211, 218, 223, 229, 234, 240, 246, 251]
    w, h, x0, y0 = 610, 180, 20, 10
    lo, hi = 150, 280

    def pt(i, v):
        return x0 + i * (w - 2 * x0) / 21, y0 + (1 - (v - lo) / (hi - lo)) * (h - 2 * y0)
    a = " ".join(f"{pt(i, v)[0]:.1f},{pt(i, v)[1]:.1f}" for i, v in enumerate(real))
    b = " ".join(f"{pt(i + len(real) - 1, v)[0]:.1f},{pt(i + len(real) - 1, v)[1]:.1f}" for i, v in enumerate(proj))
    x7, y7 = pt(len(real) - 1, real[-1])
    return (f'<svg width="{w}" height="{h + 24}" viewBox="0 0 {w} {h + 24}"><line x1="{x0}" y1="{pt(0, 160)[1]:.0f}" x2="{w - x0}" y2="{pt(0, 160)[1]:.0f}" stroke="#ff6a5a" stroke-opacity=".5" stroke-dasharray="4 6"/>'
            f'<text x="{x0 + 4}" y="{pt(0, 160)[1] - 5:.0f}" font-size="11" font-weight="700" fill="#ff6a5a" letter-spacing="1.5">RESERVA MÍNIMA</text>'
            f'<polyline points="{b}" fill="none" stroke="#8f98a7" stroke-width="3" stroke-dasharray="3 7" stroke-linecap="round"/>'
            f'<polyline points="{a}" fill="none" stroke="#3ec9a6" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>'
            f'<circle cx="{x7:.1f}" cy="{y7:.1f}" r="7" fill="#fff" stroke="#3ec9a6" stroke-width="3"/>'
            f'<text x="{x0}" y="{h + 16}" font-size="11" fill="#8f98a7" letter-spacing="1.5">RD 1</text><text x="{w - x0 - 34}" y="{h + 16}" font-size="11" fill="#8f98a7" letter-spacing="1.5">RD 22</text></svg>')


def financas():
    rec = (frow("Patrocínios", "US$ 24 mi", 100, "#3ec9a6") + frow("Bônus de resultado", "US$ 1,2 mi", 5, "#3ec9a6")
           + f'<div class="tot"><span>Receitas até agora</span><b style="color:#7fe0b1">US$ 25,2 mi</b></div>')
    dep = (frow("Corridas e operação", "US$ 6,4 mi", 22, "#ff6a5a") + frow("Folha de pagamento", "US$ 5,6 mi", 19, "#ff6a5a")
           + frow("Manutenção da fábrica", "US$ 3,2 mi", 11, "#ff6a5a") + frow("P&D (projetos)", "US$ 58 mi", 100, "#ffd24a")
           + frow("Obras da fábrica", "US$ 30 mi", 52, "#ffd24a") + frow("Contratos e multas", "US$ 3,5 mi", 12, "#ffd24a")
           + f'<div class="tot"><span>Despesas até agora</span><b style="color:#ffb4a8">US$ 106,7 mi</b></div>')
    hist = ('<table class="hist"><tr><th>TEMPORADA</th><th>POSIÇÃO</th><th>PRÊMIO</th><th>SALDO FINAL</th></tr>'
            '<tr><td>2025</td><td>10º</td><td>US$ 30 mi</td><td>US$ 118 mi</td></tr></table>'
            '<div style="font-size:12px;color:#8f98a7;margin-top:8px">Aparece a cada temporada encerrada.</div>')
    body = f'''<div class="scene"><div class="wall" style="bottom:0"></div><div class="glow" style="background:radial-gradient(ellipse 45% 55% at 70% 50%,{C1}44,transparent 70%)"></div>
{topbar("AURORA RACING · APÓS 8 DE 22 RODADAS", "FINANÇAS", [("CAIXA", "US$ 190 mi"), ("PROJEÇÃO FIM DA TEMPORADA", "US$ 251 mi")])}{nav(6)}
<div class="card2" style="left:44px;top:150px;width:520px;height:190px"><div class="lbl">RECEITAS · TEMPORADA 2026</div>{rec}</div>
<div class="card2" style="left:44px;top:352px;width:520px;height:348px"><div class="lbl">DESPESAS · TEMPORADA 2026</div>{dep}</div>
<div class="card2" style="left:580px;top:150px;width:656px;height:296px"><div class="lbl">CAIXA APÓS CADA RODADA · PROJEÇÃO</div>{chart()}
<div style="display:flex;gap:26px;font-size:13px;color:#c3c9d3"><span><b style="color:#3ec9a6">━</b> realizado</span><span><b style="color:#8f98a7">┅</b> projeção (receitas fixas − custos fixos + prêmio esperado)</span></div></div>
<div class="card2" style="left:580px;top:458px;width:320px;height:242px"><div class="lbl">POR CORRIDA</div>
<div class="fr"><span class="n" style="width:160px">Patrocínios</span><span class="v" style="color:#7fe0b1;flex:1">+ US$ 3,0 mi</span></div>
<div class="fr"><span class="n" style="width:160px">Folha</span><span class="v" style="color:#ffb4a8;flex:1">− US$ 0,9 mi</span></div>
<div class="fr"><span class="n" style="width:160px">Fábrica e operação</span><span class="v" style="color:#ffb4a8;flex:1">− US$ 1,2 mi</span></div>
<div class="tot"><span>Saldo por corrida</span><b>+ US$ 0,9 mi</b></div></div>
<div class="card2" style="left:916px;top:458px;width:320px;height:242px"><div class="lbl">TEMPORADAS ANTERIORES</div>{hist}</div>
<div class="note" style="left:44px;bottom:6px">EXEMPLO: EQUIPE FICTÍCIA · VALORES PROVISÓRIOS · O PRÊMIO DO FIM DA TEMPORADA ENTRA NA PROJEÇÃO PELA POSIÇÃO ATUAL</div></div>'''
    return V.page("V11 · Finanças", CSS, body)


def patrocinios():
    car = V.car_svg(C1, C2, 2, width=560, uid="p")
    zones = [("Asa traseira", "valor ×1,0", ("DHL", "US$ 1,1 mi", "até 2027"), True), ("Laterais", "valor ×0,9", ("Dell", "US$ 0,9 mi", "até 2026"), False),
             ("Bico", "valor ×0,7", None, False), ("Halo", "valor ×0,5", ("Puma", "US$ 0,4 mi", "até 2028"), False), ("Asa dianteira", "valor ×0,6", None, False)]
    zr = ""
    for i, (n, mult, sp, sel) in enumerate(zones):
        if sp:
            right = f'<div class="rt"><b>{sp[1]}</b><small>por corrida · {sp[2]}</small></div>'
            mid = f'<span class="brand">{sp[0]}</span>'
        else:
            right = '<div class="rt"><b style="color:#ffd24a">3 ofertas</b><small>zona livre</small></div>'
            mid = ""
        zr += f'<div class="zone{" sel" if sel else ""}"><span class="num">{i + 1}</span><div><b>{n}</b><small>{mult}</small></div><div style="margin-left:14px">{mid}</div>{right}</div>'
    offers = [("Shell", "Energia", "US$ 1,4 mi", "+ US$ 0,3 mi por pódio", "2 anos", True), ("Oracle", "Tecnologia", "US$ 1,2 mi", "+ US$ 0,2 mi por pódio", "3 anos", False),
              ("Heineken", "Bebidas", "US$ 1,0 mi", "sem bônus", "1 ano", False)]
    orow = ""
    for b, cat, v, bonus, yrs, hot in offers:
        orow += (f'<div class="offer"><span class="brand">{b}</span><div class="t"><b style="font-size:15px">{cat}</b><small>{yrs} · {bonus}</small></div>'
                 f'<div class="v"><b>{v}</b><small>por corrida</small></div><div class="btn2 ghost" style="height:40px;margin-left:6px;font-size:12px;padding:0 12px">PEDIR MAIS</div>'
                 f'<div class="btn2 red" style="height:40px;margin-left:0;font-size:13px;padding:0 16px">ACEITAR</div></div>')
    def pin(n, x, y, free=False):
        return f'<div class="pin{" free" if free else ""}" style="left:{x - 15}px;top:{y - 15}px">{n}</div>'
    pins = pin(1, 552, 128) + pin(2, 330, 168) + pin(3, 120, 186, True) + pin(4, 255, 138) + pin(5, 42, 198, True)
    body = f'''<div class="scene"><div class="wall" style="bottom:0"></div><div class="glow" style="background:radial-gradient(ellipse 40% 45% at 30% 55%,{C1}55,transparent 70%)"></div>
{topbar("AURORA RACING · TEMPORADA 2026", "PATROCÍNIOS", [("PATROCÍNIO POR CORRIDA", "US$ 2,4 mi"), ("CAIXA", "US$ 190 mi")])}{nav(5)}
<div class="card2" style="left:44px;top:150px;width:290px;height:96px"><div class="lbl" style="margin-bottom:6px">INFLUÊNCIA</div>
<div style="display:flex;align-items:center;gap:12px"><b style="font-size:34px;font-weight:900">3</b><div><div class="inf"><i class="f"></i><i class="f"></i><i class="f"></i><i></i><i></i></div>
<small style="font-size:12px;color:#a8b0bd;font-weight:700;display:block;margin-top:5px">marcas até o nível 3 · sobe com a fábrica</small></div></div></div>
<div class="card2" style="left:346px;top:150px;width:270px;height:96px"><div class="lbl" style="margin-bottom:6px">CONTRATOS</div>
<div style="font-size:15px;line-height:1.5;color:#c3c9d3">3 de 5 zonas ocupadas<br><b style="color:#fff">US$ 2,4 mi</b> por corrida · bônus: pódio</div></div>
<div style="position:absolute;left:44px;top:260px;width:572px;height:430px">{car.replace('<svg ', '<svg style="position:absolute;left:0;top:70px" ', 1)}{pins}</div>
<div style="position:absolute;left:640px;top:150px;width:596px"><div class="lbl">ZONAS DO CARRO</div>{zr}
<div class="lbl" style="margin-top:12px">OFERTAS · ASA TRASEIRA (AS OFERTAS MUDAM TODO MÊS)</div>{orow}</div>
<div class="note" style="left:44px;bottom:6px;width:560px">EXEMPLO: EQUIPE FICTÍCIA · MARCAS REAIS SÓ EM TEXTO (SEM LOGOS) · VALORES PROVISÓRIOS · A POSIÇÃO NO CARRO ENTRA NO ESTÚDIO DE DESIGN</div></div>'''
    return V.page("V11 · Patrocínios", CSS, body)


if __name__ == "__main__":
    for name, fn in [("v11-1-financas", financas), ("v11-2-patrocinios", patrocinios)]:
        (HERE / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
