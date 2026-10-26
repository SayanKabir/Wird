"""Generate the Wird "window to the next prayer" icons: one open sky per
prayer, seen through a gold arch.

Run from the repo root: python3 assets/icon/gen_icons.py assets/icon
then: dart run flutter_launcher_icons

Maghrib is the default icon (flutter_launcher_icons writes it). The other
four are alternate icons the app switches to (see AppIconService), so this
also writes them straight into the platform projects: Android launcher
mipmaps for the activity aliases, iOS AppIcon-<prayer> sets, and the small
thumbnails the Settings picker shows. Needs rsvg-convert (brew install
librsvg) and macOS sips.
"""
import os, subprocess, sys

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)

ARCH = ("M292 862 V486 C292 346, 410 294, 462 248 C492 221, 512 188, 512 136 "
        "C512 188, 532 221, 562 248 C614 294, 732 346, 732 486 V862 Z")

# Sky inside the arch (top -> horizon) uses the app's prayer palettes.
PRAYERS = {
    "fajr": dict(sky=[("0", "#2E1A47"), (".45", "#4A2C6A"), (".82", "#FFB88C"), ("1", "#FFD8B0")],
                 body="dawn", hills=("#3A2452", "#24163A")),
    "dhuhr": dict(sky=[("0", "#1E5799"), (".5", "#2980B9"), (".82", "#3498B8"), ("1", "#9ED8EA")],
                  body="sun", sun=(512, 400, 54), hills=("#1C4A7A", "#123358")),
    "asr": dict(sky=[("0", "#92400E"), (".45", "#C2410C"), (".8", "#D97706"), ("1", "#F8B54C")],
                body="sun", sun=(612, 560, 48), hills=("#7A3410", "#56240A")),
    "maghrib": dict(sky=[("0", "#2C3E50"), (".38", "#8E44AD"), (".74", "#EE5A24"), ("1", "#FF8A5C")],
                    body="sun", sun=(512, 748, 70), hills=("#5A2A5E", "#3A1B42")),
    "isha": dict(sky=[("0", "#10122C"), (".6", "#16213E"), ("1", "#0F3460")],
                 body="moon", hills=("#0E1A38", "#070F24")),
}


def sparkle(x, y, s, op):
    return (f'<path d="M{x} {y-s} Q{x} {y} {x+s} {y} Q{x} {y} {x} {y+s} '
            f'Q{x} {y} {x-s} {y} Q{x} {y} {x} {y-s}Z" fill="#FBE3A4" opacity="{op}"/>')


def body(p):
    kind = p["body"]
    if kind == "sun":
        x, y, r = p["sun"]
        return (f'<circle cx="{x}" cy="{y}" r="{r*2.4}" fill="#FFE2B0" opacity=".45" filter="url(#soft)"/>'
                f'<circle cx="{x}" cy="{y}" r="{r}" fill="#FFF4DA"/>')
    if kind == "dawn":
        return ('<ellipse cx="512" cy="800" rx="220" ry="120" fill="#FFE9C8" opacity=".7" filter="url(#soft)"/>'
                + sparkle(560, 420, 16, .9))
    # Crescent and a few stars for Isha.
    return ('<circle cx="512" cy="470" r="150" fill="#9DB4FF" opacity=".18" filter="url(#soft)"/>'
            '<mask id="cres"><rect width="1024" height="1024" fill="#fff"/>'
            '<circle cx="548" cy="440" r="70" fill="#000"/></mask>'
            '<circle cx="512" cy="470" r="80" fill="#FFF4D6" mask="url(#cres)"/>'
            + sparkle(400, 350, 12, .9) + sparkle(620, 600, 9, .7) + sparkle(380, 600, 7, .6))


def defs(p):
    stops = "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in p["sky"])
    return f'''<defs>
<linearGradient id="sky" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="1024">{stops}</linearGradient>
<linearGradient id="gold" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFEBB5"/><stop offset=".5" stop-color="#EAB65A"/><stop offset="1" stop-color="#B9772A"/></linearGradient>
<filter id="soft" x="-1" y="-1" width="3" height="3"><feGaussianBlur stdDeviation="28"/></filter>
<filter id="glow" x="-.3" y="-.3" width="1.6" height="1.6"><feGaussianBlur stdDeviation="22"/></filter>
</defs>'''


# The whole icon is one open sky; the arch is the gold frame you look
# through, with the sky outside it dimmed a little. The scene runs a little
# past the edges so Android's larger crop never shows a seam.
def scene(p):
    far, near = p["hills"]
    return ('<rect x="-100" y="-100" width="1224" height="1224" fill="url(#sky)"/>'
            + body(p)
            + f'<path d="M-40 772 C162 676, 383 682, 573 744 C740 798, 903 750, 1064 722 V1124 H-40Z" fill="{far}"/>'
            + f'<path d="M-40 818 C122 774, 285 766, 448 798 C657 834, 865 774, 1064 790 V1124 H-40Z" fill="{near}"/>')


def frame():
    return (f'<path d="M-100 -100 H1124 V1124 H-100Z {ARCH}" fill="#05040F" fill-rule="evenodd" opacity=".22"/>'
            f'<path d="{ARCH}" fill="none" stroke="#F2C46D" stroke-width="44" opacity=".35" filter="url(#glow)"/>'
            f'<path d="{ARCH}" fill="none" stroke="url(#gold)" stroke-width="30" stroke-linejoin="round"/>'
            f'<path d="{ARCH}" fill="none" stroke="#FFF6DC" stroke-opacity=".55" stroke-width="3" stroke-linejoin="round"/>')


def svg(inner, p):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">{defs(p)}{inner}</svg>'


def render(name, content):
    path = os.path.join(OUT, name + ".svg")
    with open(path, "w") as f:
        f.write(content)
    subprocess.run(["rsvg-convert", "-w", "1024", "-h", "1024", path,
                    "-o", os.path.join(OUT, name + ".png")], check=True)


for key, p in PRAYERS.items():
    render(f"wird-{key}", svg(scene(p) + frame(), p))

DEFAULT = "maghrib"
# Shrinks the arch into Android's 66/108 safe zone. Both adaptive layers use
# it, so the sky in the background lines up with the frame in front.
SAFE = '<g transform="translate(512 512) scale(.64) translate(-512 -500)">{}</g>'

# Android adaptive layers: each prayer's sky is the background, the frame
# (and the dimming outside it) the foreground.
for key, p in PRAYERS.items():
    suffix = "" if key == DEFAULT else f"-{key}"
    render(f"adaptive-background{suffix}", svg(SAFE.format(scene(p)), p))
    render(f"adaptive-foreground{suffix}", svg(SAFE.format(frame()), p))


def raster(src, size, dest):
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size), src, "-o", dest], check=True)


def opaque(src, size, dest):
    """iOS icons must not carry an alpha channel: round-trip through JPEG."""
    tmp = dest + ".jpg"
    raster(src, size, dest)
    subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "100", dest, "--out", tmp],
                   check=True, capture_output=True)
    subprocess.run(["sips", "-s", "format", "png", tmp, "--out", dest], check=True, capture_output=True)
    os.remove(tmp)


RES = "android/app/src/main/res"
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@drawable/ic_launcher_background_{key}"/>
  <foreground android:drawable="@drawable/ic_launcher_foreground_{key}"/>
</adaptive-icon>
"""
APPICONSET_JSON = """{
  "images" : [
    {
      "filename" : "icon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

for key in PRAYERS:
    full = os.path.join(OUT, f"wird-{key}.svg")
    # Settings picker thumbnails (56pt at 3x).
    raster(full, 168, os.path.join(OUT, "thumbs", f"{key}.png"))
    if key == DEFAULT:
        continue
    fg = os.path.join(OUT, f"adaptive-foreground-{key}.svg")
    bg = os.path.join(OUT, f"adaptive-background-{key}.svg")
    for dpi, scale in DENSITIES.items():
        raster(full, round(48 * scale), f"{RES}/mipmap-{dpi}/ic_launcher_{key}.png")
        raster(fg, round(108 * scale), f"{RES}/drawable-{dpi}/ic_launcher_foreground_{key}.png")
        raster(bg, round(108 * scale), f"{RES}/drawable-{dpi}/ic_launcher_background_{key}.png")
    with open(f"{RES}/mipmap-anydpi-v26/ic_launcher_{key}.xml", "w") as f:
        f.write(ADAPTIVE_XML.format(key=key))
    iconset = f"ios/Runner/Assets.xcassets/AppIcon-{key}.appiconset"
    opaque(full, 1024, f"{iconset}/icon.png")
    with open(f"{iconset}/Contents.json", "w") as f:
        f.write(APPICONSET_JSON)
