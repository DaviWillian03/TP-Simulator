"""Campanha — entrada e criação da equipe (direção Garagem), mockups antes do Godot.
Uso: python design/mockups/build_v5.py   (gera v5-*.html nesta pasta)
Equipe criada de exemplo ("Aurora Racing") é fictícia; valores de origem são PROVISÓRIOS.
"""
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402

HERE = B.HERE
ico = V.ico
EMB = V.EMB
FEED = json.loads((B.ROOT / "game/data/drivers_feeder_2026.json").read_text(encoding="utf-8"))["drivers"]
C1, C2 = "#0E7C66", "#F2A900"  # cores de exemplo da equipe criada

CSS = V.G_CSS + """
.hdr3{position:absolute;left:44px;top:24px;right:44px;display:flex;align-items:center;gap:16px}
.hdr3 b{display:block;font-size:13px;letter-spacing:3px;color:#8f98a7}.hdr3 h1{font-size:30px;font-weight:900;line-height:1}
.wiz{position:absolute;left:44px;right:44px;top:98px;display:flex;align-items:center}
.ws{display:flex;align-items:center;gap:10px;font-size:15px;font-weight:700;color:#8f98a7;white-space:nowrap}
.ws i{font-style:normal;width:32px;height:32px;border-radius:50%;display:grid;place-items:center;background:rgba(255,255,255,.07);font-size:13px;font-weight:900}
.ws.done i{background:#2a6b3f;color:#fff}.ws.now{color:#fff}.ws.now i{background:#E10600;color:#fff;box-shadow:0 0 0 5px rgba(225,6,0,.25)}
.wl{flex:1;height:3px;margin:0 12px;background:rgba(255,255,255,.08)}.wl.done{background:#2a6b3f}
.foot{position:absolute;left:44px;right:44px;bottom:26px;display:flex;align-items:center;gap:14px}
.ghost{height:56px;padding:0 24px;border-radius:14px;background:rgba(255,255,255,.07);display:flex;align-items:center;gap:10px;font-size:17px;font-weight:700}
.hint{font-size:14px;color:#8f98a7}
/* entrada */
.choice{position:absolute;top:120px;bottom:44px;width:578px;border-radius:24px;overflow:hidden;background:rgba(255,255,255,.05)}
.choice.on{background:#f3f4f6;color:#11141a}.choice .tx{position:absolute;left:34px;top:30px;right:34px}
.choice .k{font-size:13px;letter-spacing:3px;color:#8f98a7;font-weight:700}.choice.on .k{color:#4b5260}
.choice h2{font-size:44px;font-weight:900;line-height:1;margin:8px 0}.choice p{font-size:16px;color:#a8b0bd;line-height:1.5}.choice.on p{color:#4b5260}
.choice .car{position:absolute;left:30px;bottom:110px}
.choice .go{position:absolute;left:34px;bottom:30px}
.pills{display:flex;gap:8px;margin-top:14px;flex-wrap:wrap}.pills span{border-radius:16px;padding:6px 12px;font-size:13px;background:rgba(255,255,255,.08)}
.choice.on .pills span{background:#e3e6eb}
/* origem */
.orig{position:absolute;top:156px;bottom:104px;width:282px;border-radius:20px;background:rgba(255,255,255,.06);padding:20px 20px}
.orig.on{background:#f3f4f6;color:#11141a}.orig.on .lab,.orig.on small{color:#4b5260}
.orig h3{font-size:24px;font-weight:900;line-height:1.05;margin:12px 0 6px}.orig p{font-size:14px;color:#a8b0bd;line-height:1.45;min-height:62px}.orig.on p{color:#4b5260}
.og{width:52px;height:52px;border-radius:14px;display:grid;place-items:center;background:rgba(255,255,255,.08)}.orig.on .og{background:#11141a}
.st5{margin-top:12px;display:flex;flex-direction:column;gap:9px}.st5 div{display:flex;align-items:center;gap:10px;font-size:13px}
.st5 .lab{width:72px;color:#a8b0bd}.dots{display:flex;gap:4px}.dots i{width:22px;height:8px;border-radius:4px;background:rgba(255,255,255,.12)}.dots i.f{background:#5c93ea}
.orig.on .dots i{background:#d6d9df}.orig.on .dots i.f{background:#1868DB}
.tags{position:absolute;left:20px;right:20px;bottom:18px;display:flex;gap:6px;flex-wrap:wrap}.tags span{font-size:12px;letter-spacing:1.5px;font-weight:700;border-radius:10px;padding:4px 8px;background:rgba(255,255,255,.08)}
.orig.on .tags span{background:#e3e6eb}.tags .hard{color:#ffb4a8}.orig.on .tags .hard{color:#b30500}
/* identidade */
.field{border-radius:14px;background:rgba(255,255,255,.07);height:56px;display:flex;align-items:center;padding:0 18px;font-size:20px;font-weight:700;gap:12px}
.field small{margin-left:auto;font-size:13px;color:#8f98a7;font-weight:600}
.sw{display:flex;gap:10px;flex-wrap:wrap}.sw i{width:44px;height:44px;border-radius:12px;display:block}.sw i.on{box-shadow:0 0 0 3px #0b0c0f,0 0 0 6px #f3f4f6}
.shapes{display:flex;gap:10px}.shapes span{width:60px;height:60px;border-radius:14px;background:rgba(255,255,255,.07);display:grid;place-items:center}.shapes span.on{background:#f3f4f6}
/* pilotos */
.pool{position:absolute;left:44px;top:156px;width:740px;bottom:104px;border-radius:20px;background:rgba(255,255,255,.04);overflow:hidden}
.prow{display:flex;align-items:center;height:44px;padding:0 16px;border-bottom:1px solid rgba(255,255,255,.07);font-size:16px}
.prow .cat{width:40px;font-weight:900;font-size:13px;border-radius:8px;padding:3px 0;text-align:center;margin-right:14px}
.prow .nm{flex:1;font-weight:900}.prow .tm{width:190px;color:#a8b0bd;font-size:14px}.prow .na{width:130px;color:#a8b0bd;font-size:14px}
.prow .rt{width:60px;text-align:right;font-weight:900;font-size:18px}.prow.sel{background:rgba(14,124,102,.28)}
.slots{position:absolute;right:40px;top:156px;width:420px;display:flex;flex-direction:column;gap:14px}
.slot{border-radius:20px;background:rgba(255,255,255,.06);padding:18px 20px}.slot.empty{background:none;border:2px dashed rgba(255,255,255,.18)}
.slot b{font-size:22px;font-weight:900}.slot small{display:block;font-size:13px;color:#a8b0bd;margin-top:4px}
/* motor/objetivos */
.eng{display:grid;grid-template-columns:repeat(3,1fr);gap:10px}.eng span{height:64px;border-radius:14px;background:rgba(255,255,255,.07);display:flex;flex-direction:column;justify-content:center;padding:0 16px;font-size:17px;font-weight:900}
.eng span small{font-size:12px;font-weight:600;color:#a8b0bd}.eng span.on{background:#f3f4f6;color:#11141a}.eng span.on small{color:#4b5260}
.obj{display:grid;grid-template-columns:repeat(2,1fr);gap:10px}.obj span{height:58px;border-radius:14px;background:rgba(255,255,255,.07);display:flex;align-items:center;padding:0 16px;font-size:16px;font-weight:700}
.obj span.on{background:#f3f4f6;color:#11141a}
.sum{position:absolute;right:40px;top:156px;width:400px;bottom:104px;border-radius:20px;background:rgba(255,255,255,.05);padding:22px 24px;overflow:hidden}
.sum .r{display:flex;justify-content:space-between;font-size:15px;padding:9px 0;border-bottom:1px solid rgba(255,255,255,.07)}.sum .r span{color:#a8b0bd}.sum .r b{font-weight:900}
.note{position:absolute;font-size:11px;letter-spacing:1.5px;color:#5d6574}
"""

STEPS = ["Origem", "Identidade", "Motor e objetivos", "Pilotos"]


def wizard(now):
    out = ""
    for i, s in enumerate(STEPS):
        cls = "done" if i < now else ("now" if i == now else "")
        if i:
            out += f'<div class="wl{" done" if i <= now else ""}"></div>'
        out += f'<div class="ws {cls}"><i>{"✓" if i < now else i + 1}</i>{s}</div>'
    return f'<div class="wiz">{out}</div>'


def head(title, sub, step=None):
    return (f'<div class="hdr3"><span class="round">{ico("back", 26, "#eef0f3", 2.6)}</span><div><b>{sub}</b><h1>{title}</h1></div></div>'
            + (wizard(step) if step is not None else ""))


def foot(cta, back=True, hint=""):
    return (f'<div class="foot">{f"<span class=ghost>{ico("back", 20)} Voltar</span>" if back else ""}<span class="hint">{hint}</span>'
            f'<div class="cta" style="margin-left:auto;width:320px">{cta} {ico("chev", 24, "#fff", 3)}</div></div>')


def page(title, body, glow=C1):
    g = f'<div class="glow" style="background:radial-gradient(ellipse 45% 50% at 60% 55%,{glow}44,transparent 70%)"></div>'
    return V.page(title, CSS, f'<div class="scene"><div class="wall" style="bottom:0"></div>{g}{body}</div>')


def entrada():
    real = V.car_svg(V.TEAM["color"], V.TEAM["color2"], 23, width=520, uid="r")
    mine = V.car_svg(C1, C2, 7, width=520, uid="m")
    body = head("CAMPANHA", "TEMPORADA 2026 · SEM FIM · OBJETIVOS DA DIRETORIA A CADA ANO")
    body += f'''<div class="choice" style="left:44px"><div class="tx"><div class="k">EQUIPE REAL</div><h2>ASSUMIR UMA<br>EQUIPE DO GRID</h2>
<p>Dirigentes, engenheiros, pilotos e nível reais da temporada 2026. Escolha entre as 11 equipes.</p>
<div class="pills"><span>11 equipes</span><span>Pilotos de F1</span><span>Metas da diretoria</span></div></div>
<div class="car">{real}</div><div class="go ghost">ESCOLHER EQUIPE {ico("chev", 20)}</div></div>
<div class="choice on" style="right:44px"><div class="tx"><div class="k">EQUIPE CRIADA · 12ª DO GRID</div><h2>CRIAR SUA<br>PRÓPRIA EQUIPE</h2>
<p>Funde a equipe com uma das 4 origens, escolha motor, cores e pilotos da F2 e da F3, e desafie o grid.</p>
<div class="pills"><span>4 origens</span><span>Motor próprio possível</span><span>Pilotos da F2/F3</span></div></div>
<div class="car">{mine}</div><div class="go cta" style="width:260px;height:56px">CRIAR EQUIPE {ico("chev", 22, "#fff", 3)}</div></div>
<div class="note" style="left:44px;bottom:16px">EQUIPE CRIADA DE EXEMPLO: FICTÍCIA · CARRO: ILUSTRAÇÃO ORIGINAL COM AS CORES ESCOLHIDAS</div>'''
    return page("V5 · Campanha · entrada", body)


ORIGINS = [
    ("Equipe de garagem", "Pouco dinheiro, fábrica mínima e motor comprado. Diretoria paciente.", "flag", (1, 1, 0, 5), ["DIFÍCIL", "POUCO COMPLEXA"]),
    ("Projeto de investidor", "Muito dinheiro e fábrica média, mas metas agressivas: pode ser demitido.", "bolt", (4, 3, 0, 1), ["MÉDIA", "PRESSÃO ALTA"]),
    ("Montadora estreante", "Dinheiro alto e motor próprio desde o início. A marca exige resultado rápido.", "globe", (4, 3, 5, 2), ["MÉDIA", "MAIS COMPLEXA"]),
    ("Resgate de equipe falida", "Estrutura razoável, mas dívidas e pessoal desmotivado. Recupere antes de vencer.", "swap", (2, 3, 0, 3), ["DIFÍCIL", "COMPLEXA"]),
]


def origem():
    cards = ""
    for i, (n, d, ic, vals, tags) in enumerate(ORIGINS):
        on = " on" if i == 2 else ""
        rows = ""
        for lab, v in zip(["Dinheiro", "Fábrica", "Motor", "Paciência"], vals):
            dots = "".join(f'<i class="{"f" if k < v else ""}"></i>' for k in range(5))
            rows += f'<div><span class="lab">{lab}</span><span class="dots">{dots}</span></div>'
        tg = "".join(f'<span class="{"hard" if t == "DIFÍCIL" else ""}">{t}</span>' for t in tags)
        cards += f'''<div class="orig{on}" style="left:{44 + i * 302}px"><span class="og">{ico(ic, 28, "#fff" if on else "#dfe3ea")}</span><h3>{n.upper()}</h3><p>{d}</p>
<div class="st5">{rows}</div><div class="tags">{tg}</div></div>'''
    body = head("CRIAR EQUIPE", "CAMPANHA · PASSO 1 DE 4", 0) + cards
    body += foot("AVANÇAR", hint="A origem define o começo e o tipo de desafio. Dinheiro e fábrica: valores PROVISÓRIOS.")
    return page("V5 · Criar equipe · origem", body)


def identidade():
    swatch = lambda cols, sel: "".join(f'<i style="background:{c}" class="{"on" if c == sel else ""}"></i>' for c in cols)
    prim = ["#0E7C66", "#1868DB", "#E8002D", "#FF8000", "#6A2C91", "#111111", "#F2F2F2"]
    sec = ["#F2A900", "#FFFFFF", "#111111", "#27F4D2", "#E10600", "#9AA3B2", "#FF87BC"]
    emb = (f'<svg width="120" height="120" viewBox="0 0 24 24"><path d="M7 2h10l5 10-5 10H7L2 12z" fill="{C1}" stroke="{C2}" stroke-width="1.4"/>'
           f'<text x="12" y="15.6" text-anchor="middle" font-family="Titillium" font-weight="900" font-size="7" fill="{C2}">AUR</text></svg>')
    shapes = "".join(f'<span class="{"on" if k == 1 else ""}"><svg width="30" height="30" viewBox="0 0 24 24">{s}</svg></span>' for k, s in enumerate([
        '<rect x="3" y="3" width="18" height="18" rx="3" fill="#8f98a7"/>', f'<path d="M7 2h10l5 10-5 10H7L2 12z" fill="{C1}"/>',
        '<circle cx="12" cy="12" r="10" fill="#8f98a7"/>', '<path d="M3 2h18v9c0 6-4 9-9 11C7 20 3 17 3 11z" fill="#8f98a7"/>',
        '<path d="M12 1l11 11-11 11L1 12z" fill="#8f98a7"/>']))
    car = V.car_svg(C1, C2, 7, width=640, uid="i")
    body = head("CRIAR EQUIPE", "CAMPANHA · PASSO 2 DE 4", 1)
    body += f'''<div style="position:absolute;left:44px;top:156px;width:520px;display:flex;flex-direction:column;gap:12px">
<div class="lbl" style="margin:0">NOME DA EQUIPE</div><div class="field">Aurora Racing<small>14 / 24</small></div>
<div style="display:flex;gap:12px"><div style="flex:1"><div class="lbl">SIGLA</div><div class="field">AUR</div></div><div style="flex:2"><div class="lbl">SEDE</div><div class="field">{ico("flag", 20)} Brasil<small>trocar</small></div></div></div>
<div class="lbl" style="margin:4px 0 0">COR PRINCIPAL</div><div class="sw">{swatch(prim, C1)}</div>
<div class="lbl" style="margin:4px 0 0">COR DE DESTAQUE</div><div class="sw">{swatch(sec, C2)}</div>
<div class="lbl" style="margin:4px 0 0">FORMA DO EMBLEMA</div><div class="shapes">{shapes}</div></div>
<div style="position:absolute;left:600px;top:150px;width:640px;height:400px;border-radius:24px;background:rgba(255,255,255,.04);overflow:hidden">
<div style="position:absolute;left:26px;top:22px;display:flex;align-items:center;gap:18px">{emb}<div><div class="lbl" style="margin:0">PRÉVIA</div><div style="font-size:34px;font-weight:900">AURORA RACING</div><div style="color:#a8b0bd">Sede: Brasil · 12ª equipe do grid</div></div></div>
<div style="position:absolute;left:0;bottom:30px">{car}</div></div>'''
    body += foot("AVANÇAR", hint="Pintura completa, patrocínios no carro e logo livre chegam com o estúdio de design (P9).")
    return page("V5 · Criar equipe · identidade", body)


def motor():
    engs = [("Mercedes", "cliente"), ("Ferrari", "cliente"), ("Honda", "cliente"), ("Red Bull Ford", "cliente"), ("Audi", "cliente"), ("Motor próprio", "P&D de motor completa")]
    eng = "".join(f'<span class="{"on" if n == "Motor próprio" else ""}">{n}<small>{s}</small></span>' for n, s in engs)
    objs = ["Campeão em 5 temporadas", "Vencer uma corrida", "Chegar ao top 5", "Só sobreviver"]
    obj = "".join(f'<span class="{"on" if k == 1 else ""}">{o}</span>' for k, o in enumerate(objs))
    seg = lambda opts, sel: '<div class="seg">' + "".join(f'<span class="{"on" if o == sel else ""}">{o}</span>' for o in opts) + "</div>"
    body = head("CRIAR EQUIPE", "CAMPANHA · PASSO 3 DE 4", 2)
    body += f'''<div style="position:absolute;left:44px;top:150px;width:740px;display:flex;flex-direction:column;gap:8px">
<div class="lbl">MOTOR</div><div class="eng">{eng}</div>
<div class="lbl" style="margin-top:10px">OBJETIVO DE LONGO PRAZO</div><div class="obj">{obj}</div>
<div style="display:flex;gap:20px;margin-top:10px"><div style="flex:1"><div class="lbl">NÍVEL DE DETALHE</div>{seg(["Essencial", "Avançado"], "Essencial")}</div>
<div style="flex:1"><div class="lbl">DIFICULDADE DA IA</div>{seg(["Fácil", "Normal", "Difícil"], "Normal")}</div></div></div>
<div class="sum"><div style="font-size:24px;font-weight:900;margin-bottom:8px">RESUMO</div>
<div class="r"><span>Origem</span><b>Montadora estreante</b></div><div class="r"><span>Equipe</span><b>Aurora Racing</b></div>
<div class="r"><span>Motor</span><b>Próprio</b></div><div class="r"><span>Orçamento inicial</span><b>US$ 190 mi</b></div>
<div class="r"><span>Fábrica</span><b>Nível 3</b></div><div class="r"><span>Objetivo</span><b>Vencer uma corrida</b></div>
<div class="r"><span>Detalhe · IA</span><b>Essencial · Normal</b></div>
<p style="margin-top:14px;font-size:14px;color:#a8b0bd;line-height:1.5">Essencial: o diretor técnico decide os detalhes da P&D. Dá para trocar a qualquer momento.</p></div>'''
    body += foot("AVANÇAR", hint="Montadora estreante já começa com motor próprio; as outras origens podem escolher.")
    return page("V5 · Criar equipe · motor e objetivos", body)


def pilotos():
    rows = ""
    pool = sorted(FEED, key=lambda d: -d["rating"])[:10]
    for d in pool:
        sel = " sel" if d["name"] in ("Rafael Câmara",) else ""
        col = "#E10600" if d["category"] == "F2" else "#1868DB"
        rows += (f'<div class="prow{sel}"><span class="cat" style="background:{col}">{d["category"]}</span><span class="nm">{d["name"]}</span>'
                 f'<span class="tm">{d["series_team"]}</span><span class="na">{d["nationality"]}</span><span class="rt">{d["rating"]}</span></div>')
    seg = '<div class="seg" style="width:300px"><span class="on">Todos</span><span>F2</span><span>F3</span></div>'
    body = head("CRIAR EQUIPE", "CAMPANHA · PASSO 4 DE 4", 3)
    body += f'''<div class="pool"><div style="display:flex;align-items:center;gap:14px;padding:14px 16px;border-bottom:1px solid rgba(255,255,255,.08)">{seg}
<span class="hint" style="margin-left:auto">48 pilotos reais · F2 e F3 2026</span></div>{rows}</div>
<div class="slots"><div class="lbl" style="margin:0">SEUS PILOTOS</div>
<div class="slot"><div style="display:flex;align-items:center;gap:10px"><span style="font-size:13px;font-weight:900;background:#E10600;border-radius:8px;padding:3px 8px">F2</span><b>Rafael Câmara</b><span style="margin-left:auto;font-size:24px;font-weight:900">79</span></div><small>Brasil · vinha da Invicta Racing · toque para trocar</small></div>
<div class="slot empty"><b style="color:#a8b0bd">Escolha o 2º piloto</b><small>Toque num nome da lista</small></div>
<p class="hint" style="line-height:1.5">Salário e duração do contrato entram na camada de contratos; agora a escolha é direta.</p></div>'''
    body += foot("FUNDAR EQUIPE", hint="Notas dos pilotos: PROVISÓRIAS até a pesquisa de atributos.")
    return page("V5 · Criar equipe · pilotos", body)


if __name__ == "__main__":
    for name, fn in [("v5-1-campanha-entrada", entrada), ("v5-2-criar-origem", origem), ("v5-3-criar-identidade", identidade),
                     ("v5-4-criar-motor-objetivos", motor), ("v5-5-criar-pilotos", pilotos)]:
        (HERE / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
