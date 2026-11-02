"""Ficha do piloto (Pessoal e mercado) — direção Garagem. Uso: python design/mockups/build_v12.py (gera v12-*.html).
Piloto de exemplo: Carlos Sainz (real). Atributos são ESTIMATIVA do projeto; altura/peso/vitórias/pódios ficam
como "—" até haver fonte confiável. Equipe de exemplo fictícia (Aurora Racing)."""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_v3 as V  # noqa: E402
import build_v6 as S6  # noqa: E402
import build_v9 as N  # noqa: E402
import build_v10 as P  # noqa: E402

HERE = B.HERE
C1 = S6.C1

CSS = P.CSS + """
.fh{width:860px;border-radius:26px;background:#17191e;padding:26px 30px;box-shadow:0 20px 60px rgba(0,0,0,.6);position:relative}
.fh .top2{display:flex;gap:20px;align-items:center}.fh h2{font-size:34px;font-weight:900;line-height:1}.fh .sub{font-size:14px;color:#a8b0bd;font-weight:700;margin-top:4px}
.fh .big{margin-left:auto;text-align:right}.fh .big b{font-size:64px;font-weight:900;line-height:.9}.fh .big small{display:block;font-size:11px;letter-spacing:2px;color:#8f98a7;font-weight:700}
.grid2{display:flex;gap:26px;margin-top:20px}.grid2>div{flex:1}
.at{display:flex;align-items:center;gap:12px;height:40px}.at span.n{width:178px;font-size:15px;font-weight:700;color:#e3e6eb}.at .b{flex:1;height:12px;border-radius:6px;background:rgba(255,255,255,.1);position:relative}
.at .b i{position:absolute;inset:0 auto 0 0;border-radius:6px}.at .b s{position:absolute;top:-5px;bottom:-5px;width:3px;background:#fff;border-radius:2px}.at .v{width:34px;text-align:right;font-weight:900;font-size:18px}
.kv{display:flex;justify-content:space-between;height:36px;align-items:center;border-bottom:1px solid rgba(255,255,255,.07);font-size:15px}.kv span{color:#a8b0bd;font-weight:700}.kv b{font-weight:900}.kv b.na{color:#5d6574}
.tagrow{display:flex;gap:8px;margin-top:10px}
"""


def attr(name, v, color, pot=None):
    mark = f'<s style="left:{pot}%"></s>' if pot else ""
    return f'<div class="at"><span class="n">{name}</span><span class="b"><i style="width:{v}%;background:{color}"></i>{mark}</span><span class="v">{v}</span></div>'


def ficha():
    attrs = [("Ritmo de corrida", 89), ("Classificação", 91), ("Regularidade", 87), ("Ultrapassagem e defesa", 86), ("Chuva", 85), ("Gestão de pneus", 86)]
    ab = "".join(attr(n, v, "#5c93ea") for n, v in attrs)
    kv = [("Nascimento", "01/09/1994 · 32 anos", False), ("Nacionalidade", "Espanha", False), ("Títulos mundiais", "0", False), ("Altura · peso", "—", True),
          ("Vitórias · pódios · poles", "—", True), ("Potencial", "88", False)]
    kvs = "".join(f'<div class="kv"><span>{k}</span><b class="{"na" if na else ""}">{v}</b></div>' for k, v, na in kv)
    body = f'''<div class="scene"><div class="wall" style="bottom:0"></div><div class="glow" style="background:radial-gradient(ellipse 45% 55% at 30% 60%,{C1}44,transparent 70%)"></div>
{P.topbar("AURORA RACING · 9 MAR", "PESSOAL · CONTRATOS")}{P.nav()}
<div class="sheet"><div class="fh"><div class="top2">{P.avatar("CS", "#1868DB", 84)}<div><h2>CARLOS SAINZ <span style="color:#8f98a7;font-size:20px">#55</span></h2>
<div class="sub">Williams · Espanha · contrato até 2027 · US$ 5,1 mi/ano</div>
<div class="tagrow"><span class="tag ok">no grid da F1</span><span class="tag warn">multa de rescisão US$ 10,2 mi</span></div></div>
<div class="big"><b>88</b><small>NOTA GERAL</small></div></div>
<div class="grid2"><div><div class="lbl" style="margin-bottom:6px">ATRIBUTOS · NOTA GERAL = MÉDIA PONDERADA</div>{ab}</div>
<div><div class="lbl" style="margin-bottom:6px">FICHA</div>{kvs}</div></div>
<div style="display:flex;gap:12px;margin-top:20px"><div class="btn2 ghost" style="margin-left:0;height:54px;background:rgba(255,255,255,.1);color:#fff;padding:0 24px">FECHAR</div>
<div class="btn2 red" style="margin-left:auto;height:54px;padding:0 34px">NEGOCIAR</div></div></div></div>
<div class="note" style="left:44px;bottom:6px;width:760px">EXEMPLO · ATRIBUTOS = ESTIMATIVA DO PROJETO (PROVISÓRIO) · "—" = AINDA SEM FONTE CONFIÁVEL (NADA INVENTADO)</div></div>'''
    return V.page("V12 · Ficha do piloto", CSS, body)


if __name__ == "__main__":
    (HERE / "v12-1-ficha-piloto.html").write_text(ficha(), encoding="utf-8")
    print("ok")
