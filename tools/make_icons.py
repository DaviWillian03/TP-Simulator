"""Gera os ícones de linha da interface (originais, traço branco; o jogo tinge com modulate).
Uso: python tools/make_icons.py   ->  game/assets/icons/<nome>.svg
"""
import pathlib

OUT = pathlib.Path(__file__).resolve().parent.parent / "game/assets/icons"
ICONS = {
    "lock": '<rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
    "chevron": '<path d="M9 5l7 7-7 7"/>',
    "back": '<path d="M15 5l-7 7 7 7"/>',
    "sun": '<circle cx="12" cy="12" r="4"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M19 5l-2 2M7 17l-2 2"/>',
    "rain": '<path d="M7 15a4 4 0 1 1 1-7.9A5 5 0 0 1 17.5 9 3.5 3.5 0 0 1 17 16H7"/><path d="M9 19l-1 2M13 19l-1 2M17 19l-1 2"/>',
    "mixed": '<circle cx="8" cy="8" r="3"/><path d="M8 2v1M2 8h1M3.8 3.8l.7.7"/><path d="M10 17a3.5 3.5 0 1 1 .9-6.9A4.5 4.5 0 0 1 19.5 12 3 3 0 0 1 19 18H10"/>',
    "globe": '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18"/>',
    "flag": '<path d="M5 21V4h11l-2 4 2 4H5"/>',
    "swap": '<path d="M4 8h13l-3-3M20 16H7l3 3"/>',
    "close": '<path d="M6 6l12 12M18 6L6 18"/>',
    "check": '<path d="M5 12l5 5 9-10"/>',
}

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for name, body in ICONS.items():
        (OUT / f"{name}.svg").write_text(
            '<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#ffffff" '
            f'stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">{body}</svg>\n', encoding="utf-8")
    print(f"{len(ICONS)} ícones em {OUT}")
