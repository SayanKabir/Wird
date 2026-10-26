"""Renders Wird's rain and thunder to assets/audio/weather/.

Run from the project root:  python3 tool/gen_weather_sounds.py

Like the UI sounds (gen_ui_sounds.py), these are synthesised rather than
recorded: shaped noise for the rain's hiss and patter, single filtered
clicks for drops, and low rolling noise for thunder. 22 kHz mono keeps
them small; the rain loop's ends are crossfaded so it repeats without a
seam. Standard library only.
"""

import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio', 'weather')


class Biquad:
    """RBJ biquad, as Web Audio's BiquadFilterNode."""

    def __init__(self, kind, freq, q=0.707):
        w0 = 2 * math.pi * freq / RATE
        alpha = math.sin(w0) / (2 * q)
        cos = math.cos(w0)
        if kind == 'lowpass':
            b0, b1, b2 = (1 - cos) / 2, 1 - cos, (1 - cos) / 2
        elif kind == 'highpass':
            b0, b1, b2 = (1 + cos) / 2, -(1 + cos), (1 + cos) / 2
        else:  # bandpass, 0 dB peak
            b0, b1, b2 = alpha, 0, -alpha
        a0, a1, a2 = 1 + alpha, -2 * cos, 1 - alpha
        self.c = (b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0)
        self.x1 = self.x2 = self.y1 = self.y2 = 0.0

    def __call__(self, x):
        b0, b1, b2, a1, a2 = self.c
        y = b0 * x + b1 * self.x1 + b2 * self.x2 - a1 * self.y1 - a2 * self.y2
        self.x2, self.x1, self.y2, self.y1 = self.x1, x, self.y1, y
        return y


def write(name, samples, peak):
    """Normalise to [peak] (0..1 of full scale) and save."""
    top = max(abs(s) for s in samples) or 1
    k = peak / top
    frames = b''.join(struct.pack('<h', int(max(-1, min(1, s * k)) * 32767)) for s in samples)
    with wave.open(os.path.join(OUT, f'{name}.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(frames)
    print(f'{name}.wav  {len(samples) / RATE:.1f} s')


def rain(seconds=12.0, fade=1.0):
    """Steady rain: a soft hiss, a low wash, and many single drops. Rendered
    with an extra [fade] seconds that are crossfaded over the start, so the
    loop has no seam."""
    rng = random.Random(3)
    n = int((seconds + fade) * RATE)
    hiss_bp = Biquad('bandpass', 3200, 0.5)
    hiss_hp = Biquad('highpass', 900)
    wash_lp = Biquad('lowpass', 420)
    out = [0.0] * n
    for i in range(n):
        white = rng.uniform(-1, 1)
        t = i / RATE
        # slow swell so it breathes rather than sits flat
        swell = 0.85 + 0.15 * math.sin(2 * math.pi * t / 6.0) * math.sin(2 * math.pi * t / 2.3)
        out[i] = (hiss_hp(hiss_bp(white)) * 0.55 + wash_lp(white) * 0.35) * swell

    # drops: tiny filtered clicks, mostly soft, a few closer and brighter
    for _ in range(int((seconds + fade) * 70)):
        start = rng.randrange(n - 400)
        near = rng.random() < 0.12
        bp = Biquad('bandpass', rng.uniform(2500, 6500) if near else rng.uniform(1500, 4500), 2.5)
        amp = rng.uniform(0.6, 1.4) if near else rng.uniform(0.12, 0.5)
        length = rng.randint(90, 260)
        for j in range(length):
            env = math.exp(-j / (length * 0.22))
            out[start + j] += bp(rng.uniform(-1, 1)) * amp * env

    body, tail = out[:int(seconds * RATE)], out[int(seconds * RATE):]
    for j, s in enumerate(tail):
        k = j / len(tail)  # equal-power crossfade of the tail over the head
        body[j] = body[j] * math.sin(k * math.pi / 2) + s * math.cos(k * math.pi / 2)
    return body


def thunder(seed, seconds, crack, rolls, darkness, swell=1.0, spread=1.0, pitch=1.0):
    """A rolling rumble. Real thunder lives mostly below 200 Hz, which a
    phone speaker can't play, so this one sits higher, around 160-900 Hz:
    noise shaped into a body that swells in over a fraction of a second,
    surges through a few [rolls] with an uneven, grumbling texture, and dies
    away within a few seconds. [crack] starts a close strike with a short
    tearing crackle of many small snaps (one burst sounds like a balloon);
    [darkness] muffles a more distant one. [swell] slows the rise (far-off
    thunder creeps in), [spread] sets how far apart the surges fall (low
    for a double clap, high for a long roll), and [pitch] moves the whole
    rumble up or down."""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    body_lp = Biquad('lowpass', (950 - 380 * darkness) * pitch, 0.7)
    body_lp2 = Biquad('lowpass', (1200 - 450 * darkness) * pitch, 0.6)
    body_hp = Biquad('highpass', 160 * pitch, 0.6)
    growl_bp = Biquad('bandpass', 300 * pitch, 0.9)

    # Surges: each a slow swell and a slower decay, the first one or two
    # strongest, spread over the first half.
    surges = []
    at = rng.uniform(0.05, 0.2)
    for k in range(rolls):
        surges.append((at, rng.uniform(0.55, 1.0) * (1 - 0.15 * k), rng.uniform(0.25, 0.5) * swell, rng.uniform(0.5, 0.9)))
        at += rng.uniform(0.25, 0.6) * spread

    def envelope(t):
        e = 0.0
        for start, amp, rise, fall in surges:
            if t < start:
                continue
            d = t - start
            e += amp * (1 - math.exp(-d / (rise / 3))) * math.exp(-d / fall)
        # the long grumbling tail under everything
        e += 0.3 * (1 - math.exp(-t / 0.5)) * math.exp(-t / (seconds * 0.3))
        return e

    pink = [0.0] * 3
    texture = 1.0
    out = [0.0] * n
    for i in range(n):
        t = i / RATE
        white = rng.uniform(-1, 1)
        # cheap pink-ish noise: three leaky integrators at different rates
        pink[0] = 0.997 * pink[0] + white * 0.03
        pink[1] = 0.985 * pink[1] + white * 0.06
        pink[2] = 0.90 * pink[2] + white * 0.12
        noise = pink[0] + pink[1] + pink[2]
        # uneven grumble: amplitude wanders a few times a second
        if i % 400 == 0:
            texture = 0.6 + 0.8 * rng.random()
        body = body_hp(body_lp2(body_lp(noise)))
        growl = growl_bp(noise) * 0.6
        tail = min(1.0, (seconds - t) / 1.4)  # a gentle end
        out[i] = (body + growl) * envelope(t) * (0.75 + 0.25 * texture) * tail

    if crack:
        # many small snaps over ~0.4 s, thinning out, under the first surge
        for _ in range(70):
            start = int(rng.betavariate(1.2, 3.5) * 0.45 * RATE)
            bp = Biquad('bandpass', rng.uniform(700, 2600), 1.4)
            amp = rng.uniform(0.15, 0.5) * (1 - start / (0.5 * RATE))
            length = rng.randint(120, 500)
            for j in range(length):
                if start + j < n:
                    out[start + j] += bp(rng.uniform(-1, 1)) * amp * math.exp(-j / (length * 0.3))
    return out


def write_rms(name, samples, rms):
    """Set loudness by average level, not the loudest instant, so no single
    snap dominates; then softly limit what peaks above."""
    mean = math.sqrt(sum(s * s for s in samples) / len(samples)) or 1
    k = rms / mean
    limited = [math.tanh(s * k * 1.6) / 1.6 for s in samples]
    write(name, limited, peak=max(abs(s) for s in limited))


def main():
    os.makedirs(OUT, exist_ok=True)
    # Quiet on purpose: rain is a backdrop, played softer still in the app.
    write('rain_loop', rain(), peak=0.45)
    # Eight thunders, so a storm rarely repeats itself: from far-off grumbles
    # to close cracks, single surges to double claps and longer rolls.
    variants = [
        ('thunder_far', dict(seed=11, seconds=4.0, crack=False, rolls=2, darkness=0.8), 0.1),
        ('thunder_far_creep', dict(seed=12, seconds=4.5, crack=False, rolls=2, darkness=0.9, swell=2.4, pitch=0.9), 0.095),
        ('thunder_roll', dict(seed=23, seconds=5.0, crack=False, rolls=3, darkness=0.4), 0.11),
        ('thunder_roll_long', dict(seed=24, seconds=5.0, crack=False, rolls=4, darkness=0.5, spread=1.5, pitch=0.95), 0.125),
        ('thunder_grumble', dict(seed=41, seconds=4.0, crack=False, rolls=3, darkness=0.6, swell=1.6, pitch=0.85), 0.115),
        ('thunder_double', dict(seed=52, seconds=4.0, crack=False, rolls=2, darkness=0.3, spread=0.45, pitch=1.05), 0.12),
        ('thunder_near', dict(seed=37, seconds=4.5, crack=True, rolls=3, darkness=0.1), 0.14),
        ('thunder_near_sharp', dict(seed=63, seconds=3.5, crack=True, rolls=2, darkness=0.05, spread=0.7, pitch=1.1), 0.13),
    ]
    for name, params, rms in variants:
        write_rms(name, thunder(**params), rms=rms)


if __name__ == '__main__':
    main()
