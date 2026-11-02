"""Campanha — Eventos inesperados (notícias) e Conselho de regras (direção Garagem).
Uso: python design/mockups/build_v13.py   (gera v13-*.html nesta pasta)
Equipe criada de exemplo (Aurora Racing, fictícia). Eventos são EXEMPLOS PROVISÓRIOS, em tom sóbrio; nada criminal ou
escandaloso com pessoas reais. Decisões do usuário: consequência automática com aviso (sem escolhas); eventos de pilotos,
calendário, equipe/fábrica e mercado/finanças; conselho com pontuação, corridas sprint e regra de pneus; todas as equipes
votam e o jogador só vota (sem lobby); regras valem na temporada seguinte.
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402
import build_v6 as S6  # noqa: E402
import build_v9 as N  # noqa: E402
import build_v10 as P  # noqa: E402

HERE = B.HERE
ico = V.ico
C1, C2 = S6.C1, S6.C2

CSS = P.CSS + """
.news{position:absolute;border-radius:22px;background:rgba(255,255,255,.06);padding:16px 20px}
.nw{display:flex;gap:12px;align-items:flex-start;padding:10px 0;border-bottom:1px solid rgba(255,255,255,.07)}
.nw .dot{width:34px;height:34px;border-radius:50%;display:grid;place-items:center;flex:none;font-weight:900;font-size:15px}
.nw b{display:block;font-size:15px;font-weight:900;line-height:1.2}.nw small{font-size:12px;color:#a8b0bd;font-weight:700}.nw p{font-size:13px;color:#c3c9d3;line-height:1.4;margin-top:2px}
.ev{width:760px;border-radius:26px;background:#f3f4f6;color:#11141a;padding:26px 30px 24px 38px;position:relative;box-shadow:0 20px 60px rgba(0,0,0,.6)}
.ev:before{content:"";position:absolute;left:0;top:0;bottom:0;width:10px;background:#E10600;border-radius:26px 0 0 26px}
.ev .k{font-size:12px;letter-spacing:3px;color:#4b5260;font-weight:700}.ev h2{font-size:34px;font-weight:900;line-height:1.05;margin:6px 0 8px}
.ev p{font-size:16px;color:#2b303a;line-height:1.5}.eff{display:flex;gap:10px;margin-top:16px}.eff div{flex:1;border-radius:14px;background:#e3e6eb;padding:10px 14px;font-size:13px;color:#4b5260;line-height:1.3}.eff b{display:block;font-size:19px;color:#11141a;font-weight:900}
.eff div.bad b{color:#b3261e}.eff div.good b{color:#2a6b3f}
.pr{border-radius:22px;background:rgba(255,255,255,.06);padding:16px 20px;margin-bottom:10px;position:relative}
.pr h3{font-size:21px;font-weight:900;line-height:1.1}.pr p{font-size:13px;color:#c3c9d3;margin-top:4px;line-height:1.4}
.votes{display:flex;gap:5px;margin-top:10px;align-items:center}.votes span{width:30px;height:30px;border-radius:50%;display:grid;place-items:center;font-size:11px;font-weight:900;color:#11141a}
.votes .y{background:#3c9d5d;color:#fff}.votes .n{background:#e0443a;color:#fff}.votes .w{background:rgba(255,255,255,.14);color:#8f98a7}.votes .me{outline:3px solid #fff;outline-offset:2px}
.vb{display:flex;gap:8px;margin-left:auto}.vb span{height:44px;padding:0 20px;border-radius:14px;background:rgba(255,255,255,.1);display:grid;place-items:center;font-size:14px;font-weight:900;letter-spacing:1px}
.vb span.on{background:#f3f4f6;color:#11141a}.tally{font-size:13px;color:#a8b0bd;font-weight:700;margin-left:12px;white-space:nowrap}.tally b{color:#fff}
.rule{display:flex;justify-content:space-between;height:38px;align-items:center;border-bottom:1px solid rgba(255,255,255,.07);font-size:15px}.rule span{color:#a8b0bd;font-weight:700}.rule b{font-weight:900}
"""


def topbar(sub, title):
    return (f'<div class="top"><span class="round">{ico("back", 26, "#eef0f3", 2.6)}</span>'
            f'<svg width="46" height="46" viewBox="0 0 24 24"><path d="M7 2h10l5 10-5 10H7L2 12z" fill="{C1}" stroke="{C2}" stroke-width="1.4"/></svg>'
            f'<div class="tm"><b>{sub}</b><h1>{title}</h1></div></div>')


def nav(on):
    items = ["Início", "Campeonatos", "Pessoal", "Carro", "Fábrica", "Patrocínios", "Finanças", "Conselho"]
    return '<div class="nav">' + "".join(f'<span class="{"on" if k == on else ""}">{i}</span>' for k, i in enumerate(items)) + "</div>"


def news_item(color, letter, title, when, text):
    return f'<div class="nw"><span class="dot" style="background:{color}33;color:{color}">{letter}</span><div><b>{title}</b><small>{when}</small><p>{text}</p></div></div>'


NEWS = (news_item("#ff6a5a", "P", "Rafael Câmara lesionado", "TER, 14 ABR", "Fora das próximas 2 corridas. O reserva Joshua Dürksen assume o carro.")
        + news_item("#ffd24a", "C", "GP de Sakhir cancelado", "SEG, 6 ABR", "Crise na região: a rodada sai do calendário e não rende pontos nem patrocínio.")
        + news_item("#5c93ea", "E", "Lote de peças com defeito", "SEX, 27 MAR", "O projeto “Assoalho v2” perdeu a produção (metade do dinheiro devolvida).")
        + news_item("#3c9d5d", "$", "Apoio do país-sede", "QUI, 12 MAR", "O governo local reforça o caixa com US$ 4 mi em troca de eventos.")
        + news_item("#ff6a5a", "P", "Tom Herta em baixa de confiança", "DOM, 1 MAR", "Queda de regularidade por 3 corridas após a maratona de viagens."))


def hub_with_event():
    ev = '''<div class="sheet" style="background:rgba(5,6,8,.72);display:flex;align-items:center;justify-content:center"><div class="ev">
<div class="k">NOTÍCIA · PILOTO</div><h2>RAFAEL CÂMARA SOFRE LESÃO NO TREINO</h2>
<p>O piloto bateu forte no treino livre e passará por exames. A equipe médica indica afastamento de duas corridas. A Aurora aciona o piloto reserva, Joshua Dürksen, que assume o carro #2.</p>
<div class="eff"><div class="bad"><b>2 corridas</b>fora da pista</div><div><b>Dürksen</b>reserva no carro (nota 77)</div><div class="good"><b>sem custo</b>seguro cobre a substituição</div></div>
<div style="display:flex;margin-top:22px"><div class="cta" style="margin-left:auto;width:260px;height:56px;font-size:18px">ENTENDI {chev}</div></div></div></div>'''.replace("{chev}", ico("chev", 22, "#fff", 3))
    body = f'''<div class="scene"><div class="wall" style="bottom:0"></div><div class="glow" style="background:radial-gradient(ellipse 45% 55% at 30% 60%,{C1}44,transparent 70%)"></div>
{topbar("AURORA RACING · 14 ABR", "SEDE · NOTÍCIAS")}{nav(0)}
<div class="news" style="left:44px;top:150px;width:700px;height:300px"><div class="lbl">PRÓXIMO EVENTO · EM 6 DIAS</div><div style="font-size:40px;font-weight:900">GP DA ESPANHA</div>
<div style="font-size:15px;color:#a8b0bd;margin-top:6px">Barcelona · 24 a 26 de abril</div><div class="cta" style="width:360px;margin-top:70px;height:56px;font-size:18px">AVANÇAR ATÉ O EVENTO {ico("chev", 22, "#fff", 3)}</div></div>
<div class="news" style="right:44px;top:100px;width:470px;height:600px"><div class="lbl">NOTÍCIAS DA TEMPORADA</div><div style="display:flex;gap:6px;margin-bottom:6px"><div class="tab" style="padding:3px"><span style="height:30px;font-size:12px;padding:0 10px">Eventos:</span><span style="height:30px;font-size:12px;padding:0 10px">Raros</span><span class="on" style="height:30px;font-size:12px;padding:0 10px">Normais</span><span style="height:30px;font-size:12px;padding:0 10px">Frequentes</span><span style="height:30px;font-size:12px;padding:0 10px">Desligados</span></div></div>{NEWS}</div>
{ev}
<div class="note" style="left:44px;bottom:6px;width:640px">EXEMPLO: EQUIPE FICTÍCIA · EVENTOS PROVISÓRIOS · O CARTÃO APARECE AO AVANÇAR O TEMPO; A CONSEQUÊNCIA JÁ FOI APLICADA</div></div>'''
    return V.page("V13 · Notícia de evento", CSS, body)


def conselho():
    teams = [("McLaren", "y"), ("Mercedes", "y"), ("Ferrari", "n"), ("Red Bull", "y"), ("Williams", "n"), ("Racing Bulls", "n"), ("Aston Martin", "n"), ("Haas", "n"),
             ("Alpine", "w"), ("Audi", "y"), ("Cadillac", "n")]
    initials = {"McLaren": "Mc", "Mercedes": "Me", "Ferrari": "Fe", "Red Bull": "RB", "Williams": "Wi", "Racing Bulls": "RC", "Aston Martin": "AM", "Haas": "Ha", "Alpine": "Al", "Audi": "Au", "Cadillac": "Ca"}

    def votes(vs, mine):
        out = "".join(f'<span class="{v}">{initials[t]}</span>' for t, v in vs)
        out += f'<span class="{mine} me">AU</span>'
        return out

    def prop(title, desc, vs, mine, sel, _tally=""):
        allv = [v for _, v in vs] + [mine]
        y, n, w = allv.count("y"), allv.count("n"), allv.count("w")
        tally = f"<b>{y} sim</b> · {n} não · {w} abst. · <b>{'aprovada' if y > n else 'rejeitada'}</b>"
        btn = "".join(f'<span class="{"on" if sel == k else ""}">{k}</span>' for k in ["SIM", "NÃO", "ABSTER"])
        return (f'<div class="pr"><div style="display:flex;align-items:center"><h3>{title}</h3><div class="vb">{btn}</div></div><p>{desc}</p>'
                f'<div class="votes">{votes(vs, mine)}<div class="tally">{tally}</div></div></div>')
    v1 = [(t, v) for t, v in teams]
    p = (prop("PONTUAÇÃO · TOP 12 PONTUAM", "Do 11º ao 12º lugar passam a marcar 2 e 1 ponto. Beneficia equipes do meio do grid.", v1, "y", "SIM", "<b>6 sim</b> · 4 não · 1 abst. · <b>aprovada</b>")
         + prop("MAIS CORRIDAS SPRINT · DE 6 PARA 8", "Mais dois fins de semana sprint: mais pontos em jogo, mais custo de pneus e peças.", [(t, "n" if v == "y" else "y") for t, v in teams], "w", "ABSTER", "<b>5 sim</b> · 5 não · 1 abst. · <b>rejeitada</b> (empate barra)")
         + prop("PNEUS · LIBERAR O COMPOSTO OBRIGATÓRIO", "Acaba a regra dos 2 compostos secos: dá para fazer a corrida inteira com um só, se a estratégia aguentar.", [(t, "w" if i % 3 == 0 else ("y" if i % 2 else "n")) for i, (t, v) in enumerate(teams)], "n", "NÃO", "<b>4 sim</b> · 4 não · 3 abst. · <b>rejeitada</b>"))
    rules = ("".join(f'<div class="rule"><span>{k}</span><b>{v}</b></div>' for k, v in [("Pontuação da corrida", "25-18-15-12-10-8-6-4-2-1"), ("Pontuação da sprint", "8-7-6-5-4-3-2-1"),
                                                                                       ("Fins de semana sprint", "6 de 22"), ("Compostos secos obrigatórios", "2"), ("Motor", "Híbrido 2026 (V6)"),
                                                                                       ("Valem para", "Temporada 2026")]))
    body = f'''<div class="scene"><div class="wall" style="bottom:0"></div><div class="glow" style="background:radial-gradient(ellipse 45% 55% at 70% 50%,{C1}44,transparent 70%)"></div>
{topbar("AURORA RACING · FIM DA TEMPORADA 2026", "CONSELHO DE REGRAS")}{nav(7)}
<div style="position:absolute;left:44px;top:150px;width:760px"><div class="lbl">VOTAÇÃO · REGRAS DE 2027 · TODAS AS EQUIPES VOTAM, MAIORIA SIMPLES</div>{p}</div>
<div class="news" style="right:44px;top:150px;width:400px;height:548px"><div class="lbl">REGRAS EM VIGOR</div>{rules}
<div style="font-size:13px;color:#a8b0bd;line-height:1.5;margin-top:14px">As propostas aprovadas valem a partir da temporada seguinte. A IA vota pelo próprio interesse (equipes fortes tendem a favorecer mais pontos e sprints). Fora da janela de fim de temporada a votação fica fechada.</div>
<div class="cta" style="margin-top:20px;height:58px;font-size:17px">CONFIRMAR VOTOS E FECHAR {ico("chev", 22, "#fff", 3)}</div></div>
<div class="note" style="left:44px;bottom:6px;width:760px">EXEMPLO · PROPOSTAS E VOTOS PROVISÓRIOS · SEM LOBBY: O SEU VOTO É UM ENTRE 12 (A CRIADA É A 12ª EQUIPE)</div></div>'''
    return V.page("V13 · Conselho de regras", CSS, body)


if __name__ == "__main__":
    for name, fn in [("v13-1-evento", hub_with_event), ("v13-2-conselho", conselho)]:
        (HERE / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
