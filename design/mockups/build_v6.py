"""Campanha — temporada completa (direção Garagem): sede, campeonatos e relatório da diretoria.
Uso: python design/mockups/build_v6.py   (gera v6-*.html nesta pasta)
Equipe criada de exemplo (Aurora Racing) é fictícia; metas, finanças e pontos são dados de EXEMPLO.
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402

HERE = B.HERE
ico = V.ico
C1, C2 = "#0E7C66", "#F2A900"

CSS = V.G_CSS + """
.top{position:absolute;left:44px;right:44px;top:24px;display:flex;align-items:center;gap:14px}
.top .tm b{display:block;font-size:13px;letter-spacing:3px;color:#8f98a7}.top .tm h1{font-size:28px;font-weight:900;line-height:1}
.date{margin-left:auto;display:flex;align-items:center;gap:12px;background:rgba(255,255,255,.07);border-radius:26px;padding:8px 20px}
.date b{font-size:20px;font-weight:900}.date small{display:block;font-size:12px;letter-spacing:2px;color:#8f98a7}
.chipm{display:flex;align-items:center;gap:8px;background:rgba(255,255,255,.07);border-radius:22px;padding:8px 16px;font-size:15px;font-weight:700}
.chipm small{font-size:11px;letter-spacing:2px;color:#8f98a7;font-weight:700}
.nav{position:absolute;left:44px;top:92px;display:flex;gap:6px;background:rgba(255,255,255,.07);border-radius:26px;padding:4px}
.nav span{height:44px;padding:0 20px;border-radius:22px;display:grid;place-items:center;font-size:16px;font-weight:700;color:#c3c9d3}.nav span.on{background:#f3f4f6;color:#11141a}
.hero{position:absolute;left:44px;top:156px;width:560px;height:262px;border-radius:22px;background:#f3f4f6;color:#11141a;padding:24px 28px;overflow:hidden}
.hero:before{content:"";position:absolute;left:0;top:0;bottom:0;width:7px;background:#E10600}
.hero .k{font-size:13px;letter-spacing:3px;color:#4b5260;font-weight:700}.hero h2{font-size:40px;font-weight:900;line-height:1;margin:6px 0 4px}
.hero p{font-size:15px;color:#4b5260}.hero svg.trk{position:absolute;right:24px;top:22px}
.cnt{display:flex;gap:10px;margin-top:10px}.cnt div{background:#e3e6eb;border-radius:12px;padding:8px 14px 9px;font-size:13px;color:#4b5260;line-height:1.25}.cnt b{display:block;font-size:22px;color:#11141a;font-weight:900;line-height:1.05}
.hero .acts{position:absolute;left:28px;bottom:20px;display:flex;gap:12px}
.card{position:absolute;border-radius:20px;background:rgba(255,255,255,.06);padding:18px 20px}
.lbl{font-size:12px;letter-spacing:2.5px;color:#8f98a7;margin-bottom:8px;font-weight:700}
.prog{height:12px;border-radius:7px;background:rgba(255,255,255,.1);position:relative;margin:10px 0 6px}.prog i{position:absolute;left:0;top:0;bottom:0;border-radius:7px}
.tick{position:absolute;top:-4px;bottom:-4px;width:3px;background:#fff;border-radius:2px}
.row2{display:flex;align-items:center;gap:10px;height:40px;font-size:16px;border-bottom:1px solid rgba(255,255,255,.07)}
.card .row2 svg,.card .row2 img{position:static;opacity:1;flex:none}.row2 .n{width:26px;font-weight:900;color:#a8b0bd}.row2 .nm{flex:1;font-weight:700}.row2 .p{font-weight:900;min-width:40px;text-align:right}.card p b{display:inline}.row2.me{background:rgba(14,124,102,.3);border-radius:10px;border-bottom:none;padding:0 18px 0 12px;margin:4px -8px 0;gap:10px}
.pos{width:30px;height:24px;border-radius:7px;display:grid;place-items:center;font-weight:900;font-size:14px}
.tab{display:flex;background:rgba(255,255,255,.07);border-radius:22px;padding:4px;gap:4px}.tab span{height:38px;padding:0 18px;border-radius:19px;display:grid;place-items:center;font-size:15px;font-weight:700;color:#c3c9d3}.tab span.on{background:#f3f4f6;color:#11141a}
.note{position:absolute;font-size:11px;letter-spacing:1.5px;color:#5d6574}
.sh{position:absolute;border-radius:20px;background:rgba(255,255,255,.04);overflow:hidden}
.th{display:flex;height:40px;align-items:center;font-size:12px;letter-spacing:2px;color:#8f98a7;padding:0 14px;border-bottom:1px solid rgba(255,255,255,.08)}
.tr{display:flex;height:34px;align-items:center;padding:0 14px;font-size:15px;border-bottom:1px solid rgba(255,255,255,.07)}
.tr .p{width:32px;height:24px;border-radius:7px;display:grid;place-items:center;font-weight:900;font-size:14px;margin-right:12px}
.tr .n{flex:1;font-weight:900}.tr .t{width:170px;color:#a8b0bd;font-size:14px}.tr .w{width:60px;text-align:right;color:#a8b0bd}.tr .s{width:70px;text-align:right;font-weight:900;font-size:17px}
.tr.me{background:rgba(14,124,102,.3)}
.verd{position:absolute;left:44px;top:110px;width:600px}
.big{font-size:70px;font-weight:900;line-height:.95}
"""


def team_row(pos, tid, name, pts, me=False, wins=None):
    t = B.teams.get(tid)
    col = t["color"] if t else C1
    lum = int(col[1:3], 16) * .299 + int(col[3:5], 16) * .587 + int(col[5:7], 16) * .114
    fg = "#11141a" if lum > 140 else "#fff"
    emb = (f'<img src="{V.EMB.format(tid)}" width="20">' if t else
           f'<svg width="20" height="20" viewBox="0 0 24 24"><path d="M7 2h10l5 10-5 10H7L2 12z" fill="{C1}" stroke="{C2}" stroke-width="1.4"/></svg>')
    return (f'<div class="tr{" me" if me else ""}"><span class="p" style="background:{col};color:{fg}">{pos}</span>{emb}'
            f'<span class="n" style="margin-left:10px">{name}</span>'
            + (f'<span class="w">{wins}</span>' if wins is not None else "") + f'<span class="s">{pts}</span></div>')


def sede():
    car = V.car_svg(C1, C2, 2, width=640, uid="s")
    standings = [(1, "mclaren", "McLaren", 187), (2, "mercedes", "Mercedes", 141), (3, "ferrari", "Ferrari", 133), (4, "redbull", "Red Bull Racing", 109),
                 (5, "williams", "Williams", 58), (6, "astonmartin", "Aston Martin", 41)]
    rows = "".join(f'<div class="row2"><span class="n">{p}</span><img src="{V.EMB.format(t)}" width="20"><span class="nm">{n}</span><span class="p">{s}</span></div>' for p, t, n, s in standings)
    rows += (f'<div class="row2 me"><span class="n">9</span><svg width="20" height="20" viewBox="0 0 24 24" style="flex:none"><path d="M7 2h10l5 10-5 10H7L2 12z" fill="{C1}" stroke="{C2}" stroke-width="1.4"/></svg>'
             '<span class="nm">Aurora Racing</span><span class="p">17</span></div>')
    body = f'''<div class="scene"><div class="wall" style="bottom:0"></div><div class="glow" style="background:radial-gradient(ellipse 45% 50% at 70% 60%,{C1}55,transparent 70%)"></div>
<div class="top"><span class="round">{ico("back", 26, "#eef0f3", 2.6)}</span>
<svg width="46" height="46" viewBox="0 0 24 24"><path d="M7 2h10l5 10-5 10H7L2 12z" fill="{C1}" stroke="{C2}" stroke-width="1.4"/></svg>
<div class="tm"><b>SEDE · TEMPORADA 2026</b><h1>AURORA RACING</h1></div>
<div class="date"><div><small>HOJE</small><b>SEG, 09 MAR</b></div></div>
<div class="chipm"><div><small>CAIXA</small>US$ 176 mi</div></div><div class="chipm"><div><small>DIRETORIA</small>Satisfeita</div></div></div>
<div class="nav"><span class="on">Início</span><span>Campeonatos</span><span>Pilotos</span><span>Carro</span><span>Fábrica</span><span>Finanças</span></div>
<div class="hero"><div class="k">PRÓXIMO EVENTO · EM 6 DIAS</div><h2>GP DA CHINA</h2><p>Xangai · 13 a 15 de março · fim de semana sprint</p>
<div class="cnt"><div><b>6</b>dias</div><div><b>2</b>treinos + sprint</div><div><b>40%</b>chuva dom.</div></div>
{V.outline("shanghai", 150, 120, "#11141a", 6, 8).replace("<svg ", '<svg class="trk" ', 1)}
<div class="acts"><div class="cta" style="height:56px;padding:0 24px;font-size:18px;width:340px">AVANÇAR ATÉ O EVENTO {ico("chev", 22, "#fff", 3)}</div>
<div style="height:56px;padding:0 18px;border-radius:14px;background:#e3e6eb;display:flex;align-items:center;font-weight:900;font-size:17px">+1 DIA</div></div></div>
<div class="card" style="left:44px;top:430px;width:560px;height:170px"><div class="lbl">OBJETIVO DA DIRETORIA · TEMPORADA 2026</div>
<div style="display:flex;align-items:baseline;gap:10px"><b style="font-size:26px;font-weight:900">Terminar no top 8 dos construtores</b></div>
<div class="prog"><i style="width:34%;background:linear-gradient(90deg,{C1},#3ec9a6)"></i><span class="tick" style="left:60%"></span></div>
<div style="display:flex;justify-content:space-between;font-size:13px;color:#a8b0bd"><span>Hoje: 9º · 17 pts</span><span>Meta: 8º ou melhor</span></div>
<div style="display:flex;gap:10px;margin-top:8px;align-items:center"><span style="font-size:13px;color:#a8b0bd;letter-spacing:1px">PACIÊNCIA DA DIRETORIA</span>
<span style="flex:1;height:10px;border-radius:6px;background:rgba(255,255,255,.1);position:relative"><i style="position:absolute;inset:0 auto 0 0;width:68%;border-radius:6px;background:#5c93ea"></i></span><b>Boa</b></div></div>
<div class="card" style="left:44px;top:612px;width:560px;height:84px;padding:14px 20px;display:flex;gap:30px;align-items:center">
<div><div class="lbl" style="margin:0">ORÇAMENTO</div><b style="font-size:22px">US$ 176 mi</b></div><div><div class="lbl" style="margin:0">DESPESA MENSAL</div><b style="font-size:22px">US$ 11 mi</b></div>
<div><div class="lbl" style="margin:0">PRÊMIOS ESPERADOS</div><b style="font-size:22px">US$ 62 mi</b></div></div>
<div class="card" style="right:44px;top:100px;width:400px;height:330px"><div class="lbl">CONSTRUTORES · APÓS 1 DE 22</div>{rows}</div>
<div style="position:absolute;right:20px;bottom:90px">{car}</div>
<div class="note" style="left:44px;bottom:6px">EXEMPLO: EQUIPE FICTÍCIA · METAS, CAIXA E PONTOS SÃO DADOS ILUSTRATIVOS · FINANÇAS/FÁBRICA/CARRO = PRÓXIMAS CAMADAS (ABAS APAGADAS)</div></div>'''
    return V.page("V6 · Campanha · sede", CSS, body)


def campeonatos():
    teams = [("mclaren", 187, 4), ("mercedes", 141, 2), ("ferrari", 133, 1), ("redbull", 109, 1), ("williams", 58, 0), ("astonmartin", 41, 0),
             ("racingbulls", 38, 0), ("haas", 29, 0), ("aurora", 17, 0), ("alpine", 14, 0), ("audi", 9, 0), ("cadillac", 3, 0)]
    trs = ""
    for i, (t, p, w) in enumerate(teams):
        name = "Aurora Racing" if t == "aurora" else B.teams[t]["name"]
        trs += team_row(i + 1, t, name, p, me=(t == "aurora"), wins=w)
    drivers = [("NORRIS", "mclaren", 112, 3), ("PIASTRI", "mclaren", 75, 1), ("RUSSELL", "mercedes", 77, 1), ("LECLERC", "ferrari", 71, 1), ("VERSTAPPEN", "redbull", 70, 1),
               ("ANTONELLI", "mercedes", 64, 1), ("HAMILTON", "ferrari", 62, 0), ("ALBON", "williams", 33, 0), ("SAINZ", "williams", 25, 0), ("CÂMARA", "aurora", 11, 0), ("HERTA", "aurora", 6, 0)]
    dr = ""
    for i, (n, t, p, w) in enumerate(drivers):
        col = B.teams[t]["color"] if t in B.teams else C1
        lum = int(col[1:3], 16) * .299 + int(col[3:5], 16) * .587 + int(col[5:7], 16) * .114
        emb = f'<img src="{V.EMB.format(t)}" width="20">' if t in B.teams else f'<svg width="20" height="20" viewBox="0 0 24 24"><path d="M7 2h10l5 10-5 10H7L2 12z" fill="{C1}" stroke="{C2}" stroke-width="1.4"/></svg>'
        dr += (f'<div class="tr{" me" if t == "aurora" else ""}"><span class="p" style="background:{col};color:{"#11141a" if lum > 140 else "#fff"}">{i + 1}</span>{emb}'
               f'<span class="n" style="margin-left:10px">{n}</span><span class="w">{w}</span><span class="s">{p}</span></div>')
    body = f'''<div class="scene"><div class="wall" style="bottom:0"></div>
<div class="top"><span class="round">{ico("back", 26, "#eef0f3", 2.6)}</span><div class="tm"><b>AURORA RACING · APÓS 4 DE 22 RODADAS</b><h1>CAMPEONATOS</h1></div>
<div class="tab" style="margin-left:auto"><span class="on">2026</span><span>Histórico</span></div></div>
<div class="sh" style="left:44px;top:96px;width:600px;bottom:24px"><div class="th"><span style="flex:1">CONSTRUTORES</span><span style="width:60px;text-align:right">VIT.</span><span style="width:70px;text-align:right">PTS</span></div>{trs}</div>
<div class="sh" style="right:44px;top:96px;width:560px;bottom:24px"><div class="th"><span style="flex:1">PILOTOS</span><span style="width:60px;text-align:right">VIT.</span><span style="width:70px;text-align:right">PTS</span></div>{dr}
<div style="position:absolute;left:14px;right:14px;bottom:14px;font-size:13px;color:#8f98a7;line-height:1.5">A sua equipe aparece destacada. Toque num piloto ou equipe para ver o histórico de resultados.</div></div>
<div class="note" style="left:44px;bottom:6px">DADOS DE EXEMPLO · 12 EQUIPES / 24 PILOTOS NO GRID (TELA ROLA)</div></div>'''
    return V.page("V6 · Campanha · campeonatos", CSS, body)


def relatorio():
    body = f'''<div class="scene"><div class="wall" style="bottom:0"></div><div class="glow" style="background:radial-gradient(ellipse 40% 50% at 30% 45%,{C1}55,transparent 70%)"></div>
<div class="top"><span class="round">{ico("back", 26, "#eef0f3", 2.6)}</span><div class="tm"><b>AURORA RACING · FIM DA TEMPORADA 2026</b><h1>RELATÓRIO DA DIRETORIA</h1></div></div>
<div class="verd"><div class="lbl">VEREDITO</div><div class="big">META<br>CUMPRIDA</div>
<p style="font-size:18px;color:#c3c9d3;margin-top:14px;max-width:520px;line-height:1.5">Vocês terminaram em <b style="color:#fff">8º</b> entre os construtores, a meta era o top 8. A diretoria renova a confiança e libera mais orçamento.</p>
<div style="display:flex;gap:14px;margin-top:22px"><div class="card" style="position:static;width:170px"><div class="lbl" style="margin:0">POSIÇÃO FINAL</div><b style="font-size:38px;font-weight:900">8º</b></div>
<div class="card" style="position:static;width:170px"><div class="lbl" style="margin:0">PONTOS</div><b style="font-size:38px;font-weight:900">64</b></div>
<div class="card" style="position:static;width:170px"><div class="lbl" style="margin:0">MELHOR CORRIDA</div><b style="font-size:38px;font-weight:900">6º</b></div></div></div>
<div class="card" style="right:44px;top:100px;width:520px;height:420px"><div class="lbl">PRÓXIMA TEMPORADA · 2027</div>
<div class="row2"><span class="nm">Orçamento base</span><span class="p">US$ 210 mi <small style="color:#7fe0b1;font-size:13px">+ 34</small></span></div>
<div class="row2"><span class="nm">Paciência da diretoria</span><span class="p">Boa</span></div>
<div class="row2"><span class="nm">Nova meta</span><span class="p">Top 6 dos construtores</span></div>
<div class="row2"><span class="nm">Contratos que vencem</span><span class="p">0 pilotos</span></div>
<p style="margin-top:18px;font-size:14px;color:#a8b0bd;line-height:1.55;display:block">Se a meta não fosse cumprida, a paciência cairia. Com a paciência esgotada ou o caixa negativo, o resultado seria <b style="color:#ffb4a8;display:inline;font-size:inherit">demissão</b> ou <b style="color:#ffb4a8;display:inline;font-size:inherit">falência</b>, e outra equipe poderia fazer uma proposta.</p></div>
<div class="foot" style="position:absolute;left:44px;right:44px;bottom:26px;display:flex;align-items:center"><div class="cta" style="margin-left:auto;width:380px">INICIAR TEMPORADA 2027 {ico("chev", 24, "#fff", 3)}</div></div>
<div class="note" style="left:44px;bottom:6px">EXEMPLO · METAS E VALORES PROVISÓRIOS · O CAMINHO DE FRACASSO (DEMISSÃO/FALÊNCIA) USA UMA VARIAÇÃO DESTA MESMA TELA</div></div>'''
    return V.page("V6 · Campanha · relatório da diretoria", CSS, body)


if __name__ == "__main__":
    for name, fn in [("v6-1-campanha-sede", sede), ("v6-2-campanha-campeonatos", campeonatos), ("v6-3-campanha-relatorio", relatorio)]:
        (HERE / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
