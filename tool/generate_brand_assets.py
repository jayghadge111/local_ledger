"""Redraws the TrueLedger "T with a keyhole" logo and writes every brand asset.

Run from the repo root:  python3 tool/generate_brand_assets.py
Needs Pillow (pip3 install pillow). The geometry below was measured from
marketing/brand/trueledger_logo_original.jpg (2000x2000), so the redraw matches
the original; everything is drawn at 4x and scaled down for clean edges.
After running, regenerate the platform icons and splash:
  dart run flutter_launcher_icons && dart run flutter_native_splash:create
"""
from PIL import Image, ImageDraw

BG = (16, 33, 49)        # #102131
FG = (193, 230, 249)     # #C1E6F9

# Geometry in the original's pixels. T bounding box is 431..1568 x 432..1567.
T_W = 1137.0
BAR = (431, 432, 1568, 734)
STEM = (752, 700, 1247, 1567)
SLIT = (979, 400, 1020, 1600)          # the thin vertical gap
KEY_C = (1000, 977)                     # keyhole circle centre
KEY_R = 107
NECK = [(958, 1040), (1042, 1040), (1092, 1274), (908, 1274)]
CORNER = 30
CX, CY = 999.5, 999.5                   # centre of the T


def glyph_mask(size, width_frac, ss=4):
    """White T with the slit and keyhole cut out, on a transparent (L) mask."""
    n = size * ss
    k = n * width_frac / T_W
    ox, oy = n / 2 - CX * k, n / 2 - CY * k

    def p(x, y):
        return (ox + x * k, oy + y * k)

    def rect(box):
        a, b = p(box[0], box[1]), p(box[2], box[3])
        return [a[0], a[1], b[0], b[1]]

    m = Image.new("L", (n, n), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle(rect(BAR), radius=CORNER * k, fill=255)
    d.rounded_rectangle(rect(STEM), radius=CORNER * k, fill=255)
    d.rectangle(rect(SLIT), fill=0)
    c = p(*KEY_C)
    r = KEY_R * k
    d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=0)
    d.polygon([p(*q) for q in NECK], fill=0)
    return m.resize((size, size), Image.LANCZOS)


def tile(size, width_frac, bg=BG, fg=FG, rounded=None):
    img = Image.new("RGB", (size, size), bg)
    mask = glyph_mask(size, width_frac)
    img.paste(Image.new("RGB", (size, size), fg), (0, 0), mask)
    if rounded:
        a = Image.new("L", (size * 4, size * 4), 0)
        ImageDraw.Draw(a).rounded_rectangle(
            [0, 0, size * 4 - 1, size * 4 - 1], radius=rounded * size * 4, fill=255
        )
        out = img.convert("RGBA")
        out.putalpha(a.resize((size, size), Image.LANCZOS))
        return out
    return img


def glyph(size, width_frac, color):
    mask = glyph_mask(size, width_frac)
    out = Image.new("RGBA", (size, size), color + (0,))
    out.putalpha(mask)
    return out


# iOS / master: full-bleed tile, no transparency (the OS rounds the corners).
tile(1024, 0.657).save("assets/icon/icon_master.png")
# Android adaptive icon. flutter_launcher_icons adds a 16% inset on each side,
# so draw the T large here; it still lands inside the safe zone.
glyph(1024, 0.60, FG).save("assets/icon/icon_foreground.png")
glyph(1024, 0.60, (255, 255, 255)).save("assets/icon/icon_monochrome.png")
# Android 12 splash crops its icon to a circle two thirds the size: keep it small.
glyph(1024, 0.42, FG).save("assets/icon/splash_android12.png")
# Native splash mark: the full tile, so it carries straight into the in-app
# splash (which draws the same tile) on both the light and dark launch colours.
tile(512, 0.657, rounded=112 / 512).save("assets/icon/splash_mark.png")
# Web / PWA icon.
tile(1024, 0.657).save("assets/icon/web_icon.png")


def svg(rounded):
    # Same geometry, 512 box, T width = 0.657 of the tile.
    k = 512 * 0.657 / T_W
    ox, oy = 256 - CX * k, 256 - CY * k
    f = lambda v, o: round(o + v * k, 2)
    bar = (f(BAR[0], ox), f(BAR[1], oy), round((BAR[2] - BAR[0]) * k, 2), round((BAR[3] - BAR[1]) * k, 2))
    stem = (f(STEM[0], ox), f(STEM[1], oy), round((STEM[2] - STEM[0]) * k, 2), round((STEM[3] - STEM[1]) * k, 2))
    slit = (f(SLIT[0], ox), f(SLIT[1], oy), round((SLIT[2] - SLIT[0]) * k, 2), round((SLIT[3] - SLIT[1]) * k, 2))
    cx, cy, r = f(KEY_C[0], ox), f(KEY_C[1], oy), round(KEY_R * k, 2)
    neck = " ".join(f"{f(x, ox)},{f(y, oy)}" for x, y in NECK)
    rc = round(CORNER * k, 2)
    tilerect = (
        f'<rect width="512" height="512" rx="112" fill="#102131"/>'
        if rounded
        else '<rect width="512" height="512" fill="#102131"/>'
    )
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  {tilerect}
  <g fill="#C1E6F9">
    <rect x="{bar[0]}" y="{bar[1]}" width="{bar[2]}" height="{bar[3]}" rx="{rc}"/>
    <rect x="{stem[0]}" y="{stem[1]}" width="{stem[2]}" height="{stem[3]}" rx="{rc}"/>
  </g>
  <g fill="#102131">
    <rect x="{slit[0]}" y="{slit[1]}" width="{slit[2]}" height="{slit[3]}"/>
    <circle cx="{cx}" cy="{cy}" r="{r}"/>
    <polygon points="{neck}"/>
  </g>
</svg>
'''


open("assets/brand/trueledger_icon.svg", "w").write(svg(True))
open("assets/brand/launcher_full_bleed.svg", "w").write(svg(False))
print("brand assets written")
