#!/usr/bin/env python3
"""Gera os sons da corrida por síntese (arquivos originais, sem gravações de terceiros).

Saída: game/assets/audio/*.wav (mono, 22 050 Hz, 16 bits).

Por que síntese: não há licença a negociar nem gravação de transmissão (que teria direitos),
e dá para ajustar o som mexendo em números. Os motores imitam o timbre agudo de um V6 turbo
híbrido (~11 mil rpm: 3 explosões por volta do virabrequim ≈ 550 Hz) com efeito Doppler
na passagem; a torcida é ruído filtrado em faixas de voz com "ondas" de volume.

Uso: python3 tools/make_sounds.py   (precisa só de numpy)
"""
import os
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "game", "assets", "audio")
rng = np.random.default_rng(2026)


# --- utilidades ---------------------------------------------------------------------------

def band(x, lo, hi):
    """Filtro passa-faixa por FFT (circular: bom para sons em loop)."""
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1.0 / SR)
    mask = np.clip((f - lo * 0.7) / (lo * 0.3 + 1e-9), 0, 1) if lo > 0 else np.ones_like(f)
    mask *= np.clip((hi * 1.3 - f) / (hi * 0.3), 0, 1)
    return np.fft.irfft(spec * mask, len(x))


def noise(n):
    return rng.standard_normal(n)


def smooth_noise(n, rate_hz):
    """Ruído lento (para variar volume/afinação), entre -1 e 1."""
    k = max(2, int(n / SR * rate_hz) + 2)
    pts = rng.uniform(-1, 1, k)
    return np.interp(np.linspace(0, k - 1, n), np.arange(k), pts)


def osc(freq, harmonics):
    """Oscilador com frequência variável (freq = array por amostra) e harmônicos [(n, amp)]."""
    phase = 2 * np.pi * np.cumsum(freq) / SR
    out = np.zeros_like(freq)
    for n, a in harmonics:
        out += a * np.sin(n * phase + n * 0.7)
    return out


def env(n, attack, release):
    e = np.ones(n)
    a = int(attack * SR)
    r = int(release * SR)
    if a:
        e[:a] = np.linspace(0, 1, a)
    if r:
        e[-r:] *= np.linspace(1, 0, r)
    return e


def loopify(x, fade_s=0.6):
    """Emenda o fim no começo com fade cruzado (o loop não dá clique)."""
    f = int(fade_s * SR)
    body = x[:-f].copy()
    body[:f] = body[:f] * np.linspace(0, 1, f) + x[-f:] * np.linspace(1, 0, f)
    return body


def save(name, x, peak=0.85):
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())
    print("%-14s %.1f s" % (name, len(x) / SR))


ENGINE_HARM = [(1, 1.0), (2, 0.55), (3, 0.42), (4, 0.25), (5, 0.18), (6, 0.12), (8, 0.07), (10, 0.04)]


def rpm_curve(n, start, top, shift_every_s):
    """Rotação subindo com trocas de marcha (cai ~12% a cada troca)."""
    t = np.arange(n) / SR
    pos = (t % shift_every_s) / shift_every_s
    return start + (top - start) * pos ** 0.8


# --- sons ---------------------------------------------------------------------------------

def engine_bed():
    """Fundo: vários carros longe, misturados (loop de 8 s)."""
    n = int(8.6 * SR)
    mix = np.zeros(n)
    for i in range(6):
        base = rng.uniform(430, 600)
        rpm = rpm_curve(n, base * 0.86, base, rng.uniform(1.1, 1.9))
        rpm *= 1 + 0.02 * smooth_noise(n, 0.5)
        vol = 0.5 + 0.5 * (0.5 + 0.5 * smooth_noise(n, rng.uniform(0.15, 0.4)))
        mix += osc(rpm, ENGINE_HARM) * vol * rng.uniform(0.5, 1.0)
    mix = np.tanh(mix * 0.6)
    mix = band(mix, 80, 2400)  # longe: perde os agudos
    mix += 0.25 * band(noise(n), 60, 600)  # ronco/vento
    save("engine_bed", loopify(mix))


def passby(idx, seed):
    """Um carro passando perto: sobe de giro, Doppler e volume pela distância."""
    global rng
    rng = np.random.default_rng(seed)
    dur = 3.0
    n = int(dur * SR)
    t = np.arange(n) / SR
    tc = dur * rng.uniform(0.42, 0.5)  # instante em que passa na frente
    v = rng.uniform(75, 90)  # m/s (~300 km/h)
    d = rng.uniform(10, 18)  # distância mínima (m)
    x = v * (t - tc)
    r = np.sqrt(x ** 2 + d ** 2)
    c = 343.0
    doppler = c / (c + v * x / r)  # aproximando: >1; afastando: <1
    base = rng.uniform(540, 620)
    rpm = rpm_curve(n, base * 0.88, base, rng.uniform(0.7, 1.0))
    sig = osc(rpm * doppler, ENGINE_HARM + [(12, 0.03), (14, 0.02)])
    sig = np.tanh(sig * 1.4)
    sig += 0.35 * band(noise(n), 1500, 6000) * (d / r)  # chiado de ar/pneu
    amp = (d / r) ** 1.3
    save("passby_%d" % idx, sig * amp * env(n, 0.05, 0.25))


def crowd_loop():
    """Torcida: murmúrio de muitas vozes com ondas de volume (loop de 9 s)."""
    n = int(9.6 * SR)
    x = np.zeros(n)
    for lo, hi, a in [(250, 900, 1.0), (700, 1800, 0.7), (1600, 3500, 0.35)]:
        layer = band(noise(n), lo, hi)
        layer *= 0.6 + 0.4 * smooth_noise(n, 1.3)
        x += a * layer
    # "vozes": rajadas curtas em faixas de formante
    for _ in range(90):
        L = int(rng.uniform(0.08, 0.3) * SR)
        s = rng.integers(0, n - L)
        f = rng.uniform(350, 1100)
        blip = band(noise(L), f * 0.8, f * 1.4) * np.hanning(L)
        x[s:s + L] += blip * rng.uniform(0.3, 0.9)
    save("crowd_loop", loopify(x), 0.7)


def cheer():
    """Torcida vibrando (ultrapassagem, pódio): sobe rápido e cai devagar, com assobios."""
    n = int(3.6 * SR)
    t = np.arange(n) / SR
    x = band(noise(n), 300, 2600) + 0.5 * band(noise(n), 1500, 4500)
    x *= 0.75 + 0.25 * smooth_noise(n, 6)
    e = np.minimum(t / 0.35, 1.0) * np.exp(-np.maximum(t - 0.6, 0) / 1.2)
    for _ in range(4):  # assobios
        s = rng.uniform(0.2, 1.6)
        L = rng.uniform(0.4, 0.9)
        f0 = rng.uniform(1800, 2600)
        m = (t > s) & (t < s + L)
        tt = t[m] - s
        f = f0 + 500 * np.sin(np.pi * tt / L)
        x[m] += 0.35 * np.sin(2 * np.pi * np.cumsum(f) / SR) * np.hanning(m.sum())
    save("cheer", x * e)


def beep(name, freq, dur, vol=1.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * freq * t) + 0.25 * np.sin(4 * np.pi * freq * t)
    save(name, x * env(n, 0.005, dur * 0.4), 0.8 * vol)


def pit_gun():
    """Pistola pneumática da roda: trem de estalos ressonantes (~0,35 s)."""
    n = int(0.42 * SR)
    x = np.zeros(n)
    rate = 55.0
    for k in range(int(0.34 * rate)):
        s = int(k / rate * SR)
        L = int(0.012 * SR)
        x[s:s + L] += noise(L) * np.exp(-np.arange(L) / (0.003 * SR))
    x = band(x, 900, 5000) + 0.4 * band(x, 200, 700)
    save("pit_gun", x * env(n, 0.002, 0.08))


def radio():
    """Clique de rádio: chiado curto + dois tons."""
    n = int(0.32 * SR)
    t = np.arange(n) / SR
    tone = np.where(t < 0.12, np.sin(2 * np.pi * 1250 * t), np.sin(2 * np.pi * 1650 * t))
    tone *= (t > 0.04)
    x = 0.6 * tone + 0.35 * band(noise(n), 1000, 4000) * np.exp(-t / 0.05)
    save("radio", x * env(n, 0.003, 0.06))


def alert():
    """Bandeira/safety car: dois tons alternados."""
    n = int(0.9 * SR)
    t = np.arange(n) / SR
    f = np.where((t * 4).astype(int) % 2 == 0, 740, 990)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR)
    x = np.tanh(2 * x) * 0.8
    save("alert", x * env(n, 0.01, 0.1))


if __name__ == "__main__":
    engine_bed()
    for i, s in enumerate([11, 22, 33]):
        passby(i + 1, s)
    rng = np.random.default_rng(7)
    crowd_loop()
    cheer()
    beep("light", 880, 0.22)
    beep("go", 1320, 0.55)
    pit_gun()
    radio()
    alert()
