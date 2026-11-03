#!/usr/bin/env python3
"""Gera os sons da corrida por síntese (arquivos originais, sem gravações de terceiros).

Saída: game/assets/audio/*.wav (mono, 22 050 Hz, 16 bits).  Precisa só de numpy.

Versão 2 (a 1ª soava como sirene de ambulância): motor de F1 não é um tom puro, é uma sequência
de EXPLOSÕES. Aqui cada explosão é um estalo curto e áspero (ruído que decai + ressonâncias do
escapamento) colocado no instante certo; o tom do motor nasce da repetição desses estalos, com
pequenas irregularidades de tempo e de força (como num V6 de verdade). Por isso o resultado é
rugoso e "serrilhado", e não uma senoide limpa que desliza. A passagem do carro usa o efeito
Doppler sobre o instante de cada estalo. Nada de dois tons alternados (era o "alerta"): os
avisos agora são toques curtos e discretos.
"""
import os
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "game", "assets", "audio")
rng = np.random.default_rng(2026)


# --- utilidades ---------------------------------------------------------------------------

def band(x, lo, hi):
    """Filtro passa-faixa por FFT (circular: bom para sons em loop). lo=0 → só passa-baixa."""
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


def fftconv(x, h):
    n = len(x) + len(h) - 1
    m = 1 << (n - 1).bit_length()
    return np.fft.irfft(np.fft.rfft(x, m) * np.fft.rfft(h, m), m)[:len(x)]


def save(name, x, peak=0.85):
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())
    print("%-14s %.1f s" % (name, len(x) / SR))


# --- motor --------------------------------------------------------------------------------

def _firing_ir():
    """Resposta de UMA explosão no escapamento: estalo + ressonâncias (~12 ms)."""
    n = int(0.012 * SR)
    t = np.arange(n) / SR
    ir = noise(n) * np.exp(-t / 0.0014)
    for f, a, d in [(850, 0.9, 0.0022), (2500, 0.6, 0.0013), (5200, 0.3, 0.0008)]:
        ir += a * np.sin(2 * np.pi * f * t + rng.uniform(0, 6.28)) * np.exp(-t / d)
    ir[0] += 2.0  # ataque seco
    return ir / np.max(np.abs(ir))


IR = None


def engine(fire_hz, firing_phase=None, jitter=0.11):
    """Som de motor a partir da frequência de explosões por amostra (fire_hz: array).

    As explosões caem onde a fase acumulada cruza um número inteiro; cada uma tem tempo e força
    levemente aleatórios (irregularidade) e o padrão de força se repete a cada 3 (V6)."""
    global IR
    if IR is None:
        IR = _firing_ir()
    n = len(fire_hz)
    phase = np.cumsum(fire_hz) / SR if firing_phase is None else firing_phase
    idx = np.nonzero(np.diff(np.floor(phase)))[0]
    jit = rng.normal(0.0, jitter, len(idx)) * (SR / fire_hz[idx])
    idx = np.clip(idx + jit.astype(int), 0, n - 1)
    pattern = np.array([1.0, 0.78, 0.9])
    amp = pattern[np.arange(len(idx)) % 3] * (1.0 + 0.35 * rng.standard_normal(len(idx)))
    imp = np.zeros(n)
    np.add.at(imp, idx, amp)
    sig = fftconv(imp, IR)
    # chiado da combustão: ruído de médios/agudos no ritmo das explosões
    burst = fftconv(np.abs(imp), np.hanning(int(0.005 * SR)))
    sig += 0.35 * band(noise(n), 900, 5500) * burst / (np.max(burst) + 1e-9)
    return np.tanh(sig / (np.std(sig) + 1e-9) * 0.9)


def rev_curve(n, base, shift_s, depth=0.14):
    """Rotação (Hz de explosão) subindo e caindo um pouco a cada troca de marcha."""
    t = np.arange(n) / SR
    pos = (t % shift_s) / shift_s
    return base * (1.0 - depth + depth * pos ** 0.8)


def engine_bed():
    """Fundo: vários carros ao longe, misturados (loop de 8 s). Rugido, não tom."""
    n = int(8.6 * SR)
    mix = np.zeros(n)
    for _ in range(7):
        base = rng.uniform(360, 560)
        f = rev_curve(n, base, rng.uniform(1.2, 2.2)) * (1 + 0.025 * smooth_noise(n, 0.7))
        mix += engine(f) * rng.uniform(0.5, 1.0)
    mix = band(mix, 60, 2600)  # longe: perde os agudos
    mix += 0.30 * band(noise(n), 40, 260) * (0.7 + 0.3 * smooth_noise(n, 0.5))  # ronco grave
    mix += 0.10 * band(noise(n), 300, 2000)  # vento/pista
    save("engine_bed", loopify(mix))


def passby(idx, seed):
    """Um carro passando perto: aproxima, passa e se afasta (Doppler sobre cada explosão)."""
    global rng
    rng = np.random.default_rng(seed)
    dur = 3.0
    n = int(dur * SR)
    t = np.arange(n) / SR
    tc = dur * rng.uniform(0.42, 0.5)
    v = rng.uniform(70, 88)  # m/s
    d = rng.uniform(9, 16)  # distância mínima (m)
    x = v * (t - tc)
    r = np.sqrt(x ** 2 + d ** 2)
    doppler = 343.0 / (343.0 + v * x / r)
    base = rng.uniform(430, 540)
    src = rev_curve(n, base, rng.uniform(0.8, 1.2), 0.1)
    sig = engine(src * doppler, jitter=0.12)
    near = (d / r) ** 1.2
    bright = near ** 1.6
    sig = band(sig, 0, 2600) * (1 - bright) + sig * bright  # só de perto soa "aberto"
    sig += 0.30 * band(noise(n), 250, 3500) * (d / r) ** 1.7  # ar/pneus no instante da passagem
    save("passby_%d" % idx, sig * near * env(n, 0.06, 0.3))


def launch():
    """Largada: motores acelerando (rotação sobe rápido) para tocar junto da torcida."""
    global rng
    rng = np.random.default_rng(99)
    n = int(1.8 * SR)
    t = np.arange(n) / SR
    mix = np.zeros(n)
    for _ in range(5):
        f = (260 + 330 * (t / t[-1]) ** 0.7) * rng.uniform(0.92, 1.08)
        mix += engine(f)
    mix = band(mix, 80, 3200) * env(n, 0.05, 0.5)
    save("go", mix)


# --- torcida e efeitos --------------------------------------------------------------------

def crowd_loop():
    """Torcida: murmúrio de muitas vozes com ondas de volume (loop de 9 s)."""
    global rng
    rng = np.random.default_rng(7)
    n = int(9.6 * SR)
    x = np.zeros(n)
    for lo, hi, a in [(250, 900, 1.0), (700, 1800, 0.7), (1600, 3500, 0.35)]:
        layer = band(noise(n), lo, hi)
        layer *= 0.6 + 0.4 * smooth_noise(n, 1.3)
        x += a * layer
    for _ in range(90):  # "vozes": rajadas curtas
        L = int(rng.uniform(0.08, 0.3) * SR)
        s = rng.integers(0, n - L)
        f = rng.uniform(350, 1100)
        x[s:s + L] += band(noise(L), f * 0.8, f * 1.4) * np.hanning(L) * rng.uniform(0.3, 0.9)
    save("crowd_loop", loopify(x), 0.7)


def cheer():
    """Torcida vibrando: sobe rápido e cai devagar. Só ruído de voz (sem apitos)."""
    global rng
    rng = np.random.default_rng(8)
    n = int(3.6 * SR)
    t = np.arange(n) / SR
    x = band(noise(n), 300, 2600) + 0.5 * band(noise(n), 1200, 4000)
    x *= 0.75 + 0.25 * smooth_noise(n, 6)
    for _ in range(14):  # gritos individuais
        L = int(rng.uniform(0.15, 0.4) * SR)
        s = rng.integers(0, n - L)
        f = rng.uniform(450, 900)
        x[s:s + L] += 1.2 * band(noise(L), f * 0.8, f * 1.3) * np.hanning(L)
    e = np.minimum(t / 0.35, 1.0) * np.exp(-np.maximum(t - 0.6, 0) / 1.2)
    save("cheer", x * e)


def tick(name, freq, dur):
    """Toque seco e grave (semáforo): batida curta, sem tom de apito."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * freq * t) * np.exp(-t / 0.035) + 0.5 * band(noise(n), 800, 3000) * np.exp(-t / 0.008)
    save(name, x)


def pit_gun():
    """Pistola pneumática da roda: trem de estalos (~0,35 s)."""
    global rng
    rng = np.random.default_rng(5)
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
    """Rádio: estática curta de 'abrir o canal' (sem tons)."""
    global rng
    rng = np.random.default_rng(6)
    n = int(0.28 * SR)
    t = np.arange(n) / SR
    x = band(noise(n), 1200, 3600) * np.exp(-t / 0.09)
    x[:int(0.004 * SR)] += 1.5  # clique de abertura
    x += 0.4 * band(noise(n), 2500, 5000) * (t > 0.18) * np.exp(-(t - 0.18) / 0.03)
    save("radio", x * env(n, 0.001, 0.06))


def alert():
    """Aviso de bandeira: um toque suave e curto (sino abafado), nada de sirene."""
    n = int(0.45 * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * 392 * t) * np.exp(-t / 0.12) + 0.35 * np.sin(2 * np.pi * 784 * t) * np.exp(-t / 0.07)
    save("alert", x * env(n, 0.004, 0.05))


if __name__ == "__main__":
    engine_bed()
    for i, s in enumerate([11, 22, 33]):
        passby(i + 1, s)
    crowd_loop()
    cheer()
    tick("light", 170, 0.16)
    launch()
    pit_gun()
    radio()
    alert()
