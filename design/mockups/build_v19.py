"""V19 · Item 5 da fila (2026-11-04): teto de gastos (trava rígida), restrição de túnel de vento pela posição do ano
anterior, empréstimo do banco e adiantamento de patrocínio. Base: a tela de Finanças atual (Garagem).
Uso: python design/mockups/build_v19.py
"""
import os
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402

HERE = B.HERE
ico = V.ico

CSS = V.G_CSS + """
.scene{background:#0b0c0f}
.bg{position:absolute;inset:0;background:radial-gradient(ellipse 60% 70% at 60% 40%,#1b2a55,#0b0c0f 72%)}
.hd{position:absolute;left:44px;top:22px;right:44px;display:flex;align-items:center;gap:14px}
.rb{width:52px;height:52px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center}
.hd h1{font-size:28px;font-weight:900;line-height:1}.hd small{display:block;font-size:12px;letter-spacing:3px;color:#8f98a7;font-weight:900}
.chip{height:44px;border-radius:22px;background:rgba(255,255,255,.08);display:flex;align-items:center;gap:8px;padding:0 18px;font-size:12px;letter-spacing:2px;color:#8f98a7;font-weight:900}
.chip b{font-size:17px;letter-spacing:0;color:#fff}
.nav{position:absolute;left:44px;top:90px;display:flex;gap:4px;background:rgba(255,255,255,.06);border-radius:26px;padding:4px}
.nav span{height:44px;padding:0 16px;border-radius:22px;display:grid;place-items:center;font-weight:800;font-size:16px;color:#eef0f3}.nav span.on{background:#f3f4f6;color:#11141a}
.card{position:absolute;border-radius:22px;background:rgba(255,255,255,.06);padding:16px 20px}
.cap{font-size:12px;letter-spacing:3px;color:#8f98a7;font-weight:900}
.row{display:flex;align-items:center;gap:10px;height:32px;font-size:16px;font-weight:800}
.row .bar{flex:1;height:10px;border-radius:5px;background:rgba(255,255,255,.1);overflow:hidden}.row .bar i{display:block;height:100%}
.row b{width:96px;text-align:right;font-weight:900}
.cap-meter{position:relative;height:26px;border-radius:13px;background:rgba(255,255,255,.08);overflow:hidden;margin-top:12px}
.cap-meter i{position:absolute;top:0;bottom:0}
.cap-meter .lim{position:absolute;right:0;top:-4px;bottom:-4px;width:3px;background:#E10600}
.big{font-size:30px;font-weight:900;line-height:1}.big small{font-size:14px;color:#a8b0bd;font-weight:800;margin-left:6px}
.leg{display:flex;gap:14px;margin-top:8px;font-size:12px;font-weight:800;color:#c3c9d3}.leg span{display:flex;align-items:center;gap:6px}.leg i{width:10px;height:10px;border-radius:3px;display:block}
.lock{display:flex;align-items:center;gap:8px;margin-top:10px;border-radius:12px;background:rgba(225,6,0,.14);padding:8px 12px;font-size:13px;font-weight:800;color:#ffb4a8}
.out{font-size:12px;color:#8f98a7;font-weight:700;margin-top:8px;line-height:1.4}
.loan{display:flex;align-items:center;gap:12px;border-radius:16px;background:rgba(0,0,0,.25);padding:10px 12px;margin-top:8px}
.loan .lic{width:44px;height:44px;border-radius:14px;display:grid;place-items:center;flex:none}
.loan strong{display:block;font-size:16px;font-weight:900}.loan small{display:block;font-size:12px;color:#a8b0bd;font-weight:700}
.loan .v{margin-left:auto;text-align:right}.loan .v b{display:block;font-size:17px;font-weight:900}.loan .v small{color:#ffb4a8}
.btn{height:46px;border-radius:23px;background:#f3f4f6;color:#11141a;display:flex;align-items:center;justify-content:center;gap:8px;font-weight:900;font-size:15px;margin-top:10px}
.atr{display:flex;align-items:center;gap:10px;border-radius:14px;background:rgba(92,147,234,.14);padding:10px 12px;margin-top:10px}
.atr b{font-size:22px;font-weight:900;color:#5c93ea}.atr small{display:block;font-size:12px;color:#c3c9d3;font-weight:700;line-height:1.3}
/* folha */
.dim{position:absolute;inset:0;background:rgba(0,0,0,.62)}
.sheet{position:absolute;left:250px;top:90px;width:780px;border-radius:24px;background:#17191e;padding:24px 28px}
.sheet h2{font-size:28px;font-weight:900}
.tabs{display:flex;gap:4px;background:rgba(0,0,0,.35);border-radius:24px;padding:4px;margin:14px 0}
.tabs span{flex:1;height:48px;border-radius:22px;display:flex;align-items:center;justify-content:center;gap:8px;font-weight:900;font-size:15px;color:#c3c9d3}.tabs span.on{background:#f3f4f6;color:#11141a}
.amt{display:flex;align-items:center;gap:16px}
.amt .val{font-size:44px;font-weight:900}
.slider{flex:1;height:10px;border-radius:5px;background:rgba(255,255,255,.12);position:relative}
.slider i{position:absolute;left:0;top:0;bottom:0;width:45%;border-radius:5px;background:#E10600}
.slider b{position:absolute;left:45%;top:50%;width:28px;height:28px;border-radius:50%;background:#fff;transform:translate(-50%,-50%);box-shadow:0 4px 12px rgba(0,0,0,.5)}
.terms{display:flex;gap:10px;margin-top:16px}
.terms div{flex:1;border-radius:16px;background:rgba(255,255,255,.06);padding:12px 14px}
.terms div.on{background:#f3f4f6;color:#11141a}.terms div.on small{color:#4b5260}
.terms strong{display:block;font-size:18px;font-weight:900}.terms small{display:block;font-size:12px;color:#a8b0bd;font-weight:700;margin-top:2px}
.facts{display:flex;gap:10px;margin-top:16px}
.facts div{flex:1;border-radius:14px;background:rgba(0,0,0,.3);padding:10px 14px}
.facts b{display:block;font-size:20px;font-weight:900}.facts small{font-size:12px;color:#a8b0bd;font-weight:700}
.warn{display:flex;align-items:center;gap:8px;margin-top:14px;font-size:13px;color:#ffd24a;font-weight:800}
.cta{height:58px;width:300px;margin:16px 0 0 auto;background:#E10600;color:#fff;font-weight:900;font-size:19px;display:flex;align-items:center;justify-content:center;gap:10px;
 clip-path:polygon(0 0,calc(100% - 18px) 0,100% 18px,100% 100%,0 100%);border-radius:14px 0 14px 14px}
"""

G = {
    "bank": '<path d="M3 10l9-6 9 6M5 10v8M9 10v8M15 10v8M19 10v8M3 20h18"/>',
    "hand": '<path d="M3 13h4l4 3h6a2 2 0 0 0 0-4h-4M7 13V9l5-3 4 3"/><circle cx="17" cy="5" r="2"/>',
    "lock": '<rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
    "wind": '<path d="M3 8h11a3 3 0 1 0-3-3M3 12h16a3 3 0 1 1-3 3M3 16h8"/>',
    "warn": '<path d="M12 3l10 18H2zM12 10v5M12 18h.01"/>',
}


def g(n, s=20, c="currentColor", w=2.2):
    return f'<svg width="{s}" height="{s}" viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round" style="flex:none">{G[n]}</svg>'


def frame(body_extra):
    nav = "".join(f'<span class="{"on" if n == "Finanças" else ""}">{n}</span>' for n in ["Início", "Campeonatos", "Pessoal", "Carro", "Design", "Fábrica", "Patrocínios", "Finanças", "Conselho"])
    left = '''<div class="card" style="left:44px;top:150px;width:520px;height:250px"><div class="cap">RECEITAS · TEMPORADA 2026</div>
<div class="row" style="margin-top:8px">Patrocínios<div class="bar"><i style="width:70%;background:#3c9d5d"></i></div><b>US$ 33,0 mi</b></div>
<div class="row">Bônus de resultado<div class="bar"><i style="width:14%;background:#3c9d5d"></i></div><b>US$ 4,2 mi</b></div>
<div class="row">Empréstimo do banco<div class="bar"><i style="width:40%;background:#5c93ea"></i></div><b>US$ 20,0 mi</b></div>
<div class="row" style="margin-top:6px;color:#a8b0bd">Receitas até agora<span style="margin-left:auto;font-size:24px;font-weight:900;color:#7fe0b1">US$ 57,2 mi</span></div></div>
<div class="card" style="left:44px;top:412px;width:520px;height:288px"><div class="cap">DESPESAS · TEMPORADA 2026</div>
<div class="row" style="margin-top:8px">Corridas e operação<span style="margin-left:6px;font-size:10px;letter-spacing:1px;color:#ffd24a">TETO</span><div class="bar"><i style="width:55%;background:#ff6a5a"></i></div><b>US$ 30,8 mi</b></div>
<div class="row">Manutenção da fábrica<span style="margin-left:6px;font-size:10px;letter-spacing:1px;color:#ffd24a">TETO</span><div class="bar"><i style="width:22%;background:#ff6a5a"></i></div><b>US$ 11,6 mi</b></div>
<div class="row">P&amp;D e peças<span style="margin-left:6px;font-size:10px;letter-spacing:1px;color:#ffd24a">TETO</span><div class="bar"><i style="width:80%;background:#ff6a5a"></i></div><b>US$ 66,1 mi</b></div>
<div class="row">Folha de pagamento<div class="bar"><i style="width:10%;background:#8f98a7"></i></div><b>US$ 5,5 mi</b></div>
<div class="row">Obras da fábrica<div class="bar"><i style="width:18%;background:#8f98a7"></i></div><b>US$ 20,0 mi</b></div>
<div class="row">Juros e parcelas<div class="bar"><i style="width:8%;background:#8f98a7"></i></div><b>US$ 4,0 mi</b></div></div>'''
    cap = f'''<div class="card" style="left:580px;top:150px;width:656px;height:250px"><div class="cap">TETO DE GASTOS 2026 · IGUAL PARA TODAS AS EQUIPES</div>
<div style="display:flex;align-items:baseline;justify-content:space-between;margin-top:10px"><div class="big">US$ 108,5 mi<small>gastos de US$ 150 mi</small></div>
<div class="big" style="font-size:22px;color:#7fe0b1">US$ 41,5 mi<small>livres</small></div></div>
<div class="cap-meter"><i style="left:0;width:20.5%;background:#ff6a5a"></i><i style="left:20.5%;width:7.7%;background:#ffb4a8"></i><i style="left:28.2%;width:44%;background:#c77dff"></i><div class="lim"></div></div>
<div class="leg"><span><i style="background:#ff6a5a"></i>operação</span><span><i style="background:#ffb4a8"></i>manutenção</span><span><i style="background:#c77dff"></i>P&amp;D e peças</span>
<span style="margin-left:auto;color:#8f98a7">fora do teto: salários, obras e juros</span></div>
<div class="lock">{g("lock", 18, "#ffb4a8")} Trava rígida: quando o teto acaba, projetos, pesquisas e peças novas ficam bloqueados até a próxima temporada.</div></div>'''
    credit = f'''<div class="card" style="left:580px;top:412px;width:320px;height:288px"><div class="cap">CRÉDITO</div>
<div class="loan"><span class="lic" style="background:rgba(92,147,234,.2)">{g("bank", 24, "#5c93ea")}</span><div><strong>Banco</strong><small>11 parcelas restantes</small></div>
<div class="v"><b>US$ 18,2 mi</b><small>− 1,8 por corrida</small></div></div>
<div class="loan"><span class="lic" style="background:rgba(255,210,74,.18)">{g("hand", 24, "#ffd24a")}</span><div><strong>Adiantamento</strong><small>patrocínio antecipado</small></div>
<div class="v"><b>—</b><small style="color:#a8b0bd">nenhum</small></div></div>
<div class="btn">{ico("chev", 18, "#11141a", 3)} Pedir dinheiro</div></div>
<div class="card" style="left:916px;top:412px;width:320px;height:288px"><div class="cap">TÚNEL DE VENTO 2026</div>
<div class="atr">{g("wind", 30, "#5c93ea")}<div><b>105%</b><small>do tempo de pesquisa de aerodinâmica · 7º no ano passado</small></div></div>
<div class="out">Regra da F1: quem termina mais à frente pesquisa menos aerodinâmica no ano seguinte (campeão 70%, último 115%). Vale para todas as equipes, inclusive a IA: muda os dias e a chance das pesquisas de aero.</div></div>'''
    return f'''<div class="scene"><div class="bg"></div>
<div class="hd"><span class="rb">{ico("back", 24, "#eef0f3", 2.6)}</span><img src="{V.EMB.format("williams")}" width="46"><div><small>WILLIAMS · APÓS 11 DE 22 RODADAS</small><h1>FINANÇAS</h1></div>
<span class="chip" style="margin-left:auto">CAIXA <b>US$ 61 mi</b></span><span class="chip">DÍVIDA <b style="color:#ffb4a8">US$ 18,2 mi</b></span></div>
<div class="nav">{nav}</div>{left}{cap}{credit}{body_extra}</div>'''


def finance():
    return V.page("V19 · Finanças · teto e crédito", CSS, frame(""))


def sheet():
    s = f'''<div class="dim"></div><div class="sheet"><div style="display:flex;align-items:center"><h2>PEDIR DINHEIRO</h2><span class="rb" style="margin-left:auto">{ico("x", 22) if False else '✕'}</span></div>
<div class="tabs"><span class="on">{g("bank", 20)} Banco · com juros</span><span>{g("hand", 20)} Adiantamento de patrocínio</span></div>
<div class="amt"><span class="val">US$ 20 mi</span><div class="slider"><i></i><b></b></div><span style="font-size:13px;color:#a8b0bd;font-weight:800">limite US$ 45 mi</span></div>
<div class="terms"><div><strong>5 corridas</strong><small>juros 4% · US$ 4,2 mi por corrida</small></div>
<div class="on"><strong>11 corridas</strong><small>juros 8% · US$ 2,0 mi por corrida</small></div>
<div><strong>Até o fim de 2027</strong><small>juros 15% · US$ 0,7 mi por corrida</small></div></div>
<div class="facts"><div><b>US$ 81 mi</b><small>caixa depois</small></div><div><b>US$ 21,6 mi</b><small>total a pagar</small></div><div><b>−3</b><small>confiança da diretoria com dívida alta</small></div></div>
<div class="warn">{g("warn", 18, "#ffd24a")} O dinheiro emprestado entra no caixa, mas os gastos continuam limitados pelo teto.</div>
<div class="cta">CONFIRMAR {ico("chev", 20, "#fff", 3)}</div></div>'''
    return V.page("V19 · Pedir dinheiro", CSS, frame(s))


if __name__ == "__main__":
    out = pathlib.Path(os.environ["V19_OUT"]) if os.environ.get("V19_OUT") else HERE
    (out / "v19-1-financas-teto-credito.html").write_text(finance(), encoding="utf-8")
    (out / "v19-2-pedir-dinheiro.html").write_text(sheet(), encoding="utf-8")
    print("ok")
