#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
make_modsettings_atlas.py
=========================
Build a PNG sprite-sheet ("atlas") for the enhanced modsSettingsApi `createImage` atlas feature,
so an animation can loop inside a mod's in-garage settings menu.

Input can be:
  * a FOLDER of frame images (numbered, sorted naturally: 1,2,...,10,11)
  * an animated .GIF
  * a .SWF  -> frames are pulled straight from a DefineSprite via FFDec (JPEXS), then packed

It outputs one grid PNG and prints the exact `atlas={...}` parameters you paste into createImage.

----------------------------------------------------------------------------------------------------
USAGE
  python make_modsettings_atlas.py <input> [options]

  <input>                 a FOLDER of frames, a .gif, or a .swf

  -o,  --out   PATH       output atlas PNG (default: atlas.png)
  -c,  --columns N        grid columns (default 0 = auto, near-square)
       --fps    N         playback speed written into the params (default 24)
       --fw     N         FRAME width  in px per cell (default 0 = keep source width)
       --fh     N         FRAME height in px per cell (default 0 = keep source height)
       --range  A:B       use only frames A..B (1-based, inclusive) e.g. 3:28 to drop intro/outro
       --no-loop          mark the animation as non-looping (default: loops)
       --bg     R,G,B,A   flatten onto this background instead of keeping transparency

  SWF-only:
       --sprite ID        which DefineSprite (character id) to pull frames from
       --ffdec  PATH      path to ffdec-cli.exe (auto-detected if installed normally)

  If you pass a .swf WITHOUT --sprite, the tool lists the sprites (id + frame count, animations
  first) so you can pick one, then re-run with --sprite <id>.

EXAMPLES
  # 30 PNG frames in ./frames, force 96x96 cells, 6 columns, 24 fps:
  python make_modsettings_atlas.py ./frames -o marker_fx_atlas.png --fw 96 --fh 96 -c 6 --fps 24

  # straight from a gif, keep its size, auto grid:
  python make_modsettings_atlas.py anim.gif -o anim_atlas.png --fps 20

  # from a swf: first see what sprites it has...
  python make_modsettings_atlas.py effects.swf
  # ...then pull sprite 883, frames 3..28, into 96x96 cells:
  python make_modsettings_atlas.py effects.swf --sprite 883 --range 3:28 --fw 96 --fh 96 -c 6

----------------------------------------------------------------------------------------------------
HOW TO USE THE RESULT IN YOUR MOD
  1) The lobby image loader reads the REAL `mods/` folder on disk, NOT the .wotmod VFS, so put the
     atlas PNG under e.g.  mods/configs/<You>/<yourmod>/  (ship it there, or write it from the mod).
     `img://` paths do NOT work for createImage - use a plain relative path under mods/.
  2) Call createImage with both `source` and the `atlas` dict (paste the block this tool prints):

       templates.createImage(
           'mods/configs/You/yourmod/anim_atlas.png',   # source (display)
           width=60, height=60, varName='preview',      # the on-screen size you want
           atlas={'source': 'mods/configs/You/yourmod/anim_atlas.png',
                  'frameWidth': 96, 'frameHeight': 96, 'columns': 6, 'count': 30,
                  'fps': 24, 'loop': True},
           align='center', valign='center',
           containerWidth=80, containerHeight=80,
           tooltip=...)

  Frames are laid out left-to-right, top-to-bottom. `width`/`height` are the DISPLAYED size
  (downscaling looks best - avoid upscaling above the cell size). Use updateImageAtlas(varName, ...)
  to swap it live.
----------------------------------------------------------------------------------------------------
Requires Pillow:  python -m pip install Pillow
FFDec (only for .swf input): https://github.com/jindrapetrik/jpexs-decompiler  (ffdec-cli.exe)
"""
import argparse
import glob
import math
import os
import re
import shutil
import subprocess
import sys
import tempfile

try:
    from PIL import Image
except ImportError:
    sys.exit("This tool needs Pillow. Install it with:\n    python -m pip install Pillow")

_IMG_EXT = ('.png', '.gif', '.bmp', '.jpg', '.jpeg', '.webp', '.tga')
_FFDEC_GUESSES = (
    r'C:\Program Files (x86)\FFDec\ffdec-cli.exe',
    r'C:\Program Files\FFDec\ffdec-cli.exe',
    r'C:\Program Files (x86)\JPEXS\ffdec-cli.exe',
)


def _natural_key(name):
    return [int(t) if t.isdigit() else t.lower() for t in re.split(r'(\d+)', name)]


# ---------------------------------------------------------------------------- SWF (via FFDec)

def _find_ffdec(arg):
    for c in ([arg] if arg else []) + list(_FFDEC_GUESSES):
        if c and os.path.isfile(c):
            return c
    found = shutil.which('ffdec-cli') or shutil.which('ffdec-cli.exe')
    return found


def _ffdec_dump(ffdec, swf):
    try:
        out = subprocess.check_output([ffdec, '-dumpSWF', swf], stderr=subprocess.STDOUT)
    except Exception as e:
        sys.exit("FFDec -dumpSWF failed: %s" % e)
    return out.decode('utf-8', 'replace')


def _list_sprites(ffdec, swf):
    # Parse DefineSprite tags: the tag data begins SpriteID(UI16 LE) + FrameCount(UI16 LE), and dumpSWF
    # prints those first bytes, so we read the frame count cheaply without rendering anything.
    rows = []
    pat = re.compile(r'DefineSprite \(chid:\s*(\d+)\).*?len=\s*\d+\s+([0-9a-fA-F ]+)')
    for m in pat.finditer(_ffdec_dump(ffdec, swf)):
        chid = int(m.group(1))
        b = [x for x in m.group(2).split() if len(x) == 2][:4]
        frames = (int(b[2], 16) | (int(b[3], 16) << 8)) if len(b) >= 4 else 0
        rows.append((chid, frames))
    return rows


def _extract_sprite(ffdec, swf, sprite_id, tmp):
    r = subprocess.run([ffdec, '-selectid', str(sprite_id), '-export', 'sprite', tmp, swf],
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    pngs = sorted(glob.glob(os.path.join(tmp, '**', '*.png'), recursive=True), key=_natural_key)
    if not pngs:
        msg = r.stdout.decode('utf-8', 'replace') if r.stdout else ''
        sys.exit("FFDec exported no frames for sprite %s. Is the id right?\n%s" % (sprite_id, msg[-500:]))
    return pngs


def _handle_swf(args):
    ffdec = _find_ffdec(args.ffdec)
    if not ffdec:
        sys.exit("FFDec not found. Install JPEXS or pass --ffdec C:\\path\\to\\ffdec-cli.exe")
    if not args.sprite:
        rows = _list_sprites(ffdec, args.input)
        if not rows:
            sys.exit("No DefineSprite tags found in %s" % args.input)
        rows.sort(key=lambda r: (-r[1], r[0]))
        print("\n  Sprites in %s (animations first):\n" % os.path.basename(args.input))
        print("    sprite id   frames")
        for chid, frames in rows[:40]:
            print("    %-10d  %d" % (chid, frames))
        print("\n  Re-run with the one you want, e.g.:")
        print("    python %s %s --sprite %d --range 1:%d --fw 96 --fh 96\n" % (
            os.path.basename(sys.argv[0]), args.input, rows[0][0], max(rows[0][1], 1)))
        sys.exit(0)
    tmp = tempfile.mkdtemp(prefix='atlas_swf_')
    frame_paths = _extract_sprite(ffdec, args.input, args.sprite, tmp)
    frames = [Image.open(p).convert('RGBA').copy() for p in frame_paths]
    shutil.rmtree(tmp, ignore_errors=True)
    return frames


# ---------------------------------------------------------------------------- folder / gif

def _load_folder_or_gif(src):
    if os.path.isfile(src) and src.lower().endswith('.gif'):
        im = Image.open(src)
        frames, i = [], 0
        try:
            while True:
                im.seek(i)
                frames.append(im.convert('RGBA').copy())
                i += 1
        except EOFError:
            pass
        if not frames:
            sys.exit("No frames found in gif: %s" % src)
        return frames
    if os.path.isdir(src):
        files = [f for f in os.listdir(src) if f.lower().endswith(_IMG_EXT)]
        files.sort(key=_natural_key)
        if not files:
            sys.exit("No image frames in folder: %s" % src)
        return [Image.open(os.path.join(src, f)).convert('RGBA') for f in files]
    sys.exit("Input must be a folder, a .gif, or a .swf: %s" % src)


# ---------------------------------------------------------------------------- main

def _parse_bg(text):
    parts = [int(x) for x in text.split(',')]
    while len(parts) < 4:
        parts.append(255 if len(parts) == 3 else 0)
    return tuple(parts[:4])


def _apply_range(frames, spec):
    try:
        a, b = spec.split(':')
        a, b = int(a), int(b)
    except Exception:
        sys.exit("--range must look like A:B (1-based, inclusive), e.g. 3:28")
    sub = frames[max(a, 1) - 1:b]
    if not sub:
        sys.exit("--range %s selected no frames (have %d)" % (spec, len(frames)))
    return sub


def main():
    ap = argparse.ArgumentParser(
        description="Pack animation frames (folder / gif / swf) into a PNG atlas for createImage.",
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('input', help='folder of frames, a .gif, or a .swf')
    ap.add_argument('-o', '--out', default='atlas.png', help='output atlas PNG (default atlas.png)')
    ap.add_argument('-c', '--columns', type=int, default=0, help='grid columns (0 = auto, near-square)')
    ap.add_argument('--fps', type=int, default=24, help='playback fps recorded in the params (default 24)')
    ap.add_argument('--fw', type=int, default=0, help='frame width px per cell (0 = source width)')
    ap.add_argument('--fh', type=int, default=0, help='frame height px per cell (0 = source height)')
    ap.add_argument('--range', dest='range', default=None, help='use only frames A:B (1-based, inclusive)')
    ap.add_argument('--no-loop', action='store_true', help='mark animation as non-looping')
    ap.add_argument('--bg', default=None, help='flatten onto R,G,B,A instead of keeping transparency')
    ap.add_argument('--sprite', type=int, default=None, help='[swf] DefineSprite character id to use')
    ap.add_argument('--ffdec', default=None, help='[swf] path to ffdec-cli.exe')
    args = ap.parse_args()

    if os.path.isfile(args.input) and args.input.lower().endswith('.swf'):
        frames = _handle_swf(args)
    else:
        frames = _load_folder_or_gif(args.input)

    if args.range:
        frames = _apply_range(frames, args.range)
    count = len(frames)

    fw = args.fw or frames[0].width
    fh = args.fh or frames[0].height
    cols = args.columns or int(math.ceil(math.sqrt(count)))
    cols = max(1, min(cols, count))
    rows = int(math.ceil(count / float(cols)))

    bg = _parse_bg(args.bg) if args.bg else (0, 0, 0, 0)
    atlas = Image.new('RGBA', (cols * fw, rows * fh), bg)

    upscaled = False
    for i, fr in enumerate(frames):
        if fr.size != (fw, fh):
            if fr.width < fw or fr.height < fh:
                upscaled = True
            fr = fr.resize((fw, fh), Image.LANCZOS)
        col, row = i % cols, i // cols
        atlas.paste(fr, (col * fw, row * fh), fr)

    out = args.out
    out_dir = os.path.dirname(os.path.abspath(out))
    if out_dir and not os.path.isdir(out_dir):
        os.makedirs(out_dir)
    atlas.save(out, 'PNG')

    loop = not args.no_loop
    params = ("{{'source': <same path as source>, 'frameWidth': {fw}, 'frameHeight': {fh}, "
              "'columns': {cols}, 'count': {count}, 'fps': {fps}, 'loop': {loop}}}").format(
                  fw=fw, fh=fh, cols=cols, count=count, fps=args.fps, loop=loop)

    print("")
    print("  Atlas written: %s" % os.path.abspath(out))
    print("  Sheet size   : %d x %d px   (%d cols x %d rows, %d frames)" % (
        cols * fw, rows * fh, cols, rows, count))
    print("  Cell size    : %d x %d px" % (fw, fh))
    if upscaled:
        print("  WARNING: some frames were smaller than the cell and got UPSCALED - they may look soft.")
    print("")
    print("  Paste this atlas= into your createImage call:")
    print("  atlas=%s" % params)
    print("")

    try:
        with open(os.path.splitext(out)[0] + '_atlas.txt', 'w') as fh_:
            fh_.write("frameWidth=%d\nframeHeight=%d\ncolumns=%d\ncount=%d\nfps=%d\nloop=%s\n" % (
                fw, fh, cols, count, args.fps, loop))
    except Exception:
        pass


if __name__ == '__main__':
    main()
