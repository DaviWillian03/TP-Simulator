"""V31 · Finanças da campanha (decisões de 2026-11-04/10): patrocínio garantido × por meta, prêmio oficial por posição e
compromissos com projeção do caixa. Moldura v26 (barra do topo + barra de ícones). Uso: python design/mockups/build_v31.py"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402
import build_v26 as W  # noqa: E402

HERE = B.HERE
g = W.g
GOLD = "#F5C542"
GREEN = "#7fe0b1"
RED = "#ff8a80"

CSS = W.CSS + """
.card{position:absolute;border-radius:22px;background:#171a21;box-shadow:0 10px 30px rgba(0,0,0,.35);padding:16px 20px}
.tabs{display:inline-flex;border-radius:20px;background:rgba(255,255,255,.08);padding:3px;gap:2px}
.tabs b{padding:7px 18px;border-radius:17px;font-size:13px;letter-spacing:1px;color:#a8b0bd}.tabs b.on{background:#f3f4f6;color:#11141a}
.sp{display:flex;align-items:center;gap:12px;border-radius:16px;background:rgba(255,255,255,.05);padding:10px 14px;margin-top:8px}
.sp .z{width:42px;height:42px;border-radius:12px;display:grid;place-items:center;background:rgba(255,255,255,.08);flex:none}
.sp b{font-size:16px;font-weight:900}.sp small{display:block;font-size:12px;color:#a8b0bd;font-weight:800;margin-top:2px}
.tag{display:inline-flex;align-items:center;gap:5px;border-radius:10px;padding:3px 9px;font-size:12px;font-weight:900}
.nm2{font-weight:900;text-align:right;line-height:1}.nm2 small{display:block;font-size:11px;color:#8f98a7;margin-top:3px;font-weight:800}
.prow{display:flex;align-items:center;gap:10px;height:34px;border-radius:10px;background:rgba(255,255,255,.05);padding:0 12px;margin-top:4px;font-weight:900;font-size:14px}
.prow.now{background:rgba(245,197,66,.2);box-shadow:inset 4px 0 0 #F5C542}.prow .v{margin-left:auto}
.big2{font-size:34px;font-weight:900;line-height:1}
.cmt{display:flex;align-items:center;gap:12px;border-radius:14px;background:rgba(255,255,255,.05);padding:10px 14px;margin-top:7px}
.cmt .ico{width:38px;height:38px;border-radius:11px;display:grid;place-items:center;background:rgba(255,255,255,.08);flex:none}
.cmt b{font-size:15px;font-weight:900}.cmt small{display:block;font-size:12px;color:#a8b0bd;font-weight:800}
.dim{position:absolute;inset:0;background:rgba(5,7,10,.7)}
.modal{position:absolute;border-radius:24px;background:#171a21;padding:22px 24px;box-shadow:0 20px 60px rgba(0,0,0,.6)}
.opt{flex:1;border-radius:18px;background:rgba(255,255,255,.06);padding:14px 16px;position:relative}
.opt.on{background:#f3f4f6;color:#11141a}.opt.on small{color:#4b5260}
"""


def frame(title, tab, body, extra=""):
    tabs = "".join(f'<b class="{"on" if t == tab else ""}">{t}</b>' for t in ["CAIXA", "RECEITAS", "PRÊMIO", "COMPROMISSOS"])
    return V.page(f"V31 · {title}", CSS, f'<div class="scene"><div class="bgx"></div>{W.topbar("CAIXA", "money")}{W.rail("money")}'
                  f'<div style="position:absolute;left:100px;top:92px"><div class="tabs">{tabs}</div></div>{body}{extra}</div>')


def _receitas_body():
    rows = [("Asa dianteira", "hand", "Petrobras Lubrificantes", "garantido", 0.62, None, None),
            ("Asa traseira", "hand", "Aramco Energia", "meta", 0.38, 5, 14.0),
            ("Aerofólio / capô", "hand", "Rolex Tempo", "garantido", 0.55, None, None),
            ("Laterais", "hand", "Oracle Cloud", "meta", 0.30, 3, 18.0),
            ("Capacete / macacão", "hand", "Hilton Hotéis", "garantido", 0.40, None, None)]
    li = ""
    for z, ic, brand, mode, per, pos, bonus in rows:
        tag = (f'<span class="tag" style="background:rgba(127,224,177,.18);color:{GREEN}">{g("lock", 13, GREEN)}GARANTIDO</span>' if mode == "garantido"
               else f'<span class="tag" style="background:rgba(245,197,66,.2);color:{GOLD}">{g("trophy", 13, GOLD)}META: TOP {pos}</span>')
        extra = ("" if mode == "garantido" else f'<div class="nm2" style="width:150px;color:{GOLD}">+{bonus:.1f} mi<small>se terminar entre os {pos} primeiros</small></div>')
        li += (f'<div class="sp"><span class="z">{g(ic, 22, "#22C7E8")}</span><div style="flex:1"><b>{brand}</b><small>{z} · até 2027</small></div>{tag}'
               f'<div class="nm2" style="width:110px">{per:.2f} mi<small>por corrida</small></div>{extra}</div>')
    left = (f'<div class="card" style="left:100px;top:140px;width:760px;height:544px"><div class="cap">PATROCINADORES · O QUE É GARANTIDO E O QUE DEPENDE DA META</div>{li}'
            f'<div style="font-size:12px;color:#8f98a7;font-weight:800;margin-top:14px">{g("bell", 14)} Meta cumprida paga o bônus no fim do ano; se falhar, a equipe fica só com o garantido.</div></div>')
    right = (f'<div class="card" style="left:880px;top:140px;width:384px;height:544px"><div class="cap">RECEITA DO ANO</div>'
             f'<div style="display:flex;align-items:center;gap:16px;margin-top:14px">{W.ring(0.68, 130, GREEN, "68%", "garantido", 12)}'
             f'<div><div class="big2" style="color:{GREEN}">US$ 49,6 mi</div><div style="font-size:13px;color:#a8b0bd;font-weight:800;margin-top:4px">garantido até o fim do ano</div></div></div>'
             f'<div class="cmt" style="margin-top:20px"><span class="ico">{g("trophy", 20, GOLD)}</span><div><b>US$ 32,0 mi em metas</b><small>2 de 5 contratos dependem do campeonato</small></div></div>'
             f'<div class="cmt"><span class="ico">{g("up", 20, GREEN)}</span><div><b>Hoje: 3º (meta top 5 e top 3)</b><small>as duas metas estão no caminho</small></div></div>'
             f'<div class="cmt"><span class="ico">{g("timer", 20, "#a8b0bd")}</span><div><b>+0,40 mi por pódio</b><small>soma dos contratos, por piloto</small></div></div>'
             f'<span class="cta" style="position:absolute;left:20px;right:20px;bottom:20px;height:56px;font-size:18px">VER OFERTAS DE PATROCÍNIO {g("chev", 20, "#fff")}</span></div>')
    return left + right


def receitas():
    return frame("Receitas", "RECEITAS", _receitas_body())


def oferta():
    modal = (f'<div class="dim"></div><div class="modal" style="left:230px;top:120px;width:820px">'
             f'<div style="display:flex;align-items:center;gap:12px"><span class="chip" style="background:#22C7E8;color:#11141a">{g("hand", 16, "#11141a")}OFERTA · ASA TRASEIRA</span><span style="flex:1"></span><span class="chip">{g("cal", 16)}2 anos</span></div>'
             f'<div class="big" style="font-size:32px;margin-top:14px">ARAMCO ENERGIA QUER PATROCINAR</div>'
             f'<div style="font-size:15px;color:#a8b0bd;font-weight:800;margin-top:6px">Mesmo valor total no ano: você escolhe quanto risco quer correr.</div>'
             f'<div style="display:flex;gap:14px;margin-top:18px">'
             f'<div class="opt on"><div style="display:flex;align-items:center;gap:8px;font-weight:900;font-size:18px">{g("lock", 22, "#11141a")}GARANTIDO</div>'
             f'<div class="big2" style="margin-top:12px">0,62 mi</div><small style="display:block;font-size:13px;font-weight:800;margin-top:4px">por corrida, aconteça o que acontecer</small>'
             f'<span class="tag" style="background:#e3e6eb;margin-top:12px">TOTAL NO ANO: 13,6 mi</span></div>'
             f'<div class="opt"><div style="display:flex;align-items:center;gap:8px;font-weight:900;font-size:18px">{g("trophy", 22, GOLD)}POR META</div>'
             f'<div class="big2" style="margin-top:12px">0,38 mi <span style="font-size:18px;color:{GOLD}">+ 14,0 no fim</span></div><small style="display:block;font-size:13px;color:#a8b0bd;font-weight:800;margin-top:4px">se terminar entre os 5 primeiros dos construtores</small>'
             f'<span class="tag" style="background:rgba(245,197,66,.2);color:{GOLD};margin-top:12px">TOTAL: 8,4 + 14,0 = 22,4 mi</span></div></div>'
             f'<div style="display:flex;align-items:center;gap:10px;margin-top:16px;font-size:14px;font-weight:800;color:#a8b0bd">{g("up", 16, GREEN)}Hoje você está em 3º: a meta parece segura.<span style="flex:1"></span>'
             f'<span class="cta" style="height:54px;font-size:18px;min-width:230px">FECHAR CONTRATO</span></div></div>')
    return frame("Oferta", "RECEITAS", _receitas_body(), modal)


def premio():
    pool = [100, 92, 85, 78, 70, 62, 54, 46, 38, 30, 22, 14]
    rows = ""
    for i, v in enumerate(pool):
        now = i == 2
        rows += (f'<div class="prow{" now" if now else ""}"><span style="width:26px;color:#a8b0bd">{i + 1}º</span><span style="flex:1;height:8px;border-radius:4px;background:rgba(255,255,255,.08);overflow:hidden"><u style="display:block;width:{v}%;height:100%;background:{GOLD if now else "#4C8DFF"}"></u></span>'
                 f'<span class="v">US$ {v} mi</span>{f"<span class=tag style=background:#F5C542;color:#11141a>VOCÊ</span>" if now else ""}</div>')
    left = f'<div class="card" style="left:100px;top:140px;width:520px;height:544px;padding:14px 18px"><div class="cap" style="margin-bottom:6px">PRÊMIO OFICIAL · POSIÇÃO FINAL DOS CONSTRUTORES</div>{rows}</div>'
    right = (f'<div class="card" style="left:640px;top:140px;width:624px;height:544px"><div class="cap">PROJEÇÃO PARA O SEU CARRO</div>'
             f'<div style="display:flex;align-items:center;gap:20px;margin-top:14px"><div><div class="cap" style="font-size:11px">HOJE</div><div class="big2">3º</div></div>'
             f'<div style="width:2px;height:50px;background:rgba(255,255,255,.12)"></div><div><div class="cap" style="font-size:11px">PRÊMIO NESTA POSIÇÃO</div><div class="big2" style="color:{GOLD}">US$ 85 mi</div></div>'
             f'<div style="width:2px;height:50px;background:rgba(255,255,255,.12)"></div><div><div class="cap" style="font-size:11px">FALTAM</div><div class="big2">13 GPs</div></div></div>'
             f'<div class="cmt" style="margin-top:22px"><span class="ico">{g("up", 20, GREEN)}</span><div><b>Subir para 2º vale +US$ 7 mi</b><small>você está 38 pontos atrás da Ferrari</small></div></div>'
             f'<div class="cmt"><span class="ico">{g("lock", 20, RED)}</span><div><b>Cair para 4º custa −US$ 7 mi</b><small>a McLaren está 22 pontos atrás</small></div></div>'
             f'<div class="cmt"><span class="ico">{g("cal", 20, "#a8b0bd")}</span><div><b>Pago no fim da temporada</b><small>entra no caixa na virada do ano</small></div></div>'
             f'<div style="margin-top:22px" class="cap">CADA POSIÇÃO NA TABELA VALE, EM MÉDIA, US$ 7,3 MI</div></div>')
    return frame("Prêmio", "PRÊMIO", left + right)


def compromissos():
    items = [("person", "Folha de pagamento", "pilotos e técnicos · 13 corridas", "−38,4 mi", "#A66BFF"), ("hq", "Obras na fábrica", "túnel de vento nível 3 · pronto em 40 dias", "−12,0 mi", "#2FD38A"),
             ("car", "Peças encomendadas", "2 unidades de motor + 1 asa spec B", "−4,6 mi", "#FF8A1F"), ("money", "Empréstimo do banco", "8 parcelas restantes", "−9,6 mi", "#F5C542"),
             ("gear", "Operação e manutenção", "13 corridas", "−17,2 mi", "#a8b0bd")]
    li = "".join(f'<div class="cmt"><span class="ico">{g(i, 20, c)}</span><div style="flex:1"><b>{t}</b><small>{s}</small></div><b style="color:{RED}">{v}</b></div>' for i, t, s, v, c in items)
    left = (f'<div class="card" style="left:100px;top:140px;width:520px;height:544px"><div class="cap">COMPROMISSOS ATÉ O FIM DA TEMPORADA</div>{li}'
            f'<div style="display:flex;align-items:center;margin-top:18px;padding-top:14px;border-top:2px solid rgba(255,255,255,.1)"><b style="font-size:16px">TOTAL COMPROMETIDO</b><span style="flex:1"></span><b style="font-size:24px;color:{RED}">−81,8 mi</b></div></div>')
    pts = " ".join(f"{100 + i * 62},{int(300 - (v - 100) * 1.5)}" for i, v in enumerate([140, 128, 119, 112, 104, 99, 97, 96, 100, 108, 116, 124, 131, 137]))
    dash = " ".join(f"{100 + i * 62},{int(300 - (v - 100) * 1.5)}" for i, v in enumerate([108, 116, 124, 131, 137], start=9))
    right = (f'<div class="card" style="left:640px;top:140px;width:624px;height:544px"><div style="display:flex;gap:30px"><div><div class="cap" style="font-size:11px">CAIXA HOJE</div><div class="big2">US$ 140 mi</div></div>'
             f'<div><div class="cap" style="font-size:11px">COMPROMETIDO</div><div class="big2" style="color:{RED}">−81,8 mi</div></div><div><div class="cap" style="font-size:11px">CAIXA LIVRE</div><div class="big2" style="color:{GREEN}">US$ 58 mi</div></div></div>'
             f'<div class="cap" style="margin-top:20px">PROJEÇÃO DO CAIXA ATÉ A ÚLTIMA CORRIDA</div>'
             f'<svg width="584" height="250" viewBox="0 0 584 250" style="margin-top:8px"><line x1="0" y1="190" x2="584" y2="190" stroke="#ff8a80" stroke-width="2" stroke-dasharray="6 6"/><text x="6" y="184" fill="#ff8a80" font-size="12" font-weight="800">reserva mínima</text>'
             f'<polyline fill="none" stroke="#7fe0b1" stroke-width="4" points="{" ".join(f"{i * 44},{int(220 - (v - 90) * 2.2)}" for i, v in enumerate([140, 128, 119, 112, 104, 99, 97, 96, 100, 108]))}"/>'
             f'<polyline fill="none" stroke="#7fe0b1" stroke-width="4" stroke-dasharray="3 8" stroke-linecap="round" points="{" ".join(f"{(i + 9) * 44},{int(220 - (v - 90) * 2.2)}" for i, v in enumerate([108, 116, 124, 131, 137]))}"/>'
             f'<circle cx="396" cy="{int(220 - 18 * 2.2)}" r="6" fill="#F5C542"/></svg>'
             f'<div class="cmt"><span class="ico">{g("up", 20, GREEN)}</span><div><b>Fim do ano: US$ 137 mi (com o prêmio do 3º lugar)</b><small>nunca abaixo da reserva mínima</small></div></div></div>')
    return frame("Compromissos", "COMPROMISSOS", left + right)


if __name__ == "__main__":
    pages = {"v31-1-receitas": receitas, "v31-2-oferta": oferta, "v31-3-premio": premio, "v31-4-compromissos": compromissos}
    for name, fn in pages.items():
        (HERE / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
