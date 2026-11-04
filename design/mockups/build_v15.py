"""V15 · Campanha reestruturada (prompt mestre, decisões de 2026-11-04) — passo 1.
Uso: python design/mockups/build_v15.py   (gera v15-*.html nesta pasta; V15_FACES=<pasta> e V15_OUT=<pasta> para a versão com fotos locais)
1) Sede: próximo GP com o perfil da pista, até 3 assuntos (NOTÍCIA × DECISÃO) e "avançar com preparação recomendada".
2) Carro > Peças: 4 características do carro × perfil da pista, estoque e instalação por carro, decisão de estrear uma peça.
3) Pesquisa concluída: especificação liberada, custo por unidade e para qual GP cada unidade fica pronta.
Equipe de exemplo: Williams. Datas, custos e ganhos são EXEMPLOS coerentes com o jogo (valores provisórios).
"""
import math
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
.orders{display:flex;gap:10px}.orders>div{flex:1;border-radius:16px;background:#e3e6eb;padding:12px 14px}.orders>div.on{background:#11141a;color:#fff}
.orders b{display:block;font-size:16px;font-weight:900}.orders small{display:block;font-size:12px;line-height:1.35;color:#4b5260;font-weight:700;margin-top:3px}.orders>div.on small{color:#c3c9d3}
.orders .price{font-size:18px;font-weight:900;margin-top:8px}
/* carro interativo (v15-2) */
.stage{position:absolute;left:36px;top:140px;width:820px;height:562px;border-radius:24px;background:radial-gradient(ellipse 60% 55% at 50% 48%,%COL%40,rgba(255,255,255,.03) 70%);overflow:hidden}
.stage:before{content:"";position:absolute;left:0;right:0;bottom:0;height:120px;background:linear-gradient(transparent,rgba(0,0,0,.35))}
.stage .topcar{position:absolute;left:70px;top:150px}
.stage .sel2{position:absolute;left:18px;top:16px;display:flex;gap:6px;background:rgba(0,0,0,.35);border-radius:22px;padding:4px}
.stage .sel2 span{height:38px;padding:0 14px 0 4px;border-radius:19px;display:flex;align-items:center;gap:8px;font-size:14px;font-weight:900;color:#c3c9d3}
.stage .sel2 span.on{background:#f3f4f6;color:#11141a}
.stage .hint{position:absolute;right:20px;top:28px;font-size:12px;color:#a8b0bd;font-weight:700}
.co{position:absolute;display:flex;align-items:center;gap:8px;border-radius:14px;background:rgba(10,12,16,.9);padding:7px 12px 7px 7px;white-space:nowrap;border:1px solid rgba(255,255,255,.1);min-height:44px}
.co .n{width:28px;height:28px;border-radius:50%;display:grid;place-items:center;font-size:13px;font-weight:900;color:#11141a;flex:none}
.co strong{display:block;font-size:14px;font-weight:900;line-height:1.1}.co small{display:block;font-size:12px;color:#a8b0bd;font-weight:700}
.co.on{background:#f3f4f6;color:#11141a;border-color:#fff;box-shadow:0 0 0 3px %COL%,0 8px 24px rgba(0,0,0,.5)}.co.on small{color:#4b5260}
.co .al{font-size:10px;letter-spacing:1px;font-weight:900;background:#E10600;color:#fff;border-radius:6px;padding:2px 6px;margin-left:6px;vertical-align:2px}
.co .al.y{background:#ffd24a;color:#11141a}
.lead{position:absolute;height:2px;background:rgba(255,255,255,.5);transform-origin:0 50%}
.pin{position:absolute;width:16px;height:16px;border-radius:50%;border:3px solid #fff;background:#0b0c0f;transform:translate(-50%,-50%)}
.pin.on{background:#E10600;box-shadow:0 0 0 7px rgba(225,6,0,.3)}
.strip{position:absolute;left:18px;right:18px;bottom:14px;display:flex;gap:10px}
.strip>div{flex:1;border-radius:14px;background:rgba(0,0,0,.45);padding:8px 12px;line-height:1.15}
.strip .cap{font-size:10px}.strip strong{font-size:22px;font-weight:900}.strip i{font-style:normal;font-size:12px;font-weight:900;margin-left:6px}
.panel{position:absolute;left:872px;top:140px;width:372px;height:562px;border-radius:24px;background:rgba(255,255,255,.07);padding:16px 18px;box-sizing:border-box}
.panel h3{font-size:22px;font-weight:900;line-height:1.05;margin:4px 0 2px}
.panel .ds{font-size:12px;color:#a8b0bd;font-weight:700}
.tabs{display:flex;gap:4px;background:rgba(0,0,0,.3);border-radius:22px;padding:4px;margin:8px 0}
.tabs span{flex:1;height:38px;border-radius:19px;display:flex;align-items:center;justify-content:center;font-size:14px;font-weight:900;color:#c3c9d3}.tabs span.on{background:#f3f4f6;color:#11141a}
.unit{display:flex;align-items:center;gap:10px;border-radius:13px;background:rgba(0,0,0,.25);padding:5px 10px;margin-top:5px}
.unit .sp{width:32px;height:32px;border-radius:10px;display:grid;place-items:center;font-weight:900;font-size:15px;flex:none}
.unit strong{display:block;font-size:13px;font-weight:900}.unit small{display:block;font-size:12px;color:#a8b0bd;font-weight:700}
.unit .w{margin-left:auto;width:58px;flex:none}.unit .w .bar{height:6px}.unit .w small{text-align:right}
.panel .ch{padding:8px 10px;margin-top:6px}
.dir{border-radius:14px;background:rgba(255,255,255,.07);padding:9px 12px;margin-top:6px}
.dir.on{background:#f3f4f6;color:#11141a}.dir.on small{color:#4b5260}
.dir strong{display:block;font-size:14px;font-weight:900}.dir small{display:block;font-size:12px;color:#a8b0bd;font-weight:700;line-height:1.3}
.dir .fx{display:flex;gap:5px;margin-top:5px;flex-wrap:wrap}.dir .fx span{font-size:12px;font-weight:900;border-radius:7px;padding:1px 7px;background:rgba(57,211,107,.2);color:#2a8a4c}
.dir .fx span.neg{background:rgba(225,6,0,.15);color:#c0392b}.dir:not(.on) .fx span{color:#7fe0b1}.dir:not(.on) .fx span.neg{color:#ff8a80}
.dir .ct{display:flex;justify-content:space-between;margin-top:5px;font-size:12px;font-weight:900}
.odds{border-radius:14px;background:rgba(0,0,0,.28);padding:8px 12px;margin-top:8px}
.odds .cap{font-size:10px}
.odds .row{display:flex;justify-content:space-between;font-size:12px;font-weight:700;color:#c3c9d3;line-height:1.6}
.odds .row span:last-child{font-weight:900;color:#fff}
.odds .meter{display:flex;height:10px;border-radius:5px;overflow:hidden;margin:6px 0 4px}
.odds .meter i{display:block;height:100%}
.odds .leg{display:flex;gap:10px;font-size:12px;font-weight:700;color:#a8b0bd}
.md.bad:before{background:#E10600}
/* v15-2: painéis com símbolos */
.gl{display:inline-block;vertical-align:middle;flex:none}
.co .n{color:#11141a}
.strip>div{display:flex;align-items:center;gap:10px}
.strip div .tx{line-height:1.05}
.strip small{display:block;font-size:11px;color:#a8b0bd;font-weight:700}
.tiles{display:flex;gap:8px;margin-top:6px}
.tile{flex:1;min-width:0;border-radius:14px;background:rgba(0,0,0,.28);padding:8px 6px;display:flex;flex-direction:column;align-items:center;gap:4px;text-align:center;position:relative}
.tile.on{background:#f3f4f6;color:#11141a;box-shadow:0 0 0 3px %COL%}
.tile .lb{font-size:12px;font-weight:900;line-height:1.15}
.tile .sb{font-size:11px;font-weight:700;color:#a8b0bd;line-height:1.2}.tile.on .sb{color:#4b5260}
.ring{position:relative;width:52px;height:52px}.ring svg{position:absolute;inset:0}
.ring span{position:absolute;inset:0;display:grid;place-items:center;font-size:20px;font-weight:900}
.loc{display:flex;align-items:center;gap:5px;font-size:12px;font-weight:900}
.give{display:flex;align-items:center;gap:4px;height:44px}
.give .sp{width:34px;height:34px;border-radius:10px;display:grid;place-items:center;font-weight:900;font-size:16px;background:#ff6a5a33;color:#ff6a5a}
.chipc{font-size:11px;font-weight:900;border-radius:7px;padding:2px 7px;background:rgba(57,211,107,.18);color:#7fe0b1}
.tile.on .chipc{color:#2a8a4c}.chipc.money{background:rgba(255,180,168,.18);color:#ffb4a8}
.fxl{display:flex;flex-direction:column;gap:3px;align-self:stretch;padding:0 4px}
.fxl div{display:flex;align-items:center;justify-content:space-between;font-size:13px;font-weight:900}
.up{color:#7fe0b1}.dn{color:#ff8a80}.tile.on .up{color:#2a8a4c}.tile.on .dn{color:#c0392b}
.meta{display:flex;flex-direction:column;gap:3px;align-self:stretch;border-top:1px solid rgba(128,128,128,.25);padding:5px 4px 0;font-size:12px;font-weight:900}
.meta div{display:flex;align-items:center;gap:5px}
.who{display:flex;gap:8px;margin-bottom:6px}
.who>div{flex:1;display:flex;align-items:center;gap:8px;border-radius:12px;background:rgba(255,255,255,.06);padding:6px 8px}
.who .av{width:30px;height:30px;border-radius:50%;background:#5c93ea;display:grid;place-items:center;font-size:11px;font-weight:900;color:#11141a;flex:none}
.who strong{display:block;font-size:15px;font-weight:900;line-height:1}.who small{display:block;font-size:11px;color:#a8b0bd;font-weight:700}
.dots{display:flex;gap:3px;margin-top:3px}.dots i{width:9px;height:9px;border-radius:3px;background:rgba(255,255,255,.18)}.dots i.f{background:#ffd24a}
.leg2{display:flex;justify-content:space-between;font-size:12px;font-weight:900;margin-top:2px}
.leg2 span{display:flex;align-items:center;gap:4px}
.after2{display:flex;align-items:center;gap:8px;font-size:12px;font-weight:700;color:#a8b0bd;margin-top:10px}
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


def top_car(c1, c2):
    """Carro visto de cima (arte original nas cores da equipe). Bico para a direita. 680 x 260."""
    tyre = lambda x, y, w, h: (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" fill="#121316"/>'
                               f'<rect x="{x + 8}" y="{y + 6}" width="{w - 16}" height="3" fill="#2b2f36"/><rect x="{x + 8}" y="{y + h - 9}" width="{w - 16}" height="3" fill="#2b2f36"/>')
    return f"""<svg class="topcar" width="680" height="260" viewBox="0 0 680 260">
<defs><linearGradient id="tb" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".28"/><stop offset=".5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".35"/></linearGradient></defs>
<ellipse cx="340" cy="132" rx="330" ry="56" fill="#000" opacity=".4"/>
<path d="M150 98 L142 62 M175 100 L160 62 M150 162 L142 198 M175 160 L160 198 M520 118 L572 64 M556 120 L592 64 M520 142 L572 196 M556 140 L592 196" stroke="#3a3f48" stroke-width="5" stroke-linecap="round"/>
{tyre(100, 18, 96, 52)}{tyre(100, 190, 96, 52)}{tyre(546, 24, 76, 44)}{tyre(546, 192, 76, 44)}
<path d="M176 60 L430 72 L470 96 L470 164 L430 188 L176 200 Q160 190 160 176 L160 84 Q160 70 176 60 Z" fill="#15171b"/>
<rect x="56" y="112" width="60" height="36" rx="6" fill="#1d2026"/>
<path d="M70 116 L150 110 L192 96 Q232 72 300 70 L392 74 Q424 78 446 98 L476 112 L560 118 L652 124 L664 130 L652 136 L560 142 L476 148 L446 162 Q424 182 392 186 L300 190 Q232 188 192 164 L150 150 L70 144 Z" fill="{c1}"/>
<path d="M70 116 L150 110 L192 96 Q232 72 300 70 L392 74 Q424 78 446 98 L476 112 L560 118 L652 124 L664 130 L652 136 L560 142 L476 148 L446 162 Q424 182 392 186 L300 190 Q232 188 192 164 L150 150 L70 144 Z" fill="url(#tb)"/>
<path d="M96 125 L340 116 L446 120 L446 140 L340 144 L96 135 Z" fill="{c2}" opacity=".9"/>
<path d="M380 80 Q410 82 428 98 L396 98 Z M380 180 Q410 178 428 162 L396 162 Z" fill="#0d0e11"/>
<ellipse cx="478" cy="130" rx="34" ry="15" fill="#0d0e11"/><circle cx="470" cy="130" r="9" fill="{c2}"/>
<path d="M444 130 Q476 100 510 130" stroke="#d9dde3" stroke-width="5" fill="none"/><path d="M508 130 L530 130" stroke="#d9dde3" stroke-width="4"/>
<rect x="20" y="70" width="44" height="120" rx="5" fill="{c1}"/><rect x="26" y="70" width="10" height="120" fill="{c2}" opacity=".85"/>
<rect x="16" y="64" width="52" height="8" rx="3" fill="#1d2026"/><rect x="16" y="188" width="52" height="8" rx="3" fill="#1d2026"/>
<rect x="632" y="30" width="10" height="200" rx="4" fill="{c1}"/><rect x="645" y="36" width="8" height="188" rx="4" fill="{c2}"/><rect x="656" y="44" width="6" height="172" rx="3" fill="{c1}"/>
<rect x="628" y="24" width="38" height="8" rx="3" fill="#1d2026"/><rect x="628" y="228" width="38" height="8" rx="3" fill="#1d2026"/>
</svg>"""


GLYPHS = {  # símbolos desenhados (traço), 24 x 24
    "fwing": "M2 7h20M4 12h16M7 17h10",
    "rwing": "M3 5h18v5H3zM8 10v9M16 10v9",
    "floor": "M2 16 5 8h14l3 8zM6 16v3M18 16v3",
    "susp": "M3 19 12 6l9 13M7 13h10",
    "pu": "M13 2 4 14h7l-1 8 9-12h-7z",
    "gear": "M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8zM12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M5 19l2-2M17 7l2-2",
    "reta": "M3 12h15M13 6l6 6-6 6",
    "lenta": "M6 21V10a6 6 0 0 1 12 0v4M14 11l4 4 4-4",
    "rapida": "M4 20Q4 6 18 5M14 2l4 3-3 4",
    "conf": "M12 3 20 6v6q0 6-8 9-8-3-8-9V6zM8.5 12l2.5 2.5 4.5-5",
    "money": "M12 2v20M17 6.5Q15 4 12 4 7 4 7 8t5 4 5 4-5 4q-3 0-5-2.5",
    "clock": "M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18zM12 7v5l3 3",
    "flagc": "M5 21V4h13l-3 4 3 4H5",
    "box": "M3 8 12 3l9 5v9l-9 5-9-5zM3 8l9 5 9-5M12 13v9",
    "fact": "M2 21V10l6 4V10l6 4V6l8 5v10z",
    "ok": "M5 12l5 5 9-10",
    "mid": "M5 12h14",
    "bad": "M6 6l12 12M18 6 6 18",
    "bolt": "M13 2 4 14h7l-1 8 9-12h-7z",
    "arrow": "M4 12h14M13 6l6 6-6 6",
}


def gl(name, size=18, col="currentColor", w=2.4):
    return (f'<svg class="gl" width="{size}" height="{size}" viewBox="0 0 24 24" fill="none" stroke="{col}" stroke-width="{w}" '
            f'stroke-linecap="round" stroke-linejoin="round"><path d="{GLYPHS[name]}"/></svg>')


def ring(letter, pct, col):
    c = 2 * math.pi * 22
    return (f'<div class="ring"><svg width="52" height="52"><circle cx="26" cy="26" r="22" stroke="rgba(128,128,128,.25)" stroke-width="5" fill="none"/>'
            f'<circle cx="26" cy="26" r="22" stroke="{col}" stroke-width="5" fill="none" stroke-linecap="round" stroke-dasharray="{c * pct / 100:.1f} {c:.1f}" transform="rotate(-90 26 26)"/></svg><span>{letter}</span></div>')


def callout(glyph, col, title, sub, x, y, px, py, on=False, alert=""):
    """Etiqueta da peça em (x, y), ligada por uma linha ao ponto (px, py) do carro."""
    cx, cy = x + 22, y + 22
    ln, ang = math.hypot(px - cx, py - cy), math.degrees(math.atan2(py - cy, px - cx))
    al = f'<span class="al{" y" if alert == "DESGASTE" else ""}">{alert}</span>' if alert else ""
    return (f'<div class="lead" style="left:{cx}px;top:{cy}px;width:{ln:.0f}px;transform:rotate({ang:.1f}deg)"></div>'
            f'<div class="pin{" on" if on else ""}" style="left:{px}px;top:{py}px"></div>'
            f'<div class="co{" on" if on else ""}" style="left:{x}px;top:{y}px"><span class="n" style="background:{col}">{gl(glyph, 16, "#11141a", 2.6)}</span>'
            f'<div><strong>{title}{al}</strong><small>{sub}</small></div></div>')


def stage(sel):
    a, s = MY[0], MY[1]
    ox, oy = 70, 150  # posição do carro no palco
    cos = (callout("fwing", "#ff6a5a", "Asa dianteira", "B nova · 1 no estoque", 556, 62, ox + 637, oy + 70, sel == 1, "NOVA")
           + callout("rwing", "#5c93ea", "Asa traseira", "Spec A · baixa carga", 24, 74, ox + 42, oy + 92, sel == 2)
           + callout("floor", "#3c9d5d", "Assoalho", "v1 · v2 em pesquisa", 262, 62, ox + 250, oy + 66, sel == 3)
           + callout("susp", "#ffd24a", "Suspensão", "Spec A · 1 no estoque", 560, 436, ox + 566, oy + 170, sel == 4)
           + callout("pu", "#c77dff", "Unidade de potência", "Mercedes · 2ª de 4", 262, 444, ox + 290, oy + 140, sel == 5)
           + callout("gear", "#8f98a7", "Câmbio", "2ª de 4 · desgaste 40%", 24, 420, ox + 84, oy + 130, sel == 6, "DESGASTE"))
    strip = "".join(f'<div>{gl(g, 26, c)}<div class="tx"><strong>{v}</strong><small>{k}{d}</small></div></div>' for g, c, k, v, d in
                    [("reta", "#ffd24a", "reta", 78, ""), ("lenta", "#ff6a5a", "curvas lentas", 74, ' <span style="color:#7fe0b1">▲78</span>'),
                     ("rapida", "#5c93ea", "curvas rápidas", 71, ""), ("conf", "#3c9d5d", "confiabilidade", 82, "")])
    return (f'<div class="stage"><div class="sel2"><span class="on">{avatar(a, 30)}Albon · 23</span><span>{avatar(s, 30)}Sainz · 55</span></div>'
            f'<div class="hint">Toque numa peça</div>{top_car(COL, TEAM["color2"])}{cos}<div class="strip">{strip}</div></div>')


def panel_head(n, glyph, col, area, name, desc, tab):
    return (f'<div class="panel"><div style="display:flex;align-items:center;gap:12px"><span class="n" style="width:44px;height:44px;border-radius:14px;background:{col};display:grid;place-items:center;flex:none">{gl(glyph, 26, "#11141a", 2.6)}</span>'
            f'<div><div class="cap">PEÇA {n} · {area}</div><h3>{name}</h3></div></div>{f'<div class="ds" style="margin-top:6px">{desc}</div>' if desc else ""}'
            f'<div class="tabs"><span class="{"on" if tab == "use" else ""}">{gl("box", 16)}&nbsp; Usar</span><span class="{"on" if tab == "dev" else ""}">{gl("fact", 16)}&nbsp; Desenvolver</span></div>')


def panel_use():
    a, s = MY[0], MY[1]
    units = (f'<div class="tile">{ring("B", 100, "#3c9d5d")}<div class="loc">{gl("box", 16, "#a8b0bd")} estoque</div><div class="sb">nova</div></div>'
             f'<div class="tile">{ring("A", 62, "#ffd24a")}<div class="loc">{avatar(a, 20)} Albon</div><div class="sb">62% · 6 GPs</div></div>'
             f'<div class="tile">{ring("A", 70, "#ffd24a")}<div class="loc">{avatar(s, 20)} Sainz</div><div class="sb">70% · 6 GPs</div></div>')
    give = lambda d: f'<div class="give"><span class="sp">B</span>{gl("arrow", 16)}{avatar(d, 34)}</div>'
    opts = (f'<div class="tile on">{give(a)}<div class="lb">B no Albon</div><span class="chipc">grátis</span></div>'
            f'<div class="tile">{give(s)}<div class="lb">B no Sainz</div><span class="chipc">grátis</span></div>'
            f'<div class="tile"><div class="give">{gl("bolt", 30, "#ffd24a")}<span class="sp">B</span><span class="sp">B</span></div><div class="lb">Os dois</div><span class="chipc money">US$ 0,7 mi</span></div>')
    return (panel_head(1, "fwing", "#ff6a5a", "AERODINÂMICA", "ASA DIANTEIRA", "", "use")
            + f'<div class="cap">UNIDADES · DESGASTE</div><div class="tiles">{units}</div>'
            + f'<div class="cap" style="margin-top:10px;display:flex;align-items:center;gap:6px">{gl("flagc", 14)} MÔNACO · 7 JUN</div><div class="tiles">{opts}</div>'
            + f'<div class="after2">{gl("clock", 16)} 2ª unidade da B pronta em 12 jun (Barcelona)</div>'
            + f'<div class="cta" style="margin-top:10px;height:50px">CONFIRMAR {ico("chev", 20, "#fff", 3)}</div></div>')


def panel_dev():
    def d(name, fx, money, days, gp, on=False):
        rows = "".join(f'<div>{gl(g, 18)}<span class="{"up" if v > 0 else "dn"}">{"▲" if v > 0 else "▼"} {abs(v)}</span></div>' for g, v in fx)
        return (f'<div class="tile{" on" if on else ""}"><div class="lb">{name}</div><div class="fxl">{rows}</div>'
                f'<div class="meta"><div>{gl("money", 14)} {money}</div><div>{gl("clock", 14)} {days} dias</div><div>{gl("flagc", 14)} {gp}</div></div></div>')
    dirs = (d("Alta carga", [("lenta", 4), ("reta", -2)], "2,4 mi", 18, "Hungria", True)
            + d("Baixa carga", [("reta", 4), ("lenta", -1)], "2,1 mi", 16, "Áustria")
            + d("Ousada", [("lenta", 6), ("rapida", 2)], "3,2 mi", 24, "Bélgica"))
    who = (f'<div class="who"><div><span class="av">AK</span><div><strong>80</strong><small>chefe de aero</small></div></div>'
           f'<div>{gl("fact", 26, "#ffd24a")}<div><strong>Túnel</strong><div class="dots"><i class="f"></i><i class="f"></i><i class="f"></i><i></i><i></i></div></div></div></div>')
    meter = ('<div class="odds" style="margin-top:6px"><div class="cap">CHANCE DE O UPGRADE FUNCIONAR</div>' + who
             + '<div class="meter"><i style="width:64%;background:#3c9d5d"></i><i style="width:26%;background:#ffd24a"></i><i style="width:10%;background:#E10600"></i></div>'
             + f'<div class="leg2"><span style="color:#7fe0b1">{gl("ok", 14)} 64%</span><span style="color:#ffd24a">{gl("mid", 14)} 26% ganho menor</span><span style="color:#ff8a80">{gl("bad", 14)} 10% piora</span></div></div>')
    return (panel_head(2, "rwing", "#5c93ea", "AERODINÂMICA", "ASA TRASEIRA", "", "dev")
            + f'<div class="tiles">{dirs}</div>{meter}'
            + f'<div class="cta" style="margin-top:10px;height:50px">INICIAR PESQUISA {ico("chev", 20, "#fff", 3)}</div></div>')


def parts(modal="", tab="use"):
    pnl = panel_use() if tab == "use" else panel_dev()
    sel = 1 if tab == "use" else 2
    md = research_modal() if modal == "good" else (bad_modal() if modal == "bad" else "")
    title = {"": "", "good": " · pesquisa concluída", "bad": " · upgrade falhou"}[modal]
    body = f"""<div class="scene"><div class="bg"></div>
{header("WILLIAMS · SEG, 1 JUN 2026", "CARRO · PEÇAS")}{nav("Carro")}{stage(sel)}{pnl}
{md}</div>"""
    return V.page("V15 · Carro · peças" + title, CSS, body)


def bad_modal():
    return f"""<div class="sheet"><div class="md bad"><div class="k">PRIMEIRA CORRIDA COM A PEÇA · MÔNACO</div><h2>A ASA DIANTEIRA B NÃO FUNCIONOU</h2>
<p>No túnel de vento ela prometia <strong>+4 em curvas lentas</strong>. Na pista, os dados mostram <strong>−1</strong>: o fluxo descola na saída das curvas e o carro do Albon ficou instável. A correlação entre túnel e pista falhou.</p>
<div class="facts"><div><b>+4 → −1</b>curvas lentas (esperado → real)</div><div><b>Kenyon 80</b>chefe de aerodinâmica</div><div><b>Túnel nível 3</b>quanto melhor, menos erros assim</div><div><b>US$ 2,1 mi</b>já gastos</div></div>
<div class="orders">
<div class="on"><b>Voltar para a Spec A</b><small>Volta ao carro antigo já em Barcelona. A B fica guardada.</small><div class="price">grátis</div></div>
<div><b>Corrigir a B</b><small>Pesquisa curta (9 dias) para recuperar o ganho. Pode dar certo ou não.</small><div class="price">US$ 0,8 mi</div></div>
<div><b>Manter e testar</b><small>Mais dados nos treinos de Barcelona antes de decidir.</small><div class="price">—</div></div></div>
<div style="display:flex;align-items:center;margin-top:18px"><span style="font-size:13px;color:#4b5260;font-weight:700">Isso também acontece com as rivais: veja o radar de upgrades em Campeonatos.</span>
<div class="cta" style="margin-left:auto;width:220px">CONFIRMAR {ico("chev", 20, "#fff", 3)}</div></div></div></div>"""


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
    (out / "v15-2b-carro-desenvolver.html").write_text(parts(tab="dev"), encoding="utf-8")
    (out / "v15-3-pesquisa-concluida.html").write_text(parts("good", "dev"), encoding="utf-8")
    (out / "v15-4-upgrade-falhou.html").write_text(parts("bad"), encoding="utf-8")
    print("ok")
