#!/usr/bin/env python3
"""
Sugeneruoja originalias liaudiško stiliaus (kanklių) melodijas žaidimo fonui.
Karplus–Strong stygos sintezė: skamba kaip atplėšiamos stygos.
Paleidimas: python3 tools/make_music.py  ->  audio/muzika/*.ogg
"""
import os
import subprocess
import wave

import numpy as np

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "audio", "muzika")
NOTES = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}


def freq(name):
    """'D4', 'F#4', 'Bb3' -> Hz"""
    letter, rest = name[0], name[1:]
    shift = 0
    if rest.startswith("#"):
        shift, rest = 1, rest[1:]
    elif rest.startswith("b"):
        shift, rest = -1, rest[1:]
    octave = int(rest)
    semis = NOTES[letter] + shift + (octave - 4) * 12
    return 440.0 * 2 ** (semis / 12)


def pluck(f, dur, amp=0.5, bright=0.5, rng=None):
    """Karplus–Strong styga"""
    n = int(SR * dur)
    period = max(2, int(SR / f))
    buf = (rng.random(period) * 2 - 1) * amp
    out = np.zeros(n)
    decay = 0.996 - (1 - bright) * 0.004
    for i in range(n):
        out[i] = buf[i % period]
        nxt = buf[(i + 1) % period]
        buf[i % period] = decay * 0.5 * (buf[i % period] + nxt)
    # švelni pradžia, kad nespragsėtų
    attack = min(n, int(SR * 0.004))
    out[:attack] *= np.linspace(0, 1, attack)
    return out


def render(melody, bass, beat, seed, title):
    """melody: [(nata | None, ketvirčių sk.)], bass: [(nata, ketvirčių sk.)]"""
    rng = np.random.default_rng(seed)
    total_beats = sum(d for _, d in melody)
    length = int(SR * beat * (total_beats + 4))
    mix = np.zeros(length)
    t = 0.0
    for note, d in melody:
        if note:
            s = pluck(freq(note), beat * d + 1.2, amp=0.55, bright=0.7, rng=rng)
            i = int(t * SR)
            mix[i:i + len(s)] += s[: max(0, length - i)]
        t += beat * d
    t = 0.0
    for note, d in bass:
        for chord_note, gain in ((note, 0.45), (None, 0)):
            if chord_note:
                s = pluck(freq(chord_note), beat * d + 1.5, amp=gain, bright=0.35, rng=rng)
                i = int(t * SR)
                mix[i:i + len(s)] += s[: max(0, length - i)]
        t += beat * d
    # paprastas aidas (kambarys)
    delay = int(SR * 0.19)
    echo = np.zeros_like(mix)
    echo[delay:] = mix[:-delay] * 0.28
    mix = mix + echo
    mix /= np.max(np.abs(mix)) + 1e-9
    mix *= 0.8
    fade = int(SR * 2.5)
    mix[-fade:] *= np.linspace(1, 0, fade)
    os.makedirs(OUT, exist_ok=True)
    wav_path = os.path.join(OUT, title + ".wav")
    with wave.open(wav_path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((mix * 32767).astype(np.int16).tobytes())
    ogg_path = os.path.join(OUT, title + ".ogg")
    subprocess.run(["sox", wav_path, "-C", "4", ogg_path, "reverb", "25", "50", "60"], check=True)
    os.remove(wav_path)
    print(ogg_path, round(length / SR, 1), "s")


def repeat(seq, times):
    return seq * times


# 1. „Kaimo valsas“ – D dur, 3/4, ramus
A = [("D5", 1), ("F#5", 1), ("A5", 1), ("G5", 2), ("F#5", 1), ("E5", 1), ("F#5", 1), ("G5", 1), ("F#5", 3),
     ("A5", 1), ("B5", 1), ("A5", 1), ("G5", 1), ("F#5", 1), ("E5", 1), ("D5", 2), ("E5", 1), ("F#5", 3)]
B = [("B4", 1), ("D5", 1), ("F#5", 1), ("E5", 2), ("D5", 1), ("C#5", 1), ("D5", 1), ("E5", 1), ("A4", 3),
     ("D5", 1), ("E5", 1), ("F#5", 1), ("G5", 1), ("E5", 1), ("C#5", 1), ("D5", 3), (None, 3)]
melody1 = repeat(A + B, 3)
bass_bar = [("D3", 3), ("A2", 3), ("G2", 3), ("D3", 3), ("D3", 3), ("A2", 3), ("A2", 3), ("D3", 3)]
bass_bar_b = [("B2", 3), ("A2", 3), ("G2", 3), ("A2", 3), ("D3", 3), ("G2", 3), ("A2", 3), ("D3", 3)]
bass1 = repeat(bass_bar + bass_bar_b, 3)

# 2. „Prie Nemuno“ – A moll (eolinė), lėtesnė, svajinga
C = [("A4", 2), ("C5", 1), ("E5", 2), ("D5", 1), ("C5", 2), ("B4", 1), ("A4", 3),
     ("G4", 2), ("A4", 1), ("C5", 2), ("B4", 1), ("A4", 2), ("G4", 1), ("E4", 3)]
D = [("E5", 2), ("G5", 1), ("A5", 2), ("G5", 1), ("E5", 2), ("D5", 1), ("C5", 3),
     ("D5", 2), ("C5", 1), ("B4", 2), ("G4", 1), ("A4", 3), (None, 3)]
melody2 = repeat(C + D, 3)
bass_c = [("A2", 3), ("A2", 3), ("F2", 3), ("A2", 3), ("G2", 3), ("C3", 3), ("G2", 3), ("E2", 3)]
bass_d = [("C3", 3), ("A2", 3), ("C3", 3), ("A2", 3), ("G2", 3), ("E2", 3), ("A2", 3), ("A2", 3)]
bass2 = repeat(bass_c + bass_d, 3)

if __name__ == "__main__":
    render(melody1, bass1, beat=0.42, seed=7, title="kaimo_valsas")
    render(melody2, bass2, beat=0.55, seed=11, title="prie_nemuno")
