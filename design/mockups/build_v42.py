"""V42 · Reformulação de Carro, Fábrica e Patrocínios (respostas do usuário em 2026-11-19).
Quadros: 1 Carro (notas por área × rivais, projetos, esforço atual × próximo ano, gráfico da temporada),
2 Novo projeto (área, tamanho, custo, prazo, faixa de ganho), 3 Fábrica (efeito explícito por nível),
4 Patrocínios (principal + secundários, ofertas com metas e progresso).
Uso: python design/mockups/build_v42.py"""
import pathlib

HERE = pathlib.Path(__file__).parent
TC = "#1347F5"  # Williams

CSS = """
*{box-sizing:border-box;margin:0;padding:0}
body{background:#07080b;font-family:Kanit,system-ui,sans-serif;color:#fff;text-transform:uppercase;padding:24px;display:flex;flex-direction:column;gap:28px;align-items:center}
.cap{color:#8f98a7;font-weight:800;letter-spacing:2px;font-size:13px;align-self:flex-start;margin-left:calc(50% - 640px)}
.f{width:1280px;height:720px;position:relative;overflow:hidden;border-radius:6px;background:radial-gradient(circle at 30% 20%,#18233f,#0b0d12 60%)}
.top{position:absolute;left:0;right:0;top:0;height:64px;background:rgba(7,8,11,.78);display:flex;align-items:center;gap:14px;padding:0 20px;font-weight:900}
.chip{background:rgba(255,255,255,.1);border-radius:10px;padding:6px 12px;font-size:14px;font-weight:900}
.side{position:absolute;left:0;top:64px;bottom:0;width:84px;background:rgba(7,8,11,.7);display:flex;flex-direction:column;align-items:center;gap:6px;padding-top:12px;font-size:11px;font-weight:900;color:#a2a9b5}
.side div{width:72px;height:52px;border-radius:12px;display:grid;place-items:center;text-align:center}
.side .on{background:rgba(255,255,255,.12);color:#fff}
.g{position:absolute;background:rgba(12,15,22,.78);border:1px solid rgba(255,255,255,.08);border-radius:18px;padding:16px}
.k{color:#a2a9b5;font-weight:900;letter-spacing:2px;font-size:12px;margin-bottom:10px}
.t{font-size:22px;font-weight:900}
.bar{height:12px;border-radius:6px;background:rgba(255,255,255,.1);position:relative;margin:6px 0 14px}
.bar i{position:absolute;left:0;top:0;bottom:0;border-radius:6px}
.bar b{position:absolute;top:-4px;width:3px;height:20px;background:#fff;border-radius:2px}
.row{display:flex;justify-content:space-between;font-weight:900;font-size:15px}
.up{color:#7fe0b1}.dn{color:#ff7a6b}.mute{color:#a2a9b5}
.proj{background:rgba(255,255,255,.05);border-radius:14px;padding:12px;margin-bottom:10px}
.go{position:absolute;height:52px;padding:0 22px;border-radius:12px;background:#e10600;display:flex;align-items:center;font-weight:900;font-size:17px;clip-path:polygon(0 0,93% 0,100% 25%,100% 100%,0 100%)}
.ghost{background:rgba(255,255,255,.1);border-radius:12px;padding:10px 16px;font-weight:900;font-size:14px;display:inline-block}
.seg{display:inline-flex;background:rgba(255,255,255,.08);border-radius:14px;padding:4px;gap:4px}
.seg i{font-style:normal;padding:10px 16px;border-radius:10px;font-weight:900;font-size:14px;color:#a2a9b5;text-align:center}
.seg i.on{background:#fff;color:#111}
.area{width:170px;height:118px;border-radius:16px;background:rgba(255,255,255,.06);padding:12px;font-weight:900;font-size:15px;position:relative}
.area.on{background:#fff;color:#111}
.area small{display:block;font-size:11px;color:#8f98a7;margin-top:6px;letter-spacing:1px}
.lvl{display:flex;gap:5px;margin:8px 0}
.lvl i{width:26px;height:10px;border-radius:3px;background:rgba(255,255,255,.12)}
.lvl i.on{background:#7fe0b1}
.note{position:absolute;background:#ffd24a;color:#111;font-weight:900;font-size:11px;border-radius:8px;padding:4px 8px;text-transform:none;max-width:250px;z-index:5}
.offer{border-radius:16px;background:rgba(255,255,255,.06);padding:14px;margin-bottom:10px;position:relative}
.offer.on{outline:2px solid #fff;background:rgba(19,71,245,.18)}
.goal{display:flex;align-items:center;gap:10px;font-size:13px;font-weight:800;margin-top:6px}
.goal .p{flex:1;height:8px;border-radius:4px;background:rgba(255,255,255,.1);position:relative}
.goal .p i{position:absolute;left:0;top:0;bottom:0;border-radius:4px;background:#7fe0b1}
"""


def frame_shell(active, body):
    nav = "".join(f'<div class="{"on" if n == active else ""}">{n}</div>' for n in ["INÍCIO", "TABELA", "PILOTOS", "CARRO", "FÁBRICA", "PATROC.", "CAIXA"])
    return f"""<div class="f"><div class="top"><span style="color:{TC}">◆ WILLIAMS</span><span class="chip">RD 9/23</span><span class="chip">7º</span><span class="chip">US$ 88 MI</span><span class="t" style="margin-left:24px">{active}</span><span class="chip" style="margin-left:auto">12 JUL · 2026</span></div>
<div class="side">{nav}</div>{body}</div>"""


def ratings():
    rows = [("RETA", 78, 84, "+2"), ("CURVAS LENTAS", 71, 80, ""), ("CURVAS RÁPIDAS", 74, 86, "+3"), ("CONFIABILIDADE", 82, 88, "")]
    html = '<div class="k">NOTAS DO CARRO · ▮ MELHOR RIVAL</div>'
    for name, v, best, up in rows:
        html += f'<div class="row"><span>{name}</span><span>{v}{f" <span class=up>{up}</span>" if up else ""}</span></div>'
        html += f'<div class="bar"><i style="width:{v}%;background:{TC}"></i><b style="left:{best}%"></b></div>'
    return html


def graph():
    # linhas da evolução (nota geral) por rodada: você × 3 rivais
    def pts(vals):
        return " ".join(f"{20 + i * 42},{150 - (v - 70) * 7}" for i, v in enumerate(vals))
    you = [76, 76.5, 77, 78, 78.2, 79.4, 80.1, 80.3, 81.5]
    a = [86, 86.2, 86.8, 87, 87.1, 87.5, 87.6, 88, 88.1]
    b = [82, 82.5, 82.6, 83, 83.6, 83.7, 84.4, 84.5, 84.6]
    c = [79, 79.2, 79.4, 79.5, 79.7, 79.8, 80.2, 80.3, 80.5]
    svg = f"""<svg width="560" height="170"><polyline points="{pts(a)}" fill="none" stroke="#00a19b" stroke-width="2.5"/>
<polyline points="{pts(b)}" fill="none" stroke="#ff8000" stroke-width="2.5"/><polyline points="{pts(c)}" fill="none" stroke="#e8392e" stroke-width="2.5"/>
<polyline points="{pts(you)}" fill="none" stroke="{TC}" stroke-width="5"/><circle cx="{20 + 8 * 42}" cy="{150 - (81.5 - 70) * 7}" r="6" fill="{TC}"/>
<text x="20" y="166" fill="#8f98a7" font-size="11" font-weight="800">RD 1</text><text x="350" y="166" fill="#8f98a7" font-size="11" font-weight="800">RD 9</text></svg>"""
    return f'<div class="k">EVOLUÇÃO NA TEMPORADA · VOCÊ × RIVAIS</div>{svg}'


def frame1():
    body = f"""<div class="g" style="left:100px;top:80px;width:380px;height:300px">{ratings()}</div>
<div class="g" style="left:496px;top:80px;width:420px;height:300px"><div class="k">PROJETOS EM ANDAMENTO · 2 DE 3 VAGAS</div>
<div class="proj"><div class="row"><span>ASSOALHO · GRANDE</span><span class="mute">9 DIAS</span></div><div class="bar" style="margin:8px 0"><i style="width:62%;background:#7fe0b1"></i></div><div class="mute" style="font-size:12px;font-weight:800">GANHO ESPERADO: −0,08 A −0,15 S/VOLTA · CURVAS RÁPIDAS</div></div>
<div class="proj"><div class="row"><span>MOTOR · CONFIABILIDADE · MÉDIO</span><span class="mute">4 DIAS</span></div><div class="bar" style="margin:8px 0"><i style="width:85%;background:#7fe0b1"></i></div><div class="mute" style="font-size:12px;font-weight:800">GANHO ESPERADO: −4% A −8% DE CHANCE DE QUEBRA</div></div>
<div class="ghost">+ NOVO PROJETO</div></div>
<div class="g" style="left:932px;top:80px;width:332px;height:300px"><div class="k">ESFORÇO DA EQUIPE</div>
<div class="row"><span>CARRO 2026</span><span>CARRO 2027</span></div>
<div class="bar" style="height:18px;margin:10px 0 6px"><i style="width:70%;background:{TC}"></i><b style="left:70%;height:28px;top:-5px"></b></div>
<div class="row"><span>70%</span><span class="mute">30%</span></div>
<div class="mute" style="font-size:12px;font-weight:800;margin-top:14px;line-height:1.5">O QUE VAI PARA 2027 VIRA A BASE DO CARRO NOVO NA VIRADA. ESTIMATIVA HOJE: +1,8 NA NOTA INICIAL.</div></div>
<div class="g" style="left:100px;top:396px;width:600px;height:300px">{graph()}</div>
<div class="g" style="left:716px;top:396px;width:548px;height:300px"><div class="k">ÚLTIMAS ENTREGAS</div>
<div class="proj"><span class="up">✔ ASA DIANTEIRA B</span> · ENTREGUE RD 7<div class="mute" style="font-size:12px;font-weight:800;margin-top:4px">ESPERADO −0,10 · <span class="up">REAL −0,12 S/VOLTA (CURVAS LENTAS)</span></div></div>
<div class="proj"><span class="up">✔ SUSPENSÃO B</span> · ENTREGUE RD 5<div class="mute" style="font-size:12px;font-weight:800;margin-top:4px">ESPERADO −0,06 · <span class="dn">REAL −0,04 S/VOLTA (CURVAS LENTAS)</span></div></div></div>
<span class="note" style="left:250px;top:640px">barras = sua nota; risco branco = melhor rival naquela área; "+2" = o que subiu desde o último GP</span>
<span class="note" style="left:960px;top:330px">ganho sempre positivo; o real (60–120% do esperado) aparece na entrega</span>"""
    return frame_shell("CARRO", body)


def frame2():
    areas = [("ASA DIANTEIRA", "curvas lentas"), ("ASA TRASEIRA", "reta × curvas"), ("ASSOALHO", "curvas rápidas"), ("SUSPENSÃO", "curvas lentas"), ("MOTOR", "reta · confiabilidade")]
    cards = "".join(f'<div class="area{" on" if n == "ASSOALHO" else ""}" style="position:absolute;left:{120 + i * 186}px;top:150px">{n}<small>{s}</small></div>' for i, (n, s) in enumerate(areas))
    body = f"""<div class="t" style="position:absolute;left:120px;top:92px;font-size:30px">NOVO PROJETO</div>{cards}
<div class="g" style="left:120px;top:290px;width:540px;height:330px"><div class="k">TAMANHO DO PROJETO</div>
<div class="seg"><i>PEQUENO<br><small>US$ 3 MI · 8 DIAS</small></i><i class="on">MÉDIO<br><small>US$ 6 MI · 14 DIAS</small></i><i>GRANDE<br><small>US$ 11 MI · 24 DIAS</small></i></div>
<div class="k" style="margin-top:22px">GANHO ESPERADO (ASSOALHO MÉDIO)</div>
<div class="t">−0,06 A −0,11 S/VOLTA</div><div class="mute" style="font-weight:800;font-size:13px;margin-top:4px">EM PISTAS DE CURVAS RÁPIDAS (SILVERSTONE, SUZUKA, SPA…) · METADE NAS OUTRAS</div>
<div class="k" style="margin-top:22px">FAIXA DO RESULTADO</div>
<div class="bar" style="height:16px"><i style="left:60%;width:0"></i><i style="left:28%;width:52%;background:linear-gradient(90deg,#ffd24a,#7fe0b1)"></i></div>
<div class="row mute" style="font-size:12px"><span>60%</span><span>ESPERADO</span><span>120%</span></div></div>
<div class="g" style="left:676px;top:290px;width:470px;height:330px"><div class="k">QUEM APERTA A FAIXA</div>
<div class="row" style="margin-bottom:10px"><span>CHEFE DE AERODINÂMICA · 84</span><span class="up">+8%</span></div>
<div class="row" style="margin-bottom:10px"><span>TÚNEL DE VENTO · NÍVEL 3</span><span class="up">+6%</span></div>
<div class="row" style="margin-bottom:10px"><span>VAGAS LIVRES</span><span>1 DE 3</span></div>
<div class="row" style="margin-bottom:10px"><span>TETO DE GASTOS RESTANTE</span><span>US$ 31 MI</span></div>
<div class="row"><span>VAI PARA</span><span>CARRO 2026</span></div></div>
<div class="go" style="right:134px;bottom:30px">INICIAR PROJETO · US$ 6 MI ›</div>
<span class="note" style="left:720px;top:640px">a área diz em que tipo de pista a peça ajuda (perfil das pistas)</span>"""
    return frame_shell("CARRO", body)


def frame3():
    st = [("TÚNEL DE VENTO / CFD", 3, ["projetos de aero 15% mais rápidos", "faixa do ganho aero +6%"], ["projetos de aero 22% mais rápidos", "faixa do ganho aero +9%"], "US$ 14 MI · 40 DIAS"),
          ("FÁBRICA DE PEÇAS", 2, ["2 projetos ao mesmo tempo", "peças mecânicas 8% mais rápidas"], ["3 projetos ao mesmo tempo", "peças mecânicas 14% mais rápidas"], "US$ 12 MI · 35 DIAS"),
          ("SIMULADOR", 2, ["chance de bom acerto +6%"], ["chance de bom acerto +10%"], "US$ 8 MI · 25 DIAS"),
          ("MARKETING", 1, ["ofertas de patrocínio +0%"], ["ofertas de patrocínio +8%", "1 meta a mais por oferta"], "US$ 6 MI · 20 DIAS")]
    cards = ""
    for i, (name, lvl, now, nxt, cost) in enumerate(st):
        x = 100 + (i % 2) * 586
        y = 84 + (i // 2) * 312
        lv = "".join(f'<i class="{"on" if k < lvl else ""}"></i>' for k in range(5))
        cards += f"""<div class="g" style="left:{x}px;top:{y}px;width:570px;height:296px"><div class="row"><span class="t">{name}</span><span class="mute">NÍVEL {lvl}/5</span></div><div class="lvl">{lv}</div>
<div style="display:flex;gap:12px;margin-top:8px"><div class="proj" style="flex:1"><div class="k">AGORA</div>{"<br>".join(now)}</div><div class="proj" style="flex:1;outline:1px solid rgba(127,224,177,.5)"><div class="k up">NÍVEL {lvl + 1}</div>{"<br>".join(nxt)}</div></div>
<div class="row" style="margin-top:8px"><span class="mute">{cost}</span><span class="ghost">AMPLIAR</span></div></div>"""
    return frame_shell("FÁBRICA", cards + '<span class="note" style="left:640px;top:70px">cada nível com o efeito escrito em números e o antes/depois</span>')


def frame4():
    body = f"""<div class="g" style="left:100px;top:80px;width:560px;height:616px"><div class="k">PATROCINADOR PRINCIPAL · ESCOLHA 1 DE 3 OFERTAS</div>
<div class="offer on"><div class="row"><span class="t">NOVA ENERGIA</span><span>US$ 2,4 MI / CORRIDA</span></div>
<div class="goal"><span>TOP 6 NO CAMPEONATO</span><span class="up">+ US$ 12 MI</span></div><div class="goal"><span>3 PÓDIOS</span><span class="up">+ US$ 6 MI</span></div></div>
<div class="offer"><div class="row"><span class="t">AURORA BANK</span><span>US$ 3,0 MI / CORRIDA</span></div>
<div class="goal"><span>SEM METAS</span><span class="mute">—</span></div></div>
<div class="offer"><div class="row"><span class="t">VOLTZ TELECOM</span><span>US$ 1,6 MI / CORRIDA</span></div>
<div class="goal"><span>TOP 5 NO CAMPEONATO</span><span class="up">+ US$ 22 MI</span></div><div class="goal"><span>1 VITÓRIA</span><span class="up">+ US$ 10 MI</span></div></div>
<div class="mute" style="font-size:12px;font-weight:800;margin-top:6px;line-height:1.5">METAS MAIS OUSADAS PAGAM MAIS. NÃO CUMPRIR = SÓ PERDE O BÔNUS. (MARCAS FICTÍCIAS)</div></div>
<div class="g" style="left:676px;top:80px;width:588px;height:320px"><div class="k">SECUNDÁRIOS · 3 VAGAS</div>
<div class="proj"><div class="row"><span>KESTREL ÓLEO</span><span>US$ 0,8 MI / CORRIDA</span></div><div class="goal"><span>10 CORRIDAS NOS PONTOS</span><div class="p"><i style="width:60%"></i></div><span>6/10</span></div></div>
<div class="proj"><div class="row"><span>LUMA RELÓGIOS</span><span>US$ 0,6 MI / CORRIDA</span></div><div class="goal"><span>1 VOLTA MAIS RÁPIDA</span><div class="p"><i style="width:100%"></i></div><span class="up">✔</span></div></div>
<div class="proj" style="text-align:center;color:#a2a9b5">+ VAGA LIVRE · VER 3 OFERTAS</div></div>
<div class="g" style="left:676px;top:416px;width:588px;height:280px"><div class="k">NO ANO · PROGRESSO DAS METAS</div>
<div class="row"><span>FIXO GARANTIDO</span><span>US$ 84 MI</span></div>
<div class="row" style="margin-top:8px"><span>BÔNUS JÁ GARANTIDO</span><span class="up">US$ 4 MI</span></div>
<div class="row" style="margin-top:8px"><span>BÔNUS EM JOGO</span><span>US$ 18 MI</span></div>
<div class="goal" style="margin-top:14px"><span>TOP 6 (VOCÊ: 7º)</span><div class="p"><i style="width:80%;background:#ffd24a"></i></div><span>QUASE</span></div>
<div class="goal"><span>3 PÓDIOS</span><div class="p"><i style="width:33%"></i></div><span>1/3</span></div></div>
<span class="note" style="left:110px;top:56px">no início do ano: 3 ofertas para o principal e para cada vaga secundária</span>"""
    return frame_shell("PATROC.", body)


def main():
    html = (f'<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>V42 · Carro, Fábrica e Patrocínios</title><style>{CSS}</style><body>'
            f'<div class="cap">1 · Carro</div>{frame1()}<div class="cap">2 · Novo projeto</div>{frame2()}'
            f'<div class="cap">3 · Fábrica</div>{frame3()}<div class="cap">4 · Patrocínios</div>{frame4()}</body></html>')
    (HERE / "v42-carro-fabrica-patrocinio.html").write_text(html, encoding="utf-8")
    print("ok")


if __name__ == "__main__":
    main()
