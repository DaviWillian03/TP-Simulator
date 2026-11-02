"""Campanha — Pessoal: pilotos, diretor técnico e engenheiros, mercado e negociação (direção Garagem).
Uso: python design/mockups/build_v10.py   (gera v10-*.html nesta pasta)
Equipe criada de exemplo (Aurora Racing, fictícia). Nomes de técnicos são FICTÍCIOS; pilotos de exemplo reais
só para ilustrar. Salários, notas e prazos são EXEMPLOS PROVISÓRIOS.
Regras (decisões do usuário): contrato simples (salário + duração → aceita / recusa / contraproposta); negocia a
qualquer hora, mas a troca só vale na virada de temporada (piloto de outra equipe só depois que o contrato vence
ou pagando multa); a IA também renova, dispensa e contrata na virada, e os que sobram viram agentes livres.
"""
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
.sec{position:absolute}.sec .lbl{margin-bottom:10px}
.pc{display:flex;align-items:center;gap:14px;height:88px;border-radius:20px;background:rgba(255,255,255,.07);padding:0 18px;margin-bottom:8px;position:relative}
.av{width:56px;height:56px;border-radius:50%;display:grid;place-items:center;font-weight:900;font-size:20px;flex:none;color:#fff}
.pc h3{font-size:21px;font-weight:900;line-height:1.05}.pc small{font-size:13px;color:#a8b0bd;font-weight:700}
.pc .rt{margin-left:auto;text-align:right}.pc .rt b{display:block;font-size:34px;font-weight:900;line-height:1}.pc .rt small{letter-spacing:2px;font-size:11px}
.ctr{display:flex;gap:8px;margin-top:6px}.tag{display:inline-block;background:rgba(255,255,255,.1);border-radius:10px;padding:3px 9px;font-size:12px;font-weight:700;color:#c3c9d3}
.tag.warn{background:rgba(255,210,74,.2);color:#ffd24a}.tag.ok{background:rgba(60,157,93,.22);color:#7fe0b1}
.sr{display:flex;align-items:center;gap:12px;height:52px;border-bottom:1px solid rgba(255,255,255,.07)}
.sr .role{width:108px;font-size:12px;letter-spacing:1.5px;color:#8f98a7;font-weight:700;line-height:1.25}.sr .wh{flex:1;min-width:150px;white-space:nowrap}.sr b{display:block;font-size:16px;font-weight:900;line-height:1.1}.sr small{font-size:12px;color:#a8b0bd;font-weight:700}
.sk{width:60px;height:8px;border-radius:4px;background:rgba(255,255,255,.12);position:relative}.sk i{position:absolute;inset:0 auto 0 0;border-radius:4px}
.sr .sv{width:28px;text-align:right;font-weight:900;font-size:18px}
.mini{height:38px;padding:0 14px;border-radius:12px;background:rgba(255,255,255,.1);display:flex;align-items:center;font-size:13px;font-weight:900;letter-spacing:.5px}
.mk{position:absolute;right:44px;top:150px;width:520px;bottom:24px;border-radius:22px;background:rgba(255,255,255,.05);padding:16px 18px;overflow:hidden}
.chips2{display:flex;gap:6px;margin:10px 0}.chips2 span{height:32px;padding:0 13px;border-radius:16px;background:rgba(255,255,255,.08);display:grid;place-items:center;font-size:13px;font-weight:700;color:#c3c9d3}.chips2 span.on{background:#f3f4f6;color:#11141a}
.mr{display:flex;align-items:center;gap:10px;height:50px;border-bottom:1px solid rgba(255,255,255,.07);font-size:14px}
.mr .av{width:34px;height:34px;font-size:12px}.mr .n{flex:1;font-weight:900;font-size:15px}.mr .n small{display:block;font-size:11px;color:#a8b0bd;font-weight:700}.mr .r{width:38px;text-align:right;font-weight:900;font-size:17px}.mr .c{width:104px;color:#a8b0bd;font-size:12px;font-weight:700;text-align:right;line-height:1.2}
.mr.sel{background:#f3f4f6;color:#11141a;border-radius:12px;padding:0 10px;margin:2px -10px;border:none}.mr.sel .n small,.mr.sel .c{color:#4b5260}
.sheet{position:absolute;left:0;right:0;top:0;bottom:0;background:rgba(5,6,8,.72);display:flex;align-items:center;justify-content:center}
.sh2{width:780px;border-radius:24px;background:#17191e;padding:24px 28px;box-shadow:0 20px 60px rgba(0,0,0,.6);position:relative}
.sh2 h2{font-size:28px;font-weight:900;line-height:1}.sh2 .cols{display:flex;gap:22px;margin-top:16px}.sh2 .cols>div{flex:1}
.sl{height:52px;border-radius:14px;background:rgba(255,255,255,.07);display:flex;align-items:center;padding:0 16px;gap:12px;margin-top:8px}
.sl b{font-size:22px;font-weight:900;min-width:96px}.sl .rl{flex:1;height:8px;border-radius:4px;background:rgba(255,255,255,.14);position:relative}.sl .rl i{position:absolute;inset:0 auto 0 0;border-radius:4px;background:#f3f4f6}.sl .rl s{position:absolute;top:-8px;width:24px;height:24px;border-radius:50%;background:#fff;margin-left:-12px}
.sl .pm{width:36px;height:36px;border-radius:50%;background:rgba(255,255,255,.12);display:grid;place-items:center;font-size:20px;font-weight:900}
.int{height:14px;border-radius:7px;background:rgba(255,255,255,.12);position:relative;margin:8px 0 4px}.int i{position:absolute;inset:0 auto 0 0;border-radius:7px}
.reply{border-radius:16px;background:rgba(255,210,74,.14);border-left:6px solid #ffd24a;padding:12px 16px;font-size:14px;line-height:1.45;margin-top:12px}
.reply b{font-size:17px;font-weight:900;display:block;margin-bottom:2px}
"""


def avatar(initials, color, size=60):
    return f'<span class="av" style="background:{color};width:{size}px;height:{size}px">{initials}</span>'


def driver_card(name, num, rating, until, salary, color, tags, ini):
    t = "".join(f'<span class="tag {c}">{x}</span>' for x, c in tags)
    return (f'<div class="pc">{avatar(ini, color, 56)}<div><h3>{name} <span style="color:#8f98a7;font-size:15px">#{num}</span></h3>'
            f'<small>Contrato até {until} · US$ {salary} mi/ano</small><div class="ctr">{t}</div></div>'
            f'<div class="rt"><b>{rating}</b><small>NOTA</small></div></div>')


def staff_row(role, who, sub, skill, color, effect, action="TROCAR", locked=False):
    if locked:
        return (f'<div class="sr" style="opacity:.45;height:36px;border:none"><div class="role" style="width:auto">{role.replace("<br>", " ")}</div><div class="wh"><small>Motor do fornecedor: sem engenheiro de motor</small></div>'
                f'<span class="mini" style="opacity:.0">—</span></div>')
    return (f'<div class="sr"><div class="role">{role}</div><div class="wh"><b>{who}</b><small>{sub}</small></div>'
            f'<div style="width:118px;font-size:11px;color:#c3c9d3;line-height:1.25">{effect}</div>'
            f'<div class="sk"><i style="width:{skill}%;background:{color}"></i></div><span class="sv">{skill}</span><span class="mini" style="padding:0 10px">{action}</span></div>')


def topbar(sub, title):
    return (f'<div class="top"><span class="round">{ico("back", 26, "#eef0f3", 2.6)}</span>'
            f'<svg width="46" height="46" viewBox="0 0 24 24"><path d="M7 2h10l5 10-5 10H7L2 12z" fill="{C1}" stroke="{C2}" stroke-width="1.4"/></svg>'
            f'<div class="tm"><b>{sub}</b><h1>{title}</h1></div>'
            '<div style="margin-left:auto;display:flex;gap:10px"><div class="chipm"><div><small>CAIXA</small>US$ 176 mi</div></div>'
            '<div class="chipm"><div><small>FOLHA POR CORRIDA</small>US$ 1,4 mi</div></div></div></div>')


def nav():
    items = ["Início", "Campeonatos", "Pessoal", "Carro", "Fábrica", "Finanças"]
    return '<div class="nav">' + "".join(f'<span class="{"on" if k == 2 else ""}">{i}</span>' for k, i in enumerate(items)) + "</div>"


def market_rows(sel):
    rows = [("Rafael Câmara", "RC", "F2 · Brasil", "#6a7487", "78", "Contrato até 2026", "pede US$ 3 mi"),
            ("Tom Herta", "TH", "Agente livre · EUA", "#3c9d5d", "74", "Livre", "pede US$ 2 mi"),
            ("Alex Albon", "AA", "Williams · Tailândia", "#1868DB", "86", "Contrato até 2027", "multa US$ 31 mi"),
            ("Pierre Gasly", "PG", "Alpine · França", "#0090ff", "84", "Contrato até 2026", "pede US$ 12 mi"),
            ("Jack Doohan", "JD", "F2 · Austrália", "#6a7487", "76", "Contrato até 2026", "pede US$ 2,5 mi"),
            ("Nyck de Vries", "NV", "Agente livre · Holanda", "#3c9d5d", "77", "Livre", "pede US$ 4 mi"),
            ("Théo Pourchaire", "TP", "F2 · França", "#6a7487", "75", "Contrato até 2026", "pede US$ 2 mi")]
    out = ""
    for i, (n, ini, sub, col, r, c1, c2) in enumerate(rows):
        out += (f'<div class="mr{" sel" if i == sel else ""}">{avatar(ini, col, 34)}<div class="n">{n}<small>{sub}</small></div>'
                f'<div class="c">{c1}<br>{c2}</div><div class="r">{r}</div></div>')
    return out


def pessoal(sheet=False):
    left = (f'<div class="sec" style="left:44px;top:150px;width:600px"><div class="lbl">SEUS PILOTOS · TEMPORADA 2026</div>'
            f'{driver_card("Rafael Câmara", 2, 78, 2026, "2,0", C1, [("vence este ano", "warn"), ("1º piloto", "")], "RC")}'
            f'{driver_card("Tom Herta", 11, 74, 2027, "1,5", C1, [("renovado", "ok")], "TH")}'
            f'<div class="lbl" style="margin-top:10px">EQUIPE TÉCNICA</div>'
            + staff_row("DIRETOR<br>TÉCNICO", "Marcos Veloso", "até 2027 · US$ 0,9 mi", 72, "#ffd24a", "−4% nos dias de todos os projetos")
            + staff_row("ENGENHEIRO<br>AERODINÂMICA", "Helena Voss", "até 2026 · US$ 0,5 mi", 80, "#ffd24a", "+4 pts de acerto em aero")
            + staff_row("ENGENHEIRO<br>CHASSI", "Dario Quintal", "até 2028 · US$ 0,4 mi", 61, "#5c93ea", "+1 pt de acerto em chassi")
            + staff_row("ENGENHEIRO<br>DURABILIDADE", "Ingrid Solheim", "até 2027 · US$ 0,4 mi", 68, "#3c9d5d", "+2 pts de acerto em durab.")
            + staff_row("ENGENHEIRO<br>MOTOR", "", "", 0, "", "", locked=True) + '</div>')
    market = (f'<div class="mk"><div class="lbl" style="margin:0">MERCADO · NEGOCIA A QUALQUER HORA, TROCA NA VIRADA</div>'
              f'<div class="chips2"><span class="on">Pilotos</span><span>Técnicos</span><span style="margin-left:auto">Todos</span><span>Livres</span><span>F2/F3</span><span>Outras equipes</span></div>'
              f'{market_rows(0)}</div>')
    sheet_html = ""
    if sheet:
        sheet_html = f'''<div class="sheet"><div class="sh2"><div class="lbl" style="margin-bottom:6px">NEGOCIAÇÃO · PILOTO</div>
<div style="display:flex;gap:16px;align-items:center">{avatar("RC", "#6a7487", 64)}<div><h2>RAFAEL CÂMARA</h2><small style="font-size:14px;color:#a8b0bd;font-weight:700">F2 · Brasil · nota 78 · contrato até 2026</small></div>
<div style="margin-left:auto;text-align:right"><small style="font-size:11px;letter-spacing:2px;color:#8f98a7;font-weight:700">PEDE</small><div style="font-size:28px;font-weight:900">US$ 3,0 mi</div></div></div>
<div class="cols"><div><div class="lbl" style="margin:0">SUA PROPOSTA</div>
<div class="sl"><span class="pm">−</span><b>US$ 2,6 mi</b><div class="rl"><i style="width:55%"></i><s style="left:55%"></s></div><span class="pm">+</span></div>
<div class="sl"><span class="pm">−</span><b>3 anos</b><div class="rl"><i style="width:50%"></i><s style="left:50%"></s></div><span class="pm">+</span></div>
<div class="lbl" style="margin:14px 0 0">INTERESSE DO PILOTO</div><div class="int"><i style="width:68%;background:linear-gradient(90deg,#ffd24a,#3c9d5d)"></i></div>
<div style="font-size:12px;color:#a8b0bd;display:flex;justify-content:space-between"><span>recusa</span><span>contraproposta</span><span>aceita</span></div></div>
<div><div class="lbl" style="margin:0">EFEITO NA EQUIPE</div>
<div class="sr" style="height:42px"><span style="flex:1;font-size:14px;color:#c3c9d3">Folha por corrida</span><b style="font-size:16px">+US$ 0,12 mi</b></div>
<div class="sr" style="height:42px"><span style="flex:1;font-size:14px;color:#c3c9d3">Entra na equipe</span><b style="font-size:16px">virada de 2026 → 2027</b></div>
<div class="reply"><b>Contraproposta</b>“Por 3 anos eu aceito US$ 2,9 mi. Quero um carro competitivo.”</div></div></div>
<div style="display:flex;gap:12px;margin-top:18px"><div class="btn2 ghost" style="margin-left:0;height:54px;background:rgba(255,255,255,.1);color:#fff;padding:0 24px">CANCELAR</div>
<div class="btn2 ghost" style="margin-left:0;height:54px;background:#f3f4f6;padding:0 24px;margin-left:auto">ACEITAR CONTRA (US$ 2,9 mi)</div><div class="btn2 red" style="margin-left:0;height:54px;padding:0 30px">PROPOR</div></div></div></div>'''
    body = f'''<div class="scene"><div class="wall" style="bottom:0"></div><div class="glow" style="background:radial-gradient(ellipse 45% 55% at 30% 60%,{C1}44,transparent 70%)"></div>
{topbar("AURORA RACING · 9 MAR", "PESSOAL · CONTRATOS")}{nav()}{left}{market}{sheet_html}
<div class="note" style="left:44px;bottom:6px;width:600px">EXEMPLO: EQUIPE FICTÍCIA · TÉCNICOS FICTÍCIOS · VALORES PROVISÓRIOS</div></div>'''
    return V.page("V10 · Pessoal" + (" · negociação" if sheet else ""), CSS, body)


if __name__ == "__main__":
    for name, fn in [("v10-1-pessoal", lambda: pessoal(False)), ("v10-2-negociacao", lambda: pessoal(True))]:
        (HERE / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
