"""V27 · Mercado vivo (decisões de 2026-11-10): proposta de rival pelos seus, pedido de renovação e notícias do mercado.
Usa o estilo v26 (moldura da campanha, cores de seção). Uso: python design/mockups/build_v27.py
(V26_FACES=<pasta> para a versão local com rostos)."""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402
import build_v26 as W  # noqa: E402

HERE = B.HERE
g = W.g
EMB = W.EMB

CSS = W.CSS + """
.dim{position:absolute;inset:0;background:rgba(5,7,10,.72)}
.modal{position:absolute;left:190px;top:104px;width:900px;border-radius:24px;background:#171a21;padding:22px 24px;box-shadow:0 20px 60px rgba(0,0,0,.6)}
.mhead{display:flex;align-items:center;gap:14px}
.vs{display:flex;align-items:center;gap:18px;margin-top:18px}
.col{flex:1;border-radius:18px;background:rgba(255,255,255,.05);padding:14px 16px}
.col b{display:block;font-size:26px;font-weight:900}.col small{display:block;font-size:13px;color:#a8b0bd;font-weight:800;margin-top:2px}
.opts3{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-top:18px}
.op{border-radius:18px;background:rgba(255,255,255,.06);padding:14px;min-height:120px;position:relative}
.op.pri{background:#f3f4f6;color:#11141a}
.op b{display:flex;align-items:center;gap:8px;font-size:17px;font-weight:900}
.op small{display:block;font-size:13px;font-weight:700;color:#a8b0bd;margin-top:8px;line-height:1.35}.op.pri small{color:#4b5260}
.tag{display:inline-flex;align-items:center;gap:6px;border-radius:10px;padding:3px 8px;font-size:12px;font-weight:900;margin-top:8px}
.foot{display:flex;align-items:center;gap:8px;margin-top:14px;font-size:13px;font-weight:800;color:#a8b0bd}
.nitem{display:flex;align-items:center;gap:12px;border-radius:16px;background:rgba(255,255,255,.05);padding:10px 12px;margin-top:8px}
.nitem b{font-size:15px;font-weight:900}.nitem small{display:block;font-size:12px;font-weight:700;color:#a8b0bd;margin-top:2px}
.arrow{font-size:20px;font-weight:900;color:#8f98a7}
"""


def emb(t, s=40):
    return f'<img src="{EMB.format(t)}" style="width:{s}px;height:{s}px;border-radius:{s // 4}px;flex:none">'


def base(sec_on="home"):
    return f'<div class="scene"><div class="bgx"></div>{W.topbar("INÍCIO", "home")}{W.rail(sec_on)}<div class="dim"></div>'


def proposta():
    m = (f'<div class="modal"><div class="mhead"><span class="chip" style="background:#3c9d5d">{g("hand", 16, "#fff")}MERCADO · PROPOSTA</span>'
         f'<span style="flex:1"></span><span class="chip">{g("timer", 16)}responda em 21 dias</span></div>'
         f'<div class="vs">{W.face("RUS", 92, W.TC)}<div style="flex:1"><div class="big" style="font-size:30px">A FERRARI QUER O RUSSELL</div>'
         f'<div style="font-size:15px;font-weight:800;color:#a8b0bd;margin-top:6px">para 2027 e 2028 · nota 89 · 4º no campeonato</div></div>'
         f'{emb("mercedes", 56)}<span class="arrow">→</span>{emb("ferrari", 56)}</div>'
         f'<div class="vs"><div class="col"><div class="cap">HOJE</div><b>US$ 8,0 mi</b><small>por ano · contrato até 2026</small></div>'
         f'<div class="col" style="background:rgba(225,6,0,.14)"><div class="cap" style="color:#ff8a80">PROPOSTA DA FERRARI</div><b>US$ 10,4 mi</b><small>por ano · 2 anos</small></div>'
         f'<div class="col" style="background:rgba(60,157,93,.16)"><div class="cap" style="color:#7fe0b1">MULTA PARA VOCÊ</div><b>US$ 6,0 mi</b><small>se aceitar liberá-lo</small></div></div>'
         f'<div class="opts3">'
         f'<div class="op pri"><b>{g("check", 22, "#11141a")}COBRIR</b><small>Iguala os US$ 10,4 mi/ano e ele fica até 2028.</small>'
         f'<span class="tag" style="background:#e3e6eb">{g("money", 14, "#11141a")}+2,4 mi/ano na folha</span></div>'
         f'<div class="op"><b>{g("money", 22, "#F5C542")}ACEITAR A MULTA</b><small>Recebe US$ 6,0 mi agora; ele corre por você até o fim do ano e vai na virada.</small>'
         f'<span class="tag" style="background:rgba(60,157,93,.25);color:#7fe0b1">+6,0 mi no caixa</span></div>'
         f'<div class="op"><b>{g("timer", 22)}DEIXAR IR</b><small>Recusa a multa; ele sai quando o contrato acabar (na virada).</small>'
         f'<span class="tag" style="background:rgba(255,255,255,.08)">sem custo</span></div></div>'
         f'<div class="foot">{g("bell", 16)}Sem resposta no prazo, ele sai quando o contrato acabar.</div></div>')
    return V.page("V27 · Proposta de rival", CSS, base() + m + "</div>")


def renovacao():
    m = (f'<div class="modal" style="top:150px"><div class="mhead"><span class="chip" style="background:#A66BFF">{g("person", 16, "#fff")}RENOVAÇÃO</span>'
         f'<span style="flex:1"></span><span class="chip">{g("cal", 16)}contrato acaba em 2026</span></div>'
         f'<div class="vs">{W.face("ANT", 92, W.TC)}<div style="flex:1"><div class="big" style="font-size:30px">ANTONELLI QUER RENOVAR</div>'
         f'<div style="font-size:15px;font-weight:800;color:#a8b0bd;margin-top:6px">"Quero continuar aqui. Mas o meu valor subiu."</div></div></div>'
         f'<div class="vs"><div class="col"><div class="cap">HOJE</div><b>US$ 6,1 mi</b><small>por ano</small></div>'
         f'<div class="col" style="background:rgba(166,107,255,.16)"><div class="cap" style="color:#c9a7ff">PEDIDO</div><b>US$ 7,2 mi</b><small>por ano · até 2028</small></div></div>'
         f'<div class="opts3">'
         f'<div class="op pri"><b>{g("check", 22, "#11141a")}ACEITAR</b><small>Renova até 2028 por US$ 7,2 mi/ano.</small></div>'
         f'<div class="op"><b>{g("lock", 22, "#ff8a80")}RECUSAR</b><small>Ele perde confiança e sai quando o contrato acabar.</small>'
         f'<span class="tag" style="background:rgba(255,138,128,.18);color:#ff8a80">−2 ritmo e regularidade · 3 corridas</span></div>'
         f'<div class="op"><b>{g("timer", 22)}DEPOIS</b><small>Ele pergunta de novo em algumas semanas (só uma vez).</small></div></div></div>')
    return V.page("V27 · Pedido de renovação", CSS, base() + m + "</div>")


def noticias():
    items = [("ferrari", "LEC", "LECLERC RENOVA COM A FERRARI", "fica até 2029", "#7fe0b1", "renovou"),
             ("alpine", "OCO", "OCON ASSINA COM A ALPINE PARA 2027", "hoje na Haas · contrato futuro", "#5c93ea", "2027"),
             ("mercedes", "RUS", "FERRARI FAZ PROPOSTA POR RUSSELL", "decisão sua · 21 dias", "#E10600", "decidir"),
             ("audi", "HUL", "HÜLKENBERG É LIBERADO PELA AUDI", "agente livre em 2027", "#F5C542", "livre")]
    li = "".join(f'<div class="nitem">{emb(t, 44)}<div style="flex:1"><b>{tt}</b><small>{sub}</small></div>'
                 f'<span class="chip" style="background:{c}33;color:{c}">{tag}</span></div>' for t, _c, tt, sub, c, tag in items)
    m = (f'<div class="modal" style="left:330px;width:620px;top:90px"><div class="mhead">{g("hand", 22, "#3c9d5d")}<div class="big" style="font-size:24px">MERCADO</div>'
         f'<span style="flex:1"></span><span class="chip" style="background:#E10600">1 decisão</span></div>{li}'
         f'<div class="foot">{g("users", 16)}Na tela Equipe e no Pessoal, quem sai aparece com a equipe nova e o ano.</div></div>')
    return V.page("V27 · Notícias do mercado", CSS, base() + m + "</div>")


if __name__ == "__main__":
    pages = {"v27-1-proposta": proposta, "v27-2-renovacao": renovacao, "v27-3-mercado": noticias}
    for name, fn in pages.items():
        (HERE / f"{name}.html").write_text(fn(), encoding="utf-8")
    print("ok")
