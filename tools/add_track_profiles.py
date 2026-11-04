"""Perfil de cada circuito (PROVISÓRIO, 2026-11-04): peso de reta / curvas lentas / curvas rápidas no tempo de volta (soma 1).
Usado pelas características do carro (CarParts / CarForm). Estimativa pelo traçado e pela velocidade média conhecida de cada pista.
Uso: python tools/add_track_profiles.py
"""
import json
import pathlib

D = pathlib.Path(__file__).resolve().parent.parent / "game" / "data" / "circuits"
PROFILE = {  # reta, lentas, rápidas
    "albertpark": (0.35, 0.30, 0.35), "austin": (0.30, 0.35, 0.35), "baku": (0.55, 0.35, 0.10),
    "barcelona": (0.25, 0.30, 0.45), "hungaroring": (0.15, 0.55, 0.30), "interlagos": (0.35, 0.35, 0.30),
    "lasvegas": (0.60, 0.30, 0.10), "lusail": (0.25, 0.20, 0.55), "madring": (0.35, 0.40, 0.25),
    "mexico": (0.45, 0.35, 0.20), "miami": (0.40, 0.35, 0.25), "monaco": (0.05, 0.80, 0.15),
    "montreal": (0.50, 0.40, 0.10), "monza": (0.70, 0.15, 0.15), "shanghai": (0.35, 0.35, 0.30),
    "silverstone": (0.25, 0.15, 0.60), "singapore": (0.15, 0.65, 0.20), "spa": (0.45, 0.15, 0.40),
    "spielberg": (0.45, 0.30, 0.25), "suzuka": (0.20, 0.20, 0.60), "yasmarina": (0.40, 0.40, 0.20),
    "zandvoort": (0.15, 0.35, 0.50),
}
import re

for f in sorted(D.glob("*.json")):
    text = f.read_text(encoding="utf-8")
    d = json.loads(text)
    st, sl, fa = PROFILE[d["id"]]
    line = '"profile": {"straight": %s, "slow": %s, "fast": %s},' % (st, sl, fa)
    # inserção textual (preserva a formatação compacta do arquivo); idempotente
    text = re.sub(r'\n\s*"profile": \{[^}]*\},', "", text)
    text = re.sub(r'(\n(\s*)"rain_probability")', lambda m: "\n" + m.group(2) + line + m.group(1), text, count=1)
    json.loads(text)
    f.write_text(text, encoding="utf-8")
print("ok")
