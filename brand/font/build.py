"""Wordroot Sans: a neutral grotesque, proportionally spaced, drawn as code. Flat-cut terminals,
sharp joins, squarish rounds, Helvetica-like proportions.

Every glyph is a few centerline strokes. A stroke is a polyline, buffered to the weight
with round caps and joins, then written out as TrueType outlines. Two weights come from
one drawing. Run: uv run --with fonttools --with shapely --with brotli python brand/font/build.py
Latin only (plus the macrons and accents the etymology text needs). Other scripts fall
through to the system font in the stack.
"""
import math, unicodedata, os, sys
from shapely.geometry import LineString, Point
from shapely.geometry.polygon import orient
from shapely.ops import unary_union
from shapely import affinity
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

UPM, CAP, XH, ASC, DESC = 1000, 710, 520, 735, -210
OUT = os.path.dirname(os.path.abspath(__file__))

def arc(cx, cy, rx, ry, a0, a1, n=28, e=2.3):
    """Points on a superellipse (e=2 is a circle). e a bit above 2 squares the curve, like a grotesque."""
    out = []
    for i in range(n + 1):
        a = math.radians(a0 + (a1 - a0) * i / n)
        c, sn = math.cos(a), math.sin(a)
        out.append((cx + rx * math.copysign(abs(c) ** (2 / e), c), cy + ry * math.copysign(abs(sn) ** (2 / e), sn)))
    return out

def line_at(p, q, y=None, x=None):
    t = (y - p[1]) / (q[1] - p[1]) if y is not None else (x - p[0]) / (q[0] - p[0])
    return (p[0] + t * (q[0] - p[0]), p[1] + t * (q[1] - p[1]))

def design(sw):
    """Return {char: (strokes, dots, inner_width, left_bearing, right_bearing)}.
    Strokes are polylines of centerline points; dots are (x, y, radius)."""
    b = sw / 2
    T, B, X, A, D = CAP - b, b, XH - b, ASC - b, DESC + b
    M = (T + B) / 2 + 8           # cap middle
    m = (X + B) / 2               # x-height middle
    g = {}
    def add(ch, strokes, w, lb=52, rb=52, dots=()):
        pad = 26 if w == 0 and ch != ' ' else 9   # thin stems and punctuation need more air
        if ch == ' ': pad = 0
        g[ch] = (strokes, list(dots), w, lb + pad, rb + pad)

    # ---- capitals
    add('A', [[(0, B), (290, T), (580, B)], [(110, 215), (470, 215)]], 580, 28, 28)
    r1, r2 = (T - M) / 2, (M - B) / 2
    add('B', [[(0, B), (0, T)],
              [(0, T), (250, T)] + arc(250, T - r1, r1, r1, 90, -90) + [(0, M)],
              [(0, M), (270, M)] + arc(270, M - r2, r2, r2, 90, -90) + [(0, B)]], 360)
    add('C', [arc(250, (T + B) / 2, 250, (T - B) / 2, 42, 318)], 500, 46, 40)
    add('D', [[(0, B), (0, T), (200, T)] + arc(200, (T + B) / 2, 270, (T - B) / 2, 90, -90) + [(200, B), (0, B)]], 470)
    add('E', [[(0, T), (0, B)], [(0, T), (360, T)], [(0, M), (320, M)], [(0, B), (370, B)]], 370)
    add('F', [[(0, T), (0, B)], [(0, T), (360, T)], [(0, M), (320, M)]], 360)
    add('G', [arc(260, (T + B) / 2, 260, (T - B) / 2, 42, 360) + [(270, M - 6), (270, M + 0)], [(520, M), (280, M)]], 520, 46, 48)
    add('H', [[(0, T), (0, B)], [(440, T), (440, B)], [(0, M), (440, M)]], 440)
    add('I', [[(0, T), (0, B)]], 0, 56, 56)
    add('J', [[(330, T), (330, B + 170)] + arc(160, B + 170, 170, 170, 0, -180)[1:] if False else [(330, T), (330, B + 160)] + arc(165, B + 160, 165, 160, 0, -180)], 330, 36, 52)
    kd = line_at((0, M), (400, T), x=140)
    add('K', [[(0, T), (0, B)], [(400, T), (0, M)], [kd, (410, B)]], 410, 52, 36)
    add('L', [[(0, T), (0, B), (340, B)]], 340, 52, 40)
    add('M', [[(0, B), (0, T), (290, B), (580, T), (580, B)]], 580)
    add('N', [[(0, B), (0, T), (450, B), (450, T)]], 450)
    ellO = arc(270, (T + B) / 2, 270, (T - B) / 2, 90, 450, 48)
    add('O', [ellO], 540, 42, 42)
    rp = (T - M) * 0.5 + 18
    bowlP = [(0, T), (270 - rp * 0 + 0, T)] + arc(270, T - rp, rp, rp, 90, -90) + [(0, T - 2 * rp)]
    add('P', [[(0, B), (0, T)], bowlP], 400, 52, 40)
    add('Q', [ellO, [(300, 190), (520, B - 30)]], 540, 42, 42)
    add('R', [[(0, B), (0, T)], bowlP, [(210, T - 2 * rp), (420, B)]], 420, 52, 36)
    rs = (T - B) / 4
    S = arc(240, T - rs, 230, rs, 28, 270, 24) + arc(240, B + rs, 230, rs, 90, -152, 24)
    add('S', [S], 470, 38, 38)
    add('T', [[(0, T), (500, T)], [(250, T), (250, B)]], 500, 22, 22)
    add('U', [[(0, T), (0, B + 235)] + arc(235, B + 235, 235, 235, 180, 360) + [(470, T)]], 470, 50, 50)
    add('V', [[(0, T), (290, B), (580, T)]], 580, 24, 24)
    add('W', [[(0, T), (215, B), (430, T - 60), (645, B), (860, T)]], 860, 24, 24)
    add('X', [[(0, T), (500, B)], [(500, T), (0, B)]], 500, 30, 30)
    add('Y', [[(0, T), (290, 290), (580, T)], [(290, 290), (290, B)]], 580, 24, 24)
    add('Z', [[(0, T), (440, T), (0, B), (460, B)]], 460, 40, 40)

    # ---- lowercase
    rx, ry = 235, (X - B) / 2
    bowl = arc(rx, m, rx, ry, 90, 450, 48)
    w = 2 * rx
    add('o', [bowl], w, 40, 40)
    rt, rb = 150, 118
    wa = 2 * rx
    add('a', [arc(wa / 2, X - rt, wa / 2, rt, 166, 0, 24) + [(wa, B)],
              [(wa, B + 2 * rb), (wa / 2 - 8, B + 2 * rb)] + arc(wa / 2 - 8, B + rb, wa / 2 - 8, rb, 90, 270, 20) + [(wa, B)]], wa, 40, 52)
    add('b', [[(0, A), (0, B)], arc(rx, m, rx, ry, 180, 540, 48)], w, 52, 40)
    add('d', [[(w, A), (w, B)], arc(rx, m, rx, ry, 0, 360, 48)], w, 40, 52)
    add('p', [[(0, X), (0, D)], arc(rx, m, rx, ry, 180, 540, 48)], w, 52, 40)
    add('q', [[(w, X), (w, D)], arc(rx, m, rx, ry, 0, 360, 48)], w, 40, 52)
    add('c', [arc(235, m, 235, ry, 42, 318)], 470, 40, 28)
    add('e', [[(0, m), (w, m)] + arc(rx, m, rx, ry, 0, 318, 40)], w, 40, 34)
    add('f', [[(112, B), (112, A - 105)] + arc(215, A - 105, 103, 105, 180, 62, 12), [(0, X), (255, X)]], 255, 20, 6)
    add('g', [arc(rx, m, rx, ry, 0, 360, 48), [(w, X), (w, D + 150)] + arc(w - 150, D + 150, 150, 150, 0, -150)], w, 40, 52)
    add('h', [[(0, A), (0, B)], [(0, X - 195)] + arc(195, X - 195, 195, 195, 180, 0, 28)[1:] + [(390, B)]], 390, 52, 52)
    add('i', [[(0, X), (0, B)]], 0, 56, 56, dots=[(0, X + 150, b * 1.15)])
    add('j', [[(130, X), (130, D + 130)] + arc(0, D + 130, 130, 130, 0, -150)], 130, 20, 54, dots=[(130, X + 150, b * 1.15)])
    kd2 = line_at((380, X), (0, m * 0.85), x=130)
    add('k', [[(0, A), (0, B)], [(380, X), (0, m * 0.85)], [kd2, (390, B)]], 390, 52, 30)
    add('l', [[(0, A), (0, B)]], 0, 56, 56)
    add('m', [[(0, X), (0, B)], [(0, X - 165)] + arc(165, X - 165, 165, 165, 180, 0, 24)[1:] + [(330, B)], [(330, X - 165)] + arc(495, X - 165, 165, 165, 180, 0, 24)[1:] + [(660, B)]], 660, 52, 52)
    add('n', [[(0, X), (0, B)], [(0, X - 195)] + arc(195, X - 195, 195, 195, 180, 0, 28)[1:] + [(390, B)]], 390, 52, 52)
    add('r', [[(0, X), (0, B)], [(0, X - 150)] + arc(165, X - 150, 165, 150, 180, 70, 16)[1:]], 250, 52, 8)
    rs2 = (X - B) / 4
    add('s', [arc(200, X - rs2, 190, rs2, 28, 270, 20) + arc(200, B + rs2, 190, rs2, 90, -152, 20)], 390, 36, 36)
    add('t', [[(100, 650 - b), (100, B + 110)] + arc(210, B + 110, 110, 110, 180, 270, 14) + [(260, B)], [(0, X), (270, X)]], 270, 22, 14)
    add('u', [[(0, X), (0, B + 195)] + arc(195, B + 195, 195, 195, 180, 360, 28) + [(390, X)], [(390, X), (390, B)]], 390, 52, 52)
    add('v', [[(0, X), (230, B), (460, X)]], 460, 24, 24)
    add('w', [[(0, X), (190, B), (380, X - 40), (570, B), (760, X)]], 760, 24, 24)
    add('x', [[(0, X), (420, B)], [(420, X), (0, B)]], 420, 30, 30)
    yr = ((380, X), (70, D))
    ym = line_at(yr[0], yr[1], y=B)
    add('y', [[(0, X), ym], [yr[0], yr[1]]], 380, 24, 24)
    add('z', [[(0, X), (360, X), (0, B), (380, B)]], 380, 38, 38)

    # ---- digits
    add('0', [arc(215, (T + B) / 2, 215, (T - B) / 2, 90, 450, 48)], 430, 44, 44)
    add('1', [[(20, T - 90), (170, T), (170, B)]], 170, 60, 56)
    add('2', [arc(210, T - 175, 190, 175, 165, -35, 24) + [(0, B), (410, B)]], 410, 44, 44)
    mid3 = (T + B) / 2 + 10
    ru, rl = (T - mid3) / 2, (mid3 - B) / 2
    add('3', [arc(200, T - ru, 180, ru, 150, -90, 24) + arc(200, B + rl, 200, rl, 90, -150, 24)], 400, 44, 44)
    add('4', [[(300, B), (300, T), (0, 200), (410, 200)]], 410, 28, 28)
    add('5', [[(380, T), (60, T), (30, 340)] + arc(205, 235, 215, 230, 130, -135, 30)], 420, 44, 40)
    rb6 = 235
    six = [arc(215, B + rb6, 215, rb6, 0, 360, 40), [(0, B + rb6), (0, T - 215)] + arc(215, T - 215, 215, 215, 180, 48, 20)]
    add('6', six, 430, 44, 44)
    add('7', [[(0, T), (410, T), (140, B)]], 410, 38, 38)
    mid8 = (T + B) / 2 + 10
    ru8, rl8 = (T - mid8) / 2, (mid8 - B) / 2
    add('8', [arc(205, T - ru8, 175, ru8, 0, 360, 36), arc(205, B + rl8, 200, rl8, 0, 360, 36)], 410, 44, 44)
    add('9', [[(430 - x, T + B - y) for x, y in st] for st in six], 430, 44, 44)

    # ---- punctuation
    add(' ', [], 220, 0, 0)
    add('.', [], 0, 56, 56, dots=[(0, b * 1.25, b * 1.25)])
    add(',', [[(0, 20), (-28, -105)]], 0, 56, 56, dots=[(0, b * 1.25, b * 1.25)])
    add(':', [], 0, 56, 56, dots=[(0, b * 1.25, b * 1.25), (0, X - b * 0.3, b * 1.25)])
    add(';', [[(0, 20), (-28, -105)]], 0, 56, 56, dots=[(0, b * 1.25, b * 1.25), (0, X - b * 0.3, b * 1.25)])
    add('!', [[(0, T), (0, 215)]], 0, 56, 56, dots=[(0, b * 1.25, b * 1.25)])
    add('?', [arc(200, T - 165, 185, 165, 160, -70, 24) + [(200, 255), (200, 215)]], 400, 44, 44, dots=[(200, b * 1.25, b * 1.25)])
    add("'", [[(0, T), (0, 480)]], 0, 56, 56)
    add('"', [[(0, T), (0, 480)], [(150, T), (150, 480)]], 150, 56, 56)
    g['’'] = g["'"]; g['‘'] = g["'"]
    g['“'] = g['"']; g['”'] = g['"']
    add('-', [[(0, 300), (230, 300)]], 230, 40, 40)
    add('–', [[(0, 300), (380, 300)]], 380, 40, 40)
    add('—', [[(0, 300), (700, 300)]], 700, 40, 40)
    add('·', [], 0, 56, 56, dots=[(0, 320, b * 1.25)])
    add('(', [arc(260, 250, 260, 460, 118, 242, 24)], 160, 40, 30)
    add(')', [arc(-100, 250, 260, 460, 62, -62, 24)], 160, 30, 40)
    add('/', [[(0, B - 40), (320, T + 10)]], 320, 24, 24)
    add('+', [[(0, 330), (330, 330)], [(165, 165), (165, 495)]], 330, 52, 52)
    add('=', [[(0, 250), (330, 250)], [(0, 400), (330, 400)]], 330, 52, 52)
    add('_', [[(0, -90), (480, -90)]], 480, 0, 0)
    g['…'] = ([], [(0, b * 1.25, b * 1.25), (230, b * 1.25, b * 1.25), (460, b * 1.25, b * 1.25)], 460, 56, 56)

    # ---- accent marks, as centerline strokes around x=0 at y=0 (placed later)
    return g

def marks(sw):
    b = sw / 2
    return {
        '̀': ([[(-50, 60), (30, -15)]], []),                      # grave
        '́': ([[(-30, -15), (50, 60)]], []),                      # acute
        '̂': ([[(-62, -10), (0, 52), (62, -10)]], []),            # circumflex
        '̌': ([[(-62, 52), (0, -10), (62, 52)]], []),             # caron
        '̃': ([arc(0, 0, 70, 22, 200, 340, 12)[:0] or [(-72, 6), (-40, 34), (0, 12), (40, -14), (72, 14)]], []),  # tilde
        '̄': ([[(-62, 20), (62, 20)]], []),                       # macron
        '̈': ([], [(-48, 20, b * 1.1), (48, 20, b * 1.1)]),       # diaeresis
        '̊': ([arc(0, 24, 34, 34, 0, 360, 24)], []),              # ring
    }


ADV = {'A':667,'B':667,'C':722,'D':722,'E':667,'F':611,'G':778,'H':722,'I':278,'J':500,'K':667,'L':556,'M':833,
       'N':722,'O':778,'P':667,'Q':778,'R':722,'S':667,'T':611,'U':722,'V':667,'W':944,'X':667,'Y':667,'Z':611,
       'a':556,'b':556,'c':500,'d':556,'e':556,'f':278,'g':556,'h':556,'i':222,'j':222,'k':500,'l':222,'m':833,
       'n':556,'o':556,'p':556,'q':556,'r':333,'s':500,'t':278,'u':556,'v':500,'w':722,'x':500,'y':500,'z':500,
       '0':556,'1':556,'2':556,'3':556,'4':556,'5':556,'6':556,'7':556,'8':556,'9':556,
       ' ':278,'.':278,',':278,':':278,';':278,'!':278,'?':556,"'":191,'"':355,'-':333,'(':333,')':333,'/':278,
       '+':584,'=':584,'_':556,'\u00b7':278,'\u2013':556,'\u2014':1000}

def fit(ch, strokes, dots, w, lb, rb, sw):
    """Scale a glyph's centerline to a target advance, with even side bearings."""
    adv = ADV.get(ch)
    if adv is None:
        return strokes, dots, w, lb, rb
    if w == 0:
        e = (adv - sw) / 2
        return strokes, dots, 0, e, e
    diag = (lb + rb) < 70
    sb = 14 if diag else (56 if ch.isupper() else (42 if ch.isdigit() else 34))
    wt = adv - sw - 2 * sb
    k = wt / w
    if not 0.7 <= k <= 1.4:
        # a narrow letter (1 f t r): keep its drawing and just centre it in the advance
        e = max(4, (adv - sw - w) / 2)
        return strokes, dots, w, e, e
    return ([[(x * k, y) for x, y in st] for st in strokes], [(x * k, y, r) for x, y, r in dots], wt, sb, sb)

def clip_for(ch):
    if ch in ',;':
        return -215, 900
    if ch.islower():
        return (-215 if ch in 'gjpqy' else -10), ((ASC + 10) if ch in 'bdfhijklt' else (XH + 10))
    if ch.isupper() or ch.isdigit():
        return -10, CAP + 10
    return None

COMBOS = {'̀': 'AEIOUaeiou', '́': 'AEIOUYaeiouyCcNnSsZz', '̂': 'AEIOUaeiou',
          '̃': 'ANOanoUu', '̄': 'AEIOUaeiou', '̈': 'AEIOUaeiouy',
          '̊': 'Aa', '̌': 'CcSsZzEeRrNn', '̧': 'Cc'}

def build(weight_name, sw, path):
    b = sw / 2
    base = {ch: fit(ch, *v, sw) for ch, v in design(sw).items()}
    from shapely.geometry import box
    mk = marks(sw)
    glyphs = {}   # name -> (polygon or None, advance)
    cmap = {}

    def to_poly(strokes, dots, w, lb, rb, dx=0, ch=None):
        shapes = []
        off = lb + b + dx
        for s in strokes:
            pts = [(x + off, y) for x, y in s]
            shapes.append(LineString(pts).buffer(b, quad_segs=8, cap_style='square', join_style='mitre', mitre_limit=3.5))
        for x, y, r in dots:
            shapes.append(Point(x + off, y).buffer(r, quad_segs=8))
        poly = unary_union(shapes) if shapes else None
        cl = clip_for(ch) if ch else None
        if poly is not None and cl:
            poly = poly.intersection(box(-5000, cl[0], 5000, cl[1]))
        return poly, lb + b + w + b + rb

    def gname(ch):
        return 'uni%04X' % ord(ch)

    for ch, (strokes, dots, w, lb, rb) in base.items():
        poly, adv = to_poly(strokes, dots, w, lb, rb, ch=ch)
        glyphs[gname(ch)] = (poly, adv)
        cmap[ord(ch)] = gname(ch)

    for comb, letters in COMBOS.items():
        for letter in letters:
            ch = unicodedata.normalize('NFC', letter + comb)
            if len(ch) != 1 or letter not in base:
                continue
            strokes, dots, w, lb, rb = base[letter]
            if letter in 'ij':
                dots = []
            poly, adv = to_poly(strokes, dots, w, lb, rb, ch=letter)
            cx = lb + b + w / 2
            parts = [poly] if poly is not None else []
            upper = letter.isupper()
            if comb == '̧':     # cedilla hangs below the baseline
                st = [[(cx - 20, b), (cx + 10, -50)] + arc(cx - 15, -95, 55, 50, 40, -190, 14)]
                parts += [LineString(s).buffer(b * 0.85, quad_segs=8, cap_style='round', join_style='round') for s in st]
            else:
                ms, md = mk[comb]
                ymark = (CAP + 120) if upper else (XH + 120)
                if comb in '̂̌' and not upper: ymark = XH + 120
                for s in ms:
                    pts = [(x + cx, y + ymark) for x, y in s]
                    parts.append(LineString(pts).buffer(b * 0.85, quad_segs=8, cap_style='square', join_style='mitre', mitre_limit=3.5))
                for x, y, r in md:
                    parts.append(Point(x + cx, y + ymark).buffer(r, quad_segs=8))
            glyphs[gname(ch)] = (unary_union(parts), adv)
            cmap[ord(ch)] = gname(ch)

    order = ['.notdef'] + sorted(glyphs)
    pens = {}
    npen = TTGlyphPen(None)
    box = LineString([(60, 0), (60, 700), (400, 700), (400, 0), (60, 0)]).buffer(b / 2)
    for nm, (poly, adv) in [('.notdef', (box, 500))] + sorted(glyphs.items()):
        pen = TTGlyphPen(None)
        if poly is not None and not poly.is_empty:
            polys = list(poly.geoms) if poly.geom_type == 'MultiPolygon' else [poly]
            for p in polys:
                p = orient(p.simplify(0.8), sign=-1.0)
                for ring in [p.exterior] + list(p.interiors):
                    pts = [(round(x), round(y)) for x, y in ring.coords[:-1]]
                    if len(pts) < 3: continue
                    pen.moveTo(pts[0])
                    for pt in pts[1:]: pen.lineTo(pt)
                    pen.closePath()
        pens[nm] = (pen.glyph(), adv)

    fb = FontBuilder(UPM, isTTF=True)
    fb.setupGlyphOrder(order)
    fb.setupCharacterMap(cmap)
    fb.setupGlyf({n: v[0] for n, v in pens.items()})
    hm = {}
    for n, (gl, adv) in pens.items():
        gl.recalcBounds(fb.font['glyf'] if False else None) if False else None
        hm[n] = (adv, int(getattr(gl, 'xMin', 0) if gl.numberOfContours else 0))
    fb.setupHorizontalMetrics(hm)
    fb.setupHorizontalHeader(ascent=920, descent=-260)
    fam = 'Wordroot Sans'
    fb.setupNameTable({'familyName': fam, 'styleName': weight_name,
                       'uniqueFontIdentifier': f'{fam} {weight_name}', 'fullName': f'{fam} {weight_name}',
                       'psName': f'WordrootSans-{weight_name}',
                       'copyright': 'Copyright 2026 Joshua Trommel. MIT License.',
                       'licenseDescription': 'MIT'})
    fb.setupOS2(sTypoAscender=ASC, sTypoDescender=DESC, sTypoLineGap=200, usWinAscent=920, usWinDescent=260,
                sxHeight=XH, sCapHeight=CAP, usWeightClass=700 if weight_name == 'Bold' else 400,
                fsSelection=0x20 if weight_name == 'Bold' else 0x40)
    fb.setupPost()
    fb.save(path)
    if '--woff2' in sys.argv or True:
        from fontTools.ttLib import TTFont
        f = TTFont(path); f.flavor = 'woff2'
        try: f.save(path.replace('.ttf', '.woff2'))
        except Exception as e: print('woff2 skipped:', e)
    return len(glyphs)

if __name__ == '__main__':
    out = os.path.join(OUT, '..', 'fonts'); os.makedirs(out, exist_ok=True)
    for name, sw in [('Regular', 90), ('Bold', 152)]:
        n = build(name, sw, os.path.join(out, f'WordrootSans-{name}.ttf'))
        print(name, n, 'glyphs')
