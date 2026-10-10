"""Puts real TrueLedger screenshots into the two phones of the marketing banner.

Usage (from the repo root; needs Pillow and numpy):
  python3 tool/compose_banner.py <home.png> <transactions.png> <out.png>

The banner is marketing/brand/banner_original.jpg (2000x1342). Positions were
measured from it. The front phone's screen shows <home>; the back phone's
(partly hidden) screen shows <transactions>. The front phone's shadow on the
back screen, the "100% Offline" badge and the phone bezels are kept from the
original, so only the screen contents change.
"""
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

BANNER = "marketing/brand/banner_original.jpg"
SS = 4  # supersampling for smooth mask edges

FRONT = dict(box=(1095, 159, 1548, 1167), radius=66, island=(1248, 172, 1395, 215))
BACK = dict(box=(1515, 382, 1926, 1245), radius=54, island=(1668, 393, 1793, 428))
FRONT_OUTER = dict(box=(1074, 138, 1570, 1188), radius=87)  # front phone incl. bezel
BADGE = dict(box=(1456, 211, 1838, 344), radius=40)


def rrect_mask(size, box, radius, grow=0):
    """Anti-aliased rounded-rectangle mask (L) the size of the banner."""
    w, h = size
    m = Image.new("L", (w * SS, h * SS), 0)
    x0, y0, x1, y1 = box
    ImageDraw.Draw(m).rounded_rectangle(
        [(x0 - grow) * SS, (y0 - grow) * SS, (x1 + grow) * SS - 1, (y1 + grow) * SS - 1],
        radius=(radius + grow) * SS,
        fill=255,
    )
    return m.resize((w, h), Image.LANCZOS)


def fit_screen(path, box):
    """Scale the screenshot to cover the screen box, cropping a sliver."""
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    s = Image.open(path).convert("RGB")
    k = max(w / s.width, h / s.height)
    s = s.resize((round(s.width * k), round(s.height * k)), Image.LANCZOS)
    left = (s.width - w) // 2
    return s.crop((left, 0, left + w, h))


def main(home, tx, out):
    banner = Image.open(BANNER).convert("RGB")
    W, H = banner.size
    orig = banner.copy()
    arr = np.asarray(orig).astype(np.float32)

    front_outer = rrect_mask((W, H), FRONT_OUTER["box"], FRONT_OUTER["radius"], grow=1)
    badge = rrect_mask((W, H), BADGE["box"], BADGE["radius"], grow=3)

    # --- back phone -------------------------------------------------------
    bx0, by0, bx1, by1 = BACK["box"]
    screen_b = rrect_mask((W, H), BACK["box"], BACK["radius"])
    visible_b = np.asarray(screen_b).astype(np.float32) / 255
    visible_b *= 1 - np.asarray(front_outer).astype(np.float32) / 255
    visible_b *= 1 - np.asarray(badge).astype(np.float32) / 255

    # The front phone's shadow on the back screen, read from the original:
    # the brightest values (screen background) form the lighting envelope.
    lum = (arr[..., 0] * 0.299 + arr[..., 1] * 0.587 + arr[..., 2] * 0.114)
    region = lum.copy()
    hidden = (visible_b < 0.5)
    region[hidden] = 0
    crop = Image.fromarray(region.astype(np.uint8)).crop((bx0, by0, bx1, by1))
    env = crop.filter(ImageFilter.MaxFilter(41)).filter(ImageFilter.GaussianBlur(10))
    env = np.asarray(env).astype(np.float32)
    far = np.median(env[:, -60:-10], axis=1, keepdims=True)  # unshadowed side
    far = np.asarray(
        Image.fromarray(far.astype(np.uint8)).filter(ImageFilter.GaussianBlur(6))
    ).astype(np.float32)
    factor = np.clip(env / np.maximum(far, 1), 0.35, 1.0)
    factor = np.where(env < 20, 1.0, factor)

    new_b = np.asarray(fit_screen(tx, BACK["box"])).astype(np.float32)
    new_b = new_b * factor[..., None]
    layer = arr.copy()
    layer[by0:by1, bx0:bx1] = new_b
    a = visible_b[..., None]
    arr = arr * (1 - a) + layer * a

    # --- front phone ------------------------------------------------------
    fx0, fy0, fx1, fy1 = FRONT["box"]
    screen_f = np.asarray(rrect_mask((W, H), FRONT["box"], FRONT["radius"])).astype(np.float32) / 255
    new_f = np.asarray(fit_screen(home, FRONT["box"])).astype(np.float32)
    layer = arr.copy()
    layer[fy0:fy1, fx0:fx1] = new_f
    a = screen_f[..., None]
    arr = arr * (1 - a) + layer * a

    # --- dynamic islands --------------------------------------------------
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    for phone in (FRONT, BACK):
        x0, y0, x1, y1 = phone["island"]
        m = Image.new("L", (W * SS, H * SS), 0)
        ImageDraw.Draw(m).rounded_rectangle(
            [x0 * SS, y0 * SS, x1 * SS, y1 * SS], radius=(y1 - y0) * SS // 2, fill=255
        )
        m = m.resize((W, H), Image.LANCZOS)
        img = Image.composite(Image.new("RGB", (W, H), (4, 4, 6)), img, m)

    # --- the badge stays on top of everything ------------------------------
    img = Image.composite(orig, img, badge)
    img.save(out)
    print("wrote", out, img.size)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
