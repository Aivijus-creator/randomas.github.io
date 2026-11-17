#!/usr/bin/env python3
"""
Sugeneruoja močiutės frazes lietuviškai (espeak-ng + MBROLA lt2 balsas, sox efektai).
Reikia: apt-get install espeak-ng mbrola mbrola-lt2 sox
Paleidimas: python3 tools/make_voices.py  ->  audio/mociute/mociute_N.ogg
Frazės turi sutapti su Config/Texts lt.GrannyPhrases eile.
"""
import os
import subprocess
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "audio", "mociute")

PHRASES = [
    "Valgyk, tu labai sulysęs!",
    "Dar vieną cepeliną?",
    "Mano laikais bulvės buvo didesnės!",
    "Kepurę užsidėk, šalta!",
    "Kas nori grietinės?",
    "Nepamiršk paskambinti močiutei!",
    "Kibinai patys nepasidarys!",
    "Daugiau spirgučių dar niekam nepakenkė.",
]

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for i, text in enumerate(PHRASES, 1):
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            raw = tmp.name
        subprocess.run(["espeak-ng", "-v", "mb-lt2", "-s", "125", "-p", "60", "-w", raw, text], check=True)
        out = os.path.join(OUT, "mociute_%d.ogg" % i)
        # Aukštesnis (moteriškas), lėtesnis, šiek tiek virpantis balsas su lengvu aidu
        subprocess.run(["sox", raw, "-r", "44100", "-c", "1", out, "pitch", "550", "tempo", "0.88",
                        "tremolo", "5.5", "18", "equalizer", "3000", "1q", "-3",
                        "reverb", "18", "50", "40", "gain", "-n", "-2"], check=True)
        os.remove(raw)
        print(out, "-", text)
