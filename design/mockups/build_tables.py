"""Mockups de estilo das tabelas (torre de posições + menu DADOS), direção Paddock.

Uso: python design/mockups/build_tables.py   (gera t-*.html nesta pasta)
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import build as B  # noqa: E402
import build_m2 as M  # noqa: E402

HERE = B.HERE
TYRE = M.TYRE
ROWS = M.ROWS_A

BASE_CSS = """
body{background:#efe9de;color:#141414;font-family:ArchivoN;font-weight:600}
.wrap{display:grid;grid-template-columns:310px 1fr;gap:28px;padding:18px 22px;height:720px}
.lbl{font-family:ArchivoBlack;font-size:13px;letter-spacing:1px;margin-bottom:6px;color:#6d665a}
.tw{display:flex;flex-direction:column}
.r{display:flex;align-items:center;gap:6px;height:24px}
.r .p{width:24px;text-align:center;font-family:ArchivoBlack;font-size:14px}
.r .n{flex:1;font-family:ArchivoBlack;font-size:13px;white-space:nowrap;overflow:hidden}
.r .g{width:52px;text-align:right;font-size:13px;font-variant-numeric:tabular-nums}
.r .w{width:34px;text-align:right;font-size:11px}
.tyre{width:18px;height:18px;border-radius:50%;border:3px solid var(--t);display:flex;align-items:center;justify-content:center;font-family:ArchivoBlack;font-size:9px;background:#141414;color:#fff;flex:0 0 18px}
.wb{width:30px;height:5px;background:#d8d0c1;position:relative}.wb i{position:absolute;inset:0 auto 0 0;background:#141414}
.wb.hot i{background:#E10600}
.pen{font-family:ArchivoBlack;font-size:9px;color:#fff;background:#E10600;padding:0 3px;margin-left:4px}
table{border-collapse:collapse;width:100%;font-size:13px}
th{font-size:10px;letter-spacing:1.5px;text-align:left;font-weight:600;color:#6d665a;padding:5px 6px}
td{padding:4px 6px;white-space:nowrap;font-variant-numeric:tabular-nums}
td.num{text-align:right}td.b{font-family:ArchivoBlack}
.status{font-family:ArchivoBlack;font-size:14px;letter-spacing:1px;text-align:center;padding:5px 0;margin-bottom:4px;background:#F5C400}
"""

VARIANTS = {
    "t-a-fios": ("A · Fios de revista", "Fio de tinta entre cada piloto, fio grosso a cada 5 posições, números alinhados.", """
.r{border-bottom:1.5px solid #141414}.r.five{border-bottom-width:3px}
.r.me{background:#141414;color:#efe9de}.r.me .wb{background:#555}.r.me .wb i{background:#efe9de}
.r.lead .p{color:#E10600}.r.out{color:#a39a8a}.r.out .emb{opacity:.35}
thead th{border-bottom:3px solid #141414}tbody td{border-bottom:1.5px solid #141414}tr.five td{border-bottom-width:3px}
tr.me td{background:#141414;color:#efe9de}
"""),
    "t-b-listras": ("B · Listras de papel", "Linhas alternando papel claro/escuro, fio fino entre pilotos e faixa na cor da equipe.", """
.r{border-bottom:1px solid #b9b0a0;border-left:5px solid var(--tc);padding-left:3px}.r:nth-child(even){background:#e3dccd}
.r.me{background:#141414!important;color:#efe9de}.r.me .wb{background:#555}.r.me .wb i{background:#efe9de}
.r.lead .p{background:#E10600;color:#fff}.r .p{height:100%;display:flex;align-items:center;justify-content:center}
.r.out{color:#a39a8a}.r.out .emb{opacity:.35}
thead th{border-bottom:2px solid #141414}tbody tr:nth-child(even) td{background:#e3dccd}tbody td{border-bottom:1px solid #b9b0a0}
tr.me td{background:#141414!important;color:#efe9de}
"""),
    "t-c-cronometragem": ("C · Folha de cronometragem", "Grade completa como uma folha oficial de tempos: linhas e colunas, cabeçalho em tinta.", """
.tw{border:2px solid #141414}.r{border-bottom:1px solid #141414}.r>*{border-right:1px solid #c9c1b2;height:100%;display:flex;align-items:center}
.r .p{justify-content:center;background:#e3dccd}.r .g{justify-content:flex-end;padding-right:4px}.r .w{justify-content:flex-end;padding-right:4px}
.r .n{padding-left:4px}.r.me{background:#141414;color:#efe9de}.r.me .p{background:#E10600;color:#fff}.r.lead .p{color:#E10600}
.r.out{color:#a39a8a}.r.out .emb{opacity:.35}.r .emb,.r .tyre{border-right:none}.r>.wb{height:5px;border-right:none;margin-right:4px}
table{border:2px solid #141414}thead th{background:#141414;color:#efe9de;border-right:1px solid #444}
tbody td{border-bottom:1px solid #141414;border-right:1px solid #c9c1b2}tr.me td{background:#141414;color:#efe9de}
"""),
    "t-d-placas": ("D · Placas", "Cada piloto numa placa com contorno e espaço entre elas; posição em bloco de tinta.", """
.tw{gap:3px}.r{border:1.5px solid #141414;height:22px;padding-right:6px;gap:5px}
.r .p{background:#141414;color:#efe9de;height:100%;display:flex;align-items:center;justify-content:center;width:26px}
.r.lead .p{background:#E10600}.r.me{background:#141414;color:#efe9de}.r.me .p{background:#E10600}
.r.me .wb{background:#555}.r.me .wb i{background:#efe9de}.r.out{border-style:dashed;color:#a39a8a}.r.out .emb{opacity:.35}
table{border-collapse:separate;border-spacing:0 3px}tbody td{border-top:1.5px solid #141414;border-bottom:1.5px solid #141414}
tbody td:first-child{border-left:1.5px solid #141414;background:#141414;color:#efe9de;text-align:center}tbody td:last-child{border-right:1.5px solid #141414}
tr.me td{background:#141414;color:#efe9de}tr.me td:first-child{background:#E10600}
"""),
}


def tower():
    out = ['<div class="status">SAFETY CAR · 3 VOLTAS</div>']
    for i, (code, gap, tyre, wear, flag) in enumerate(ROWS):
        d = B.drivers[code]
        t = B.teams[d["team"]]
        cls = "r" + (" me" if d["team"] == "williams" else "") + (" lead" if i == 0 else "") + (" out" if flag == "out" else "") + (" five" if (i + 1) % 5 == 0 else "")
        pen = f'<span class="pen">{flag}</span>' if flag.startswith("+") else ""
        if flag == "out":
            tail = '<span class="g" style="width:auto;font-size:11px">ABANDONO</span>'
        else:
            hot = " hot" if wear >= 70 else ""
            tail = (f'<span class="g">{gap}</span><span class="tyre" style="--t:{TYRE[tyre]}">{tyre}</span>'
                    f'<span class="wb{hot}"><i style="width:{wear}%"></i></span>')
        out.append(f'<div class="{cls}" style="--tc:{t["color"]}"><span class="p">{"–" if flag == "out" else i + 1}</span>'
                   f'{B.emblem(d["team"], 18)}<span class="n">{d["name"].split(" ")[-1].upper()}{pen}</span>{tail}</div>')
    return "\n".join(out)


def table():
    head = "<thead><tr><th>POS</th><th>PILOTO</th><th>EQUIPE</th><th>ÚLT. VOLTA</th><th>MELHOR</th><th>INTERVALO</th><th>PNEU</th><th>PARADAS</th><th>ESTADO</th></tr></thead>"
    rows = []
    for i, (code, gap, tyre, wear, flag) in enumerate(ROWS[:14]):
        d = B.drivers[code]
        cls = ("me " if d["team"] == "williams" else "") + ("five" if (i + 1) % 5 == 0 else "")
        rows.append(f'<tr class="{cls}"><td class="b">{i + 1}</td><td class="b">{d["name"]}</td><td>{B.teams[d["team"]]["name"]}</td>'
                    f'<td class="num">1:16.{300 + i * 17}</td><td class="num">1:15.{150 + i * 23}</td><td class="num">+{0.6 + i * 0.3:.1f}</td>'
                    f'<td><span class="tyre" style="--t:{TYRE[tyre]};display:inline-flex;vertical-align:middle">{tyre}</span> {max(1, wear // 4)} v</td>'
                    f'<td class="num">{1 if tyre != "M" else 0}</td><td>Na pista</td></tr>')
    return f"<table>{head}<tbody>{''.join(rows)}</tbody></table>"


def page(slug, title, pitch, css):
    body = f'''<div class="wrap"><div><div class="lbl">TABELA DA CORRIDA</div><div class="tw">{tower()}</div></div>
<div><div class="lbl">{title.upper()} — {pitch}</div><div class="lbl" style="margin-top:14px">MENU DADOS</div>{table()}</div></div>'''
    return B.page(title, BASE_CSS + css, body)


if __name__ == "__main__":
    for slug, (title, pitch, css) in VARIANTS.items():
        (HERE / f"{slug}.html").write_text(page(slug, title, pitch, css), encoding="utf-8")
    print("ok")
