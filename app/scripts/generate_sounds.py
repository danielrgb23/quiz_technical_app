#!/usr/bin/env python3
"""Gera os efeitos sonoros do app (WAV 16-bit mono) sem dependências externas.

Sons sintetizados (seno + harmônicos com envelope), portanto sem licença de
terceiros. Uso: python3 scripts/generate_sounds.py
"""
import math
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "quiz_app" / "assets" / "sounds"

NOTE = {"C4": 261.63, "E4": 329.63, "G4": 392.00, "A3": 220.00, "F3": 174.61,
        "C5": 523.25, "E5": 659.25, "G5": 783.99, "B5": 987.77, "C6": 1046.50,
        "A5": 880.00, "D3": 146.83}


def tone(freq, dur, vol=0.5, decay=6.0, harmonics=((1, 1.0), (2, 0.25), (3, 0.1))):
    n = int(RATE * dur)
    attack = int(RATE * 0.004)
    samples = []
    for i in range(n):
        t = i / RATE
        env = math.exp(-decay * t / dur) * min(1.0, i / max(attack, 1))
        env *= min(1.0, (n - i) / (RATE * 0.01))  # fade-out anti-click
        v = sum(a * math.sin(2 * math.pi * freq * h * t) for h, a in harmonics)
        samples.append(vol * env * v / sum(a for _, a in harmonics))
    return samples


def seq(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples))


write("tap", tone(NOTE["A5"], 0.06, 0.35, 8))
write("correct", seq(tone(NOTE["C5"], 0.09, 0.5, 4), tone(NOTE["E5"], 0.09, 0.5, 4),
                     tone(NOTE["G5"], 0.28, 0.55, 5)))
write("wrong", seq(tone(NOTE["A3"], 0.14, 0.5, 3, ((1, 1.0), (2, 0.6), (3, 0.4))),
                   tone(NOTE["F3"], 0.3, 0.5, 4, ((1, 1.0), (2, 0.6), (3, 0.4)))))
write("complete", seq(tone(NOTE["C5"], 0.11, 0.5, 4), tone(NOTE["E5"], 0.11, 0.5, 4),
                      tone(NOTE["G5"], 0.11, 0.5, 4), tone(NOTE["C6"], 0.5, 0.55, 5)))
write("start", seq(tone(NOTE["E5"], 0.08, 0.45, 4), tone(NOTE["B5"], 0.18, 0.5, 5)))
write("locked", tone(NOTE["D3"], 0.12, 0.55, 8, ((1, 1.0), (2, 0.5))))
print(f"Sons gerados em {OUT}")
