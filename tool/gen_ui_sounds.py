"""Renders Wird's UI sounds to assets/audio/ui/.

Run from the project root:  python3 tool/gen_ui_sounds.py

The sounds are synthesised, not recorded: short sine/triangle tones and
band-passed noise with exponential envelopes, the same recipes as the "soft"
pack on sayankabir.com (sound.js). Web Audio plays those live; Flutter has no
synth, so they're rendered once to tiny WAVs here. Tap and tick get a few
variants each because the originals randomise their pitch on every play;
SoundService rotates through them.

Standard library only, so it runs anywhere.
"""

import math
import os
import random
import struct
import wave

RATE = 44100
# The portfolio runs everything through a 0.9 master and a compressor on
# laptop speakers. Phone speakers are smaller and quieter, so more level
# here; the loudest peaks sit around -12 dBFS.
MASTER = 2.6
FLOOR = 1e-4
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio', 'ui')


def env(t, attack, peak, decay):
    """Web Audio's exponentialRampToValueAtTime: floor -> peak -> floor."""
    if t < 0:
        return 0.0
    if t < attack:
        return FLOOR * (peak / FLOOR) ** (t / attack)
    if t < attack + decay:
        return peak * (FLOOR / peak) ** ((t - attack) / decay)
    return 0.0


def tone(buf, t, f0, f1=None, kind='sine', attack=0.004, decay=0.08, gain=0.1):
    start = int(t * RATE)
    length = int((attack + decay + 0.05) * RATE)
    sweep = attack + decay
    phase = 0.0
    for i in range(length):
        s = i / RATE
        f = f0 * (f1 / f0) ** min(s / sweep, 1.0) if f1 else f0
        phase += 2 * math.pi * f / RATE
        if kind == 'triangle':
            v = 2 / math.pi * math.asin(math.sin(phase))
        else:
            v = math.sin(phase)
        buf[start + i] += v * env(s, attack, gain, decay)


def bell(buf, t, f, decay=0.8, gain=0.06):
    """A soft struck bell: the note, its octave, and a faint inharmonic
    partial that gives the strike its shimmer. Upper partials die first."""
    tone(buf, t, f, attack=0.005, decay=decay, gain=gain)
    tone(buf, t, f * 2, attack=0.004, decay=decay * 0.45, gain=gain * 0.3)
    tone(buf, t, f * 2.76, attack=0.003, decay=decay * 0.2, gain=gain * 0.1)


def glass(buf, t, f, decay=0.5, gain=0.04):
    """Thin glass: the note and two inharmonic partials, brighter than
    [bell] and quicker to fade."""
    tone(buf, t, f, attack=0.002, decay=decay, gain=gain)
    tone(buf, t, f * 2.76, attack=0.002, decay=decay * 0.35, gain=gain * 0.25)
    tone(buf, t, f * 5.4, attack=0.001, decay=decay * 0.15, gain=gain * 0.08)


def hiss(buf, t, freq=3000, q=1.0, attack=0.002, decay=0.02, gain=0.05, rng=random):
    """White noise through a band-pass biquad (RBJ, 0 dB peak, as Web Audio)."""
    w0 = 2 * math.pi * freq / RATE
    alpha = math.sin(w0) / (2 * q)
    a0 = 1 + alpha
    b0, b2 = alpha / a0, -alpha / a0
    a1, a2 = -2 * math.cos(w0) / a0, (1 - alpha) / a0
    x1 = x2 = y1 = y2 = 0.0
    start = int(t * RATE)
    for i in range(int((attack + decay + 0.05) * RATE)):
        x = rng.uniform(-1, 1)
        y = b0 * x + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, x, y1, y
        buf[start + i] += y * env(i / RATE, attack, gain, decay)


def render(name, build, seconds=0.4):
    buf = [0.0] * int(seconds * RATE)
    build(buf)
    # Trim the silent tail, keep a few ms so nothing clicks.
    end = len(buf)
    while end > 0 and abs(buf[end - 1]) < 1e-5:
        end -= 1
    end = min(len(buf), end + int(0.005 * RATE))
    frames = b''.join(
        struct.pack('<h', int(max(-1.0, min(1.0, v * MASTER)) * 32767)) for v in buf[:end])
    with wave.open(os.path.join(OUT, f'{name}.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(frames)
    print(f'{name}.wav  {end / RATE * 1000:.0f} ms')


def main():
    os.makedirs(OUT, exist_ok=True)
    rng = random.Random(7)

    # A normal tap: a soft wooden knock.
    for n in range(3):
        f0 = rng.uniform(640, 700)
        render(f'tap_{n}', lambda b, f0=f0: (
            tone(b, 0, f0, 420, decay=0.06, gain=0.09),
            hiss(b, 0, 2000, q=0.9, decay=0.012, gain=0.04, rng=rng)))

    # Selection, counting, sliders: a barely-there detent.
    for n in range(3):
        f = rng.uniform(3800, 4200)
        render(f'tick_{n}', lambda b, f=f: (
            # Twice the portfolio's level: a 10 ms tick barely registers on
            # a phone speaker otherwise.
            hiss(b, 0, f, q=3, decay=0.012, gain=0.1, rng=rng),
            tone(b, 0, 1800, decay=0.025, gain=0.03)))

    # A confirmation: a small rising pop.
    render('pop', lambda b: tone(b, 0, 380, 920, decay=0.07, gain=0.08))

    # Switches: two notes up for on, down for off.
    render('toggle_on', lambda b: (
        tone(b, 0, 784, decay=0.09, gain=0.06),
        tone(b, 0.07, 1175, decay=0.16, gain=0.06)))
    render('toggle_off', lambda b: (
        tone(b, 0, 1175, decay=0.08, gain=0.05),
        tone(b, 0.07, 784, decay=0.14, gain=0.05)))

    # Completing something that matters (a dhikr session, onboarding): three
    # rising notes of the pentatonic, soft and short.
    render('complete', lambda b: (
        tone(b, 0, 784, attack=0.006, decay=0.12, gain=0.05),
        tone(b, 0.08, 988, attack=0.006, decay=0.14, gain=0.05),
        tone(b, 0.16, 1175, attack=0.008, decay=0.3, gain=0.05)), seconds=0.6)

    # Logging a prayer: the app's reward, so warmer and longer than anything
    # else. Two bell strikes a fifth apart (D5, A5) that ring out; prayed in
    # jamaah, a third strike an octave up joins them.
    render('prayed', lambda b: (
        bell(b, 0, 587, decay=0.7, gain=0.06),
        bell(b, 0.11, 880, decay=0.9, gain=0.055)), seconds=1.2)
    render('prayed_jamaah', lambda b: (
        bell(b, 0, 587, decay=0.7, gain=0.055),
        bell(b, 0.11, 880, decay=0.8, gain=0.05),
        bell(b, 0.22, 1175, decay=1.0, gain=0.045)), seconds=1.4)

    # The festive decorations appearing: a quick run of high glass notes
    # (G6 B6 D7 G7) with a breath of sparkle over it.
    def festive(b):
        for i, f in enumerate([1568, 1976, 2349, 3136]):
            glass(b, i * 0.065, f, decay=0.5 - i * 0.06, gain=0.03)
        hiss(b, 0.02, 7000, q=1.5, attack=0.08, decay=0.35, gain=0.012, rng=rng)
    render('festive', festive, seconds=1.0)

    # Location found and prayer times ready: two soft glass notes rising a
    # fourth (A5, D6), gentler than the prayer bell.
    render('ready', lambda b: (
        glass(b, 0, 880, decay=0.45, gain=0.035),
        glass(b, 0.09, 1175, decay=0.6, gain=0.035)), seconds=0.9)


if __name__ == '__main__':
    main()
