"""V15 · Campanha reestruturada (prompt mestre, decisões de 2026-11-04) — passo 1.
Uso: python design/mockups/build_v15.py   (gera v15-*.html nesta pasta; V15_FACES=<pasta> e V15_OUT=<pasta> para a versão com fotos locais)
1) Sede: próximo GP com o perfil da pista, até 3 assuntos (NOTÍCIA × DECISÃO) e "avançar com preparação recomendada".
2) Carro > Peças: 4 características do carro × perfil da pista, estoque e instalação por carro, decisão de estrear uma peça.
3) Pesquisa concluída: especificação liberada, custo por unidade e para qual GP cada unidade fica pronta.
Equipe de exemplo: Williams. Datas, custos e ganhos são EXEMPLOS coerentes com o jogo (valores provisórios).
"""
import os
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402

HERE = B.HERE
ico = V.ico
FACES = os.environ.get("V15_FACES")
TEAM = B.teams["williams"]
COL = TEAM["color"]
MY = [d for d in V.DRIVERS if d["team"] == "williams"]  # Albon, Sainz

CSS = V.G_CSS + """
.scene{background:#0b0c0f}
.bg{position:absolute;inset:0;background:linear-gradient(#171a20,#0c0d10)}
.bg:before{content:"";position:absolute;inset:0;background:repeating-linear-gradient(180deg,rgba(255,255,255,.03) 0 1px,transparent 1px 46px)}
.bg:after{content:"";position:absolute;inset:0;background:radial-gradient(ellipse 50% 60% at 18% 40%,%COL%33,transparent 70%)}
.hd{position:absolute;left:36px;top:18px;right:36px;display:flex;align-items:center;gap:14px}
.rb{width:46px;height:46px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center;flex:none}
.hd small{display:block;font-size:12px;letter-spacing:2.5px;color:#9aa3b2;font-weight:700}.hd h1{font-size:28px;font-weight:900;line-height:1}
.chip{height:44px;padding:0 16px;border-radius:22px;background:rgba(255,255,255,.08);display:flex;align-items:center;gap:8px;font-size:13px;color:#a8b0bd;font-weight:700;white-space:nowrap}
.chip b{color:#fff;font-size:16px;font-weight:900}
.nav{position:absolute;left:36px;top:78px;display:flex;gap:3px;background:rgba(255,255,255,.06);border-radius:26px;padding:4px}
.nav span{height:40px;padding:0 17px;border-radius:20px;display:grid;place-items:center;font-size:15px;font-weight:700;color:#c3c9d3}
.nav span.on{background:#f3f4f6;color:#11141a}
.card{position:absolute;border-radius:22px;background:rgba(255,255,255,.06);padding:16px 18px}
.cap{font-size:11px;letter-spacing:2.5px;color:#8f98a7;font-weight:700}
.cta{height:56px;border-radius:14px 0 14px 14px;clip-path:polygon(0 0,calc(100% - 16px) 0,100% 16px,100% 100%,0 100%);background:#E10600;color:#fff;font-weight:900;font-size:17px;letter-spacing:.5px;display:flex;align-items:center;justify-content:center;gap:10px}
.ghost{height:46px;border-radius:14px;background:rgba(255,255,255,.08);display:flex;align-items:center;justify-content:center;font-size:14px;font-weight:700;color:#c3c9d3}
.bar{height:8px;border-radius:5px;background:rgba(255,255,255,.1);position:relative;flex:1}.bar i{position:absolute;inset:0 auto 0 0;border-radius:5px}
.trait{display:flex;align-items:center;gap:10px;font-size:13px;font-weight:700;color:#c3c9d3;height:28px}.trait .l{width:116px}.trait b{width:34px;text-align:right;color:#fff;font-weight:900}
.gp{left:36px;top:140px;width:470px;height:560px;overflow:hidden;padding:0}
.gp .gflag{position:absolute;inset:0 0 auto 0;height:190px;background:linear-gradient(#CE1126 50%,#fff 50%);opacity:.26}
.gp .gflag:after{content:"";position:absolute;inset:0;background:linear-gradient(transparent 30%,rgba(16,18,22,.95))}
.gp .in{position:relative;padding:18px 22px}
.gp h2{font-size:38px;font-weight:900;line-height:1;margin-top:6px}.gp .when{font-size:15px;color:#c3c9d3;margin-top:6px;font-weight:700}
.est{display:flex;gap:10px;margin:14px 0 10px}.est div{flex:1;border-radius:14px;background:rgba(0,0,0,.35);padding:10px 12px;font-size:12px;color:#a8b0bd;font-weight:700}.est b{display:block;font-size:22px;color:#fff;font-weight:900}
.issues{left:526px;top:140px;width:420px}
.is{border-radius:18px;background:rgba(255,255,255,.06);padding:13px 15px;margin-top:10px;position:relative}
.is .tg{display:inline-block;font-size:10px;letter-spacing:2px;font-weight:900;border-radius:7px;padding:3px 8px}
.is .tg.tdec{background:#E10600;color:#fff}.is .tg.tnews{background:rgba(255,255,255,.14);color:#c3c9d3}
.is b{display:block;font-size:16px;font-weight:900;margin:6px 0 3px;line-height:1.2}.is p{font-size:13px;color:#c3c9d3;line-height:1.35}
.opts{display:flex;gap:6px;margin-top:9px}.opts span{flex:1;height:40px;border-radius:11px;background:rgba(255,255,255,.1);display:grid;place-items:center;font-size:12px;font-weight:900;text-align:center;line-height:1.1}
.opts span.rec{background:#f3f4f6;color:#11141a}
.is .go{position:absolute;right:14px;top:13px;font-size:12px;color:#8f98a7;font-weight:700;display:flex;gap:4px;align-items:center;white-space:nowrap}.is .go svg{display:inline-block;position:static}
.team{left:966px;top:140px;width:278px}
.drv{display:flex;align-items:center;gap:10px;margin-top:10px}.drv b{display:block;font-size:16px;font-weight:900}.drv small{font-size:12px;color:#a8b0bd;font-weight:700}
.drv .p{margin-left:auto;font-size:22px;font-weight:900;color:#E10600}
.goal{margin-top:14px;border-radius:14px;background:rgba(0,0,0,.3);padding:10px 12px}
/* peças */
.traits{left:36px;top:140px;width:360px}
.parts{left:416px;top:140px;width:470px}
.prt{display:flex;align-items:center;gap:10px;height:62px;border-bottom:1px solid rgba(255,255,255,.07)}
.prt .ic{width:38px;height:38px;border-radius:11px;display:grid;place-items:center;flex:none;font-weight:900;font-size:13px}
.prt .nm{flex:1}.prt .nm b{display:block;font-size:15px;font-weight:900}.prt .nm small{font-size:12px;color:#a8b0bd;font-weight:700}
.car2{display:flex;gap:6px}.car2 span{width:58px;height:40px;border-radius:10px;background:rgba(255,255,255,.07);display:flex;flex-direction:column;align-items:center;justify-content:center;font-size:11px;color:#a8b0bd;font-weight:700;line-height:1.15}
.car2 span b{font-size:12px;color:#fff}.car2 span.new{background:rgba(57,211,107,.18)}.car2 span.new b{color:#7fe0b1}
.stk{width:54px;text-align:center;font-size:11px;color:#a8b0bd;font-weight:700}.stk b{display:block;font-size:18px;color:#fff;font-weight:900}
.prt.sel{background:rgba(255,255,255,.07);border-radius:12px;padding:0 8px;border-bottom:none;outline:2px solid #f3f4f6}
.decp{left:906px;top:140px;width:338px;height:562px}
.tl{position:relative;margin:8px 0 2px;height:72px}
.tl .line{position:absolute;left:8px;right:8px;top:40px;height:3px;background:rgba(255,255,255,.15)}
.tl .gp2{position:absolute;top:24px;width:2px;height:34px;background:#ffd24a}
.tl .gp2 small{position:absolute;top:-20px;left:-22px;width:60px;text-align:center;font-size:10px;color:#ffd24a;font-weight:900;letter-spacing:1px}
.tl .u{position:absolute;top:32px;width:18px;height:18px;border-radius:50%;background:#5c93ea;border:3px solid #0b0c0f}
.tl .u small{position:absolute;top:22px;left:-26px;width:70px;text-align:center;font-size:10px;color:#c3c9d3;font-weight:700}
.ch{border-radius:14px;background:rgba(255,255,255,.07);padding:7px 12px;margin-top:6px;display:flex;align-items:center;gap:10px}
.ch.on{background:#f3f4f6;color:#11141a}.ch.on small{color:#4b5260}
.ch .r{width:20px;height:20px;border-radius:50%;border:3px solid rgba(255,255,255,.4);flex:none}.ch.on .r{border-color:#E10600;background:radial-gradient(#E10600 45%,transparent 50%)}
.ch b{display:block;font-size:14px;font-weight:900}.ch small{display:block;font-size:12px;color:#a8b0bd;font-weight:700;line-height:1.3}
.ch .cost{margin-left:auto;text-align:right;font-size:13px;font-weight:900;white-space:nowrap}
.after{margin-top:12px;font-size:12px;color:#a8b0bd;font-weight:700;line-height:1.5}.after span{color:#fff}
/* modal */
.sheet{position:absolute;inset:0;background:rgba(5,6,8,.74);display:flex;align-items:center;justify-content:center}
.md{width:820px;border-radius:26px;background:#f3f4f6;color:#11141a;padding:26px 30px 24px 40px;position:relative;box-shadow:0 20px 60px rgba(0,0,0,.6)}
.md:before{content:"";position:absolute;left:0;top:0;bottom:0;width:10px;background:#3c9d5d;border-radius:26px 0 0 26px}
.md .k{font-size:12px;letter-spacing:3px;color:#4b5260;font-weight:700}.md h2{font-size:32px;font-weight:900;line-height:1.05;margin:6px 0 4px}
.md p{font-size:15px;color:#2b303a;line-height:1.45}
.facts{display:flex;gap:10px;margin:16px 0}.facts div{flex:1;border-radius:14px;background:#e3e6eb;padding:10px 14px;font-size:12px;color:#4b5260;line-height:1.3;font-weight:700}.facts b{display:block;font-size:20px;color:#11141a;font-weight:900}
.orders{display:flex;gap:10px}.orders div{flex:1;border-radius:16px;background:#e3e6eb;padding:12px 14px}.orders div.on{background:#11141a;color:#fff}
.orders b{display:block;font-size:16px;font-weight:900}.orders small{display:block;font-size:12px;line-height:1.35;color:#4b5260;font-weight:700;margin-top:3px}.orders div.on small{color:#c3c9d3}
.orders .price{font-size:18px;font-weight:900;margin-top:8px}
""".replace("%COL%", COL)


def emb(tid, w=26):
    return f'<img src="{V.EMB.format(tid)}" width="{w}">'


def avatar(d, size=52):
    col = B.teams[d["team"]]["color"]
    if FACES:
        return (f'<span style="width:{size}px;height:{size}px;border-radius:50%;background:{col};flex:none;overflow:hidden;display:block">'
                f'<img src="file://{FACES}/{d["id"]}_face.png" style="width:100%;height:100%;object-fit:cover;display:block"></span>')
    return f'<span style="width:{size}px;height:{size}px;border-radius:50%;background:{col};flex:none;display:grid;place-items:center">{emb(d["team"], size // 2)}</span>'


def header(sub, title, chips=True):
    c = ('<span class="chip" style="margin-left:auto">CAIXA <b>US$ 61 mi</b></span>'
         '<span class="chip">COMPROMETIDO <b style="color:#ffd24a">US$ 18 mi</b></span>') if chips else ""
    return f'<div class="hd"><span class="rb">{ico("back", 24, "#eef0f3", 2.6)}</span>{emb("williams", 44)}<div><small>{sub}</small><h1>{title}</h1></div>{c}</div>'


def nav(on):
    items = ["Início", "Campeonatos", "Pessoal", "Carro", "Fábrica", "Patrocínios", "Finanças", "Conselho"]
    return '<div class="nav">' + "".join(f'<span class="{"on" if i == on else ""}">{i}</span>' for i in items) + "</div>"


def trait(label, v, col, extra=""):
    return f'<div class="trait"><span class="l">{label}</span><div class="bar"><i style="width:{v}%;background:{col}"></i>{extra}</div><b>{v}</b></div>'


def sede():
    a, s = MY[0], MY[1]
    body = f'''<div class="scene"><div class="bg"></div>
{header("WILLIAMS · SEG, 1 JUN 2026", "SEDE")}{nav("Início")}
<div class="card gp"><div class="gflag"></div><div class="in">
<div class="cap">PRÓXIMO GP · RODADA 6 DE 22 · EM 6 DIAS</div><h2>GP DE MÔNACO</h2><div class="when">Monte Carlo · dom, 7 jun · seco (chance de chuva 18%)</div>
<div class="cap" style="margin-top:16px">O QUE A PISTA PEDE</div>
{trait("Curvas lentas", 95, "#ff6a5a")}{trait("Curvas rápidas", 20, "#5c93ea")}{trait("Reta", 15, "#ffd24a")}
<div class="cap" style="margin-top:12px">SEU CARRO NESTE PERFIL</div>
<div class="est"><div><b>P11–P14</b>ritmo estimado</div><div><b>2 / 4</b>motores usados</div><div><b>Pronto</b>sem exceções</div></div>
<div class="cta">AVANÇAR COM PREPARAÇÃO RECOMENDADA {ico("chev", 20, "#fff", 3)}</div>
<div style="font-size:12px;color:#a8b0bd;margin-top:8px;font-weight:700;line-height:1.4">Recomendado: asa dianteira B no carro do Albon (a única unidade), o resto como está. Você pode revisar em <span style="color:#fff">Carro &gt; Peças</span>.</div>
<div class="cap" style="margin-top:16px">DEPOIS DE MÔNACO</div>
<div style="font-size:13px;line-height:1.85;font-weight:700;color:#c3c9d3">
<div style="display:flex;justify-content:space-between"><span>14 jun · Barcelona · equilibrada</span><span style="color:#fff">neutro</span></div>
<div style="display:flex;justify-content:space-between"><span>28 jun · Áustria · reta</span><span style="color:#7fe0b1">ponto forte</span></div></div>
</div></div>
<div class="card issues"><div class="cap">ASSUNTOS · 3</div>
<div class="is"><span class="tg tdec">DECISÃO</span><span class="go">Carro &gt; Peças {ico("chev", 12, "#8f98a7", 3)}</span>
<b>Asa dianteira B: só uma unidade antes de Mônaco</b><p>A segunda fica pronta em 12 jun (Barcelona). Ganho estimado em Mônaco: +0,15 s/volta no carro equipado.</p>
<div class="opts"><span class="rec">Estrear no ALB</span><span>Estrear no SAI</span><span>Acelerar 2ª<br>US$ 0,7 mi</span></div></div>
<div class="is"><span class="tg tnews">NOTÍCIA</span><span class="go">P&amp;D {ico("chev", 12, "#8f98a7", 3)}</span>
<b>Pesquisa concluída: assoalho v2 liberado</b><p>US$ 0,9 mi por unidade, 9 dias de fabricação. Melhora curvas rápidas (+3).</p></div>
<div class="is"><span class="tg tnews">NOTÍCIA</span><span class="go">Patrocínios {ico("chev", 12, "#8f98a7", 3)}</span>
<b>Meta da Kalto cumprida: +US$ 1,2 mi</b><p>Dois carros nos pontos no Canadá. Pago na sexta, 5 jun.</p></div>
</div>
<div class="card team"><div class="cap">EQUIPE</div>
<div style="display:flex;align-items:baseline;gap:8px;margin-top:6px"><b style="font-size:34px;font-weight:900">7º</b><span style="font-size:13px;color:#a8b0bd;font-weight:700">construtores · 22 pts</span></div>
<div class="drv">{avatar(a, 46)}<div><b>Albon</b><small>9º · 14 pts</small></div><span class="p">P9</span></div>
<div class="drv">{avatar(s, 46)}<div><b>Sainz</b><small>12º · 8 pts</small></div><span class="p">P12</span></div>
<div class="goal"><div class="cap">META DA DIRETORIA</div><div style="font-size:14px;font-weight:900;margin:4px 0 8px">Terminar em 7º ou melhor</div>
<div style="display:flex;align-items:center;gap:8px"><div class="bar"><i style="width:64%;background:#3c9d5d"></i></div><span style="font-size:12px;font-weight:900">no caminho</span></div></div>
<div class="goal"><div class="cap">FÁBRICA</div><div style="font-size:13px;color:#c3c9d3;margin-top:4px;line-height:1.4;font-weight:700"><b style="color:#fff">2 de 3</b> linhas ocupadas · asa B (2ª unidade) e assoalho v2 na fila</div></div>
</div></div>'''
    return V.page("V15 · Sede · próximo GP e assuntos", CSS, body)


def parts(modal=False):
    rows = [("AD", "#ff6a5a", "Asa dianteira", "Spec B · curvas lentas +4", "B", "A", 1, True),
            ("AT", "#5c93ea", "Asa traseira", "Spec A · baixa carga para retas", "A", "A", 2, False),
            ("AS", "#3c9d5d", "Assoalho", "Spec v2 liberada · fabricar", "v1", "v1", 0, False),
            ("SU", "#ffd24a", "Suspensão", "Spec A · tração em curva lenta", "A", "A", 1, False),
            ("UP", "#c77dff", "Unidade de potência", "Mercedes · 2 de 4 usadas", "2ª", "2ª", 1, False)]
    lst = ""
    for ab, col, nm, sub, c1, c2, stock, sel in rows:
        n1 = ' class="new"' if c1 == "B" and sel else ""
        lst += (f'<div class="prt{" sel" if sel else ""}"><span class="ic" style="background:{col}33;color:{col}">{ab}</span><div class="nm"><b>{nm}</b><small>{sub}</small></div>'
                f'<div class="car2"><span{n1}>ALB<b>{"B · nova" if sel else c1}</b></span><span>SAI<b>{c2}</b></span></div><div class="stk"><b>{stock}</b>estoque</div></div>')
    body = f'''<div class="scene"><div class="bg"></div>
{header("WILLIAMS · SEG, 1 JUN 2026", "CARRO · PEÇAS")}{nav("Carro")}
<div class="card traits"><div class="cap">CARACTERÍSTICAS DO CARRO · ALB / SAI</div>
<div style="margin-top:8px">{trait("Reta", 78, "#ffd24a")}{trait("Curvas lentas", 74, "#ff6a5a")}{trait("Curvas rápidas", 71, "#5c93ea")}{trait("Confiabilidade", 82, "#3c9d5d")}</div>
<div style="font-size:12px;color:#7fe0b1;font-weight:700;margin-top:4px">Com a asa B: curvas lentas 78 no carro do Albon</div>
<div class="cap" style="margin-top:18px">PRÓXIMOS GPS × SEU CARRO</div>
<div style="font-size:13px;line-height:1.9;margin-top:4px;font-weight:700;color:#c3c9d3">
<div style="display:flex;justify-content:space-between"><span>Mônaco · curvas lentas</span><b style="color:#ff6a5a">ponto fraco</b></div>
<div style="display:flex;justify-content:space-between"><span>Barcelona · equilibrada</span><b style="color:#fff">neutro</b></div>
<div style="display:flex;justify-content:space-between"><span>Áustria · reta</span><b style="color:#7fe0b1">ponto forte</b></div></div>
<div class="ghost" style="margin-top:16px">Ver árvore de P&amp;D</div></div>
<div class="card parts"><div class="cap">ESPECIFICAÇÕES · INSTALADAS · ESTOQUE DA FÁBRICA</div>{lst}
<div style="font-size:12px;color:#8f98a7;margin-top:10px;font-weight:700">Peça no estoque não melhora o carro: precisa ser instalada.</div></div>
<div class="card decp"><div class="cap">ASA DIANTEIRA B · ESTREIA</div>
<div style="font-size:14px;color:#c3c9d3;margin-top:6px;line-height:1.4;font-weight:700">+4 em curvas lentas · em Mônaco <span style="color:#fff">+0,15 s/volta</span> no carro equipado</div>
<div class="tl"><div class="line"></div>
<div class="gp2" style="left:130px"><small>MÔNACO</small></div><div class="gp2" style="left:250px"><small>BARCELONA</small></div>
<div class="u" style="left:60px"><small>1ª · 4 jun</small></div><div class="u" style="left:190px;background:#8f98a7"><small>2ª · 12 jun</small></div></div>
<div class="ch on"><span class="r"></span><div><b>Estrear no Albon</b><small>Sainz recebe a 2ª em Barcelona.</small></div><span class="cost">sem custo</span></div>
<div class="ch"><span class="r"></span><div><b>Estrear no Sainz</b><small>Mesma coisa, no outro carro.</small></div><span class="cost">sem custo</span></div>
<div class="ch"><span class="r"></span><div><b>Esperar as duas</b><small>Os dois estreiam em Barcelona.</small></div><span class="cost">sem custo</span></div>
<div class="ch"><span class="r"></span><div><b>Acelerar a 2ª unidade</b><small>Turno extra: pronta em 5 jun, os dois com a B em Mônaco.</small></div><span class="cost" style="color:#ffb4a8">US$ 0,7 mi</span></div>
<div class="after">Depois: caixa <span>US$ 61 mi</span> · estoque <span>0</span> · Albon <span>B</span>, Sainz <span>A</span> até 12 jun</div>
<div class="cta" style="margin-top:8px;height:50px">CONFIRMAR {ico("chev", 20, "#fff", 3)}</div></div>
{research_modal() if modal else ""}</div>'''
    return V.page("V15 · Carro · peças" + (" · pesquisa concluída" if modal else ""), CSS, body)


def research_modal():
    return f'''<div class="sheet"><div class="md"><div class="k">PESQUISA CONCLUÍDA · CHASSI</div><h2>ASSOALHO V2 LIBERADO</h2>
<p>A especificação está pronta para produzir. Melhora as <strong>curvas rápidas (+3)</strong> e o desgaste dos pneus traseiros. Enquanto não for fabricado e instalado, nada muda nos carros.</p>
<div class="facts"><div><b>US$ 0,9 mi</b>por unidade</div><div><b>9 dias</b>por unidade (1 linha livre)</div><div><b>Barcelona</b>1ª unidade pronta a tempo</div><div><b>Áustria</b>2ª unidade</div></div>
<div class="orders">
<div class="on"><b>Encomendar 2 unidades</b><small>Uma para cada carro. A 2ª fica na fila depois da 1ª.</small><div class="price">US$ 1,8 mi</div></div>
<div><b>Encomendar 1 unidade</b><small>Estreia em um carro; a segunda pode ser pedida depois.</small><div class="price">US$ 0,9 mi</div></div>
<div><b>Depois</b><small>A especificação fica liberada; dá para fabricar quando quiser.</small><div class="price">—</div></div></div>
<div style="display:flex;align-items:center;margin-top:18px"><span style="font-size:13px;color:#4b5260;font-weight:700">Caixa depois: US$ 59,2 mi · comprometido: US$ 19,8 mi</span>
<div class="cta" style="margin-left:auto;width:220px">CONFIRMAR {ico("chev", 20, "#fff", 3)}</div></div></div></div>'''


if __name__ == "__main__":
    out = pathlib.Path(os.environ["V15_OUT"]) if os.environ.get("V15_OUT") else HERE
    if FACES:
        B.FONTS = B.FONTS.replace("url(fonts/", f"url(file://{(HERE / 'fonts').resolve()}/")
        V.EMB = "file://" + str((HERE / "../../game/assets/emblems").resolve()) + "/{}.svg"
    (out / "v15-1-sede.html").write_text(sede(), encoding="utf-8")
    (out / "v15-2-carro-pecas.html").write_text(parts(), encoding="utf-8")
    (out / "v15-3-pesquisa-concluida.html").write_text(parts(True), encoding="utf-8")
    print("ok")
