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
    "plus": '<path d="M12 5v14M5 12h14"/>',
    "minus": '<path d="M5 12h14"/>',
    "sound": '<path d="M4 9h4l5-4v14l-5-4H4z"/><path d="M16.5 8.5a5 5 0 0 1 0 7M19 6a8.5 8.5 0 0 1 0 12"/>',
    "mute": '<path d="M4 9h4l5-4v14l-5-4H4z"/><path d="M17 9.5l5 5M22 9.5l-5 5"/>',
    "check": '<path d="M5 12l5 5 9-10"/>',
    "bolt": '<path d="M13 2L4 14h7l-1 8 9-12h-7z"/>',
    # peças do carro e características (tela Carro · peças, 2026-11-04)
    "p_fwing": '<path d="M2 7h20M4 12h16M7 17h10"/>',
    "p_rwing": '<path d="M3 5h18v5H3zM8 10v9M16 10v9"/>',
    "p_floor": '<path d="M2 16l3-8h14l3 8zM6 16v3M18 16v3"/>',
    "p_susp": '<path d="M3 19L12 6l9 13M7 13h10"/>',
    "p_pu": '<path d="M13 2L4 14h7l-1 8 9-12h-7z"/>',
    "p_gear": '<circle cx="12" cy="12" r="4"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M5 19l2-2M17 7l2-2"/>',
    "t_straight": '<path d="M3 12h15M13 6l6 6-6 6"/>',
    "t_slow": '<path d="M6 21V10a6 6 0 0 1 12 0v4M14 11l4 4 4-4"/>',
    "t_fast": '<path d="M4 20Q4 6 18 5M14 2l4 3-3 4"/>',
    "t_rel": '<path d="M12 3l8 3v6q0 6-8 9-8-3-8-9V6zM8.5 12l2.5 2.5 4.5-5"/>',
    "money": '<path d="M12 2v20M17 6.5Q15 4 12 4 7 4 7 8t5 4 5 4-5 4q-3 0-5-2.5"/>',
    "clock": '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 3"/>',
    "box": '<path d="M3 8l9-5 9 5v9l-9 5-9-5zM3 8l9 5 9-5M12 13v9"/>',
    "factory": '<path d="M2 21V10l6 4V10l6 4V6l8 5v10z"/>',
    "arrow": '<path d="M4 12h14M13 6l6 6-6 6"/>',
    "wrench": '<path d="M14.5 5.5a4 4 0 0 0 4.9 5.2L21 12l-9 9-3-3 9-9-1.3-1.6a4 4 0 0 0-5.2-4.9l2.5 2.5-2 2-2.5-2.5"/>',
    "undo": '<path d="M9 14L4 9l5-5"/><path d="M4 9h11a5 5 0 0 1 0 10h-3"/>',
    "tree": '<circle cx="12" cy="5" r="2"/><circle cx="6" cy="19" r="2"/><circle cx="18" cy="19" r="2"/><path d="M12 7v5M12 12l-6 5M12 12l6 5"/>',
    # treino simulado e engenheiros de corrida (mockup v21, 2026-11-08)
    "shield": '<path d="M12 3l8 4v5c0 5-3.5 8-8 9-4.5-1-8-4-8-9V7z"/>',
    "headset": '<path d="M4 14v-2a8 8 0 0 1 16 0v2"/><rect x="2" y="14" width="5" height="6" rx="2"/><rect x="17" y="14" width="5" height="6" rx="2"/>',
    "person": '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-7 8-7s8 3 8 7"/>',
    "dice": '<rect x="4" y="4" width="16" height="16" rx="3"/><circle cx="9" cy="9" r="1.2"/><circle cx="15" cy="15" r="1.2"/><circle cx="15" cy="9" r="1.2"/><circle cx="9" cy="15" r="1.2"/>',
    "spin": '<path d="M20 12a8 8 0 1 1-3-6.3M20 4v5h-5"/>',
    "drs": '<rect x="3" y="8" width="18" height="8" rx="2"/><path d="M7 12h10"/>',
    "fire": '<path d="M12 3c1 4 6 6 6 11a6 6 0 0 1-12 0c0-3 2-4 2-7 2 1 3 3 3 5 1-2 1-6 1-9z"/>',
}

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for name, body in ICONS.items():
        (OUT / f"{name}.svg").write_text(
            '<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#ffffff" '
            f'stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">{body}</svg>\n', encoding="utf-8")
    print(f"{len(ICONS)} ícones em {OUT}")
