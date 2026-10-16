"""Build original Lexi Notebook lettering. Python 3 + fonttools, shapely, brotli.

Install build dependencies separately; they are not website dependencies.
Pass --deps PATH if dependencies were installed with pip --target PATH.
The hand-authored centerlines below are the editable design source, not a
modification of The Nautigal or any other third-party font.
"""
import argparse
import math
import sys
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--deps')
args = parser.parse_args()
if args.deps:
    sys.path.insert(0, args.deps)

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.basePen import BasePen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.svgLib.path import parse_path
from fontTools.ttLib import TTFont
from shapely.geometry import Point, Polygon
from shapely.geometry.polygon import orient
from shapely.ops import unary_union

OUT = Path(__file__).resolve().parent
# Upright design coordinates; the final pen applies a consistent 19-degree slant.
# Lowercase entry/exit strokes meet at y=80 to support arbitrary connected words.
LETTERS = {
 'a': (310, 'M0 80 Q70 150 75 280 C80 405 250 420 238 300 C230 210 168 -20 90 10 C5 50 95 365 238 375 M245 380 C216 238 180 22 235 12 Q263 10 310 80'),
 'b': (310, 'M0 80 C75 195 113 460 120 610 C127 830 15 666 28 510 L65 55 C95 -42 245 0 263 175 C277 338 166 431 100 285 Q172 205 310 80'),
 'c': (285, 'M0 80 Q70 143 78 245 C101 408 278 434 236 318 M236 350 C118 456 13 141 80 40 C129 -24 230 25 285 80'),
 'd': (320, 'M0 80 Q58 141 70 266 C93 412 229 408 230 300 C224 192 154 -24 81 14 C12 70 99 361 239 377 M233 360 C268 494 315 732 271 724 C240 714 205 520 210 361 C214 188 165 7 243 9 Q272 16 320 80'),
 'e': (275, 'M0 80 C66 158 173 182 207 274 C251 408 78 385 62 226 C34 2 131 -35 275 80'),
 'f': (250, 'M0 80 C90 203 192 441 187 635 C181 855 55 723 55 490 L79 -102 C85 -339 -43 -236 26 -76 Q101 52 250 80 M-10 333 Q113 353 263 391'),
 'g': (315, 'M0 80 Q56 150 72 268 C91 407 246 412 235 285 C221 151 151 -29 82 15 C9 72 98 364 241 375 M246 373 C221 221 203 39 159 -144 C123 -300 -6 -298 20 -203 Q50 -84 315 80'),
 'h': (330, 'M0 80 C85 229 112 494 113 626 C114 802 18 697 29 511 L64 12 C84 172 175 395 244 368 C300 338 188 72 240 14 Q275 -7 330 80'),
 'i': (175, 'M0 80 Q71 168 82 367 C73 259 28 49 81 15 Q112 -4 175 80 M99 514 L103 525'),
 'j': (180, 'M0 80 Q70 161 101 365 L76 -109 C66 -280 -60 -295 -38 -193 Q-14 -85 180 80 M116 516 L121 529'),
 'k': (315, 'M0 80 C83 216 119 489 120 637 C119 805 23 687 34 511 L58 8 M64 136 C159 284 279 440 270 328 C264 263 170 219 102 212 C197 235 180 10 242 16 Q280 23 315 80'),
 'l': (195, 'M0 80 C95 231 154 502 135 655 C111 824 19 676 34 499 L66 80 C75 -21 122 11 195 80'),
 'm': (510, 'M0 80 Q65 154 64 365 L51 13 C82 184 172 413 213 355 C243 312 151 49 181 13 C215 184 303 412 349 355 C388 314 289 63 343 13 Q409 -17 510 80'),
 'n': (330, 'M0 80 Q66 161 64 365 L52 14 C82 188 183 412 237 355 C282 310 184 64 239 14 Q278 -4 330 80'),
 'o': (300, 'M0 80 Q42 112 63 164 M193 376 C91 393 25 157 65 57 C110 -65 241 80 252 253 C259 350 236 390 193 376 M117 12 Q208 17 300 80'),
 'p': (330, 'M0 80 Q66 178 80 366 L41 -245 M76 164 C133 372 248 441 267 291 C292 129 156 -59 108 25 Q153 5 330 80'),
 'q': (305, 'M0 80 Q55 160 71 278 C94 411 244 410 231 280 C220 149 147 -24 80 14 C10 76 104 367 242 375 M246 374 L182 -241 Q212 -124 305 80'),
 'r': (260, 'M0 80 C69 162 76 256 87 358 C92 423 154 407 131 349 Q115 310 86 325 Q178 355 205 342 C170 257 119 13 184 12 Q216 17 260 80'),
 's': (260, 'M0 80 Q109 206 177 376 C121 410 66 343 105 279 C147 219 226 168 189 79 C159 -4 66 -15 63 41 C59 88 119 102 161 77 Q213 47 260 80'),
 't': (230, 'M0 80 Q65 165 130 580 M124 557 C103 380 25 56 94 15 Q147 -11 230 80 M15 349 Q135 370 254 402'),
 'u': (330, 'M0 80 Q67 154 86 367 C62 238 3 21 83 12 C151 9 209 251 236 370 C208 234 180 14 242 13 Q278 14 330 80'),
 'v': (300, 'M0 80 Q68 172 69 367 C54 227 68 65 99 12 C174 78 272 278 247 369 Q216 254 300 80'),
 'w': (445, 'M0 80 Q66 166 68 367 C51 223 68 68 94 13 C157 80 203 246 209 365 C194 225 211 64 244 12 C318 91 405 285 382 368 Q354 236 445 80'),
 'x': (300, 'M0 80 Q79 145 236 371 M53 352 C151 427 118 7 206 14 Q257 26 300 80'),
 'y': (330, 'M0 80 Q66 167 82 366 C60 224 16 27 84 13 C152 0 215 251 242 370 L179 -132 C147 -299 4 -290 33 -196 Q66 -80 330 80'),
 'z': (300, 'M0 80 Q61 182 70 325 Q164 394 252 351 L87 18 C167 80 271 57 223 -78 C168 -254 13 -293 31 -191 Q59 -91 300 80'),
 'A': (570, 'M-15 -15 C139 261 300 582 388 700 C392 500 345 53 440 6 Q488 -1 570 80 M89 229 Q294 247 478 285'),
 'B': (540, 'M29 0 Q92 342 145 688 M-12 573 C151 809 494 752 421 563 C387 470 209 391 128 399 C299 478 553 359 446 157 C351 -12 145 -34 57 41'),
 'C': (540, 'M484 574 C538 812 149 737 69 334 C-10 -64 319 -85 540 119'),
 'D': (590, 'M47 0 L139 681 M-17 590 C138 757 481 786 503 471 C527 152 198 -81 49 30 Q257 2 590 80'),
 'E': (480, 'M443 589 C503 789 180 718 128 535 C82 374 293 351 348 409 C155 406 -2 231 66 85 C124 -46 332 5 480 107'),
 'F': (480, 'M70 0 Q113 338 172 661 M-11 593 Q216 751 530 708 M75 365 Q244 382 421 419'),
 'G': (590, 'M486 567 C533 810 155 728 73 344 C-13 -31 277 -58 419 189 M275 256 Q423 296 541 293 C477 144 433 -84 324 -202'),
 'H': (620, 'M51 7 L152 695 M451 699 C398 454 346 69 425 14 Q511 -20 620 80 M81 314 Q261 341 439 374'),
 'I': (300, 'M38 660 Q176 707 317 705 M190 689 L85 14 M-1 -2 Q130 21 267 51'),
 'J': (440, 'M31 649 Q246 734 463 712 M344 695 C302 473 296 171 169 33 C65 -83 -39 48 27 174'),
 'K': (570, 'M47 3 L147 694 M101 279 Q296 487 497 708 M138 323 C326 469 264 36 413 13 Q486 3 570 80'),
 'L': (500, 'M12 35 C137 240 235 517 201 677 C174 818 52 659 80 446 L109 46 M5 13 C169 85 336 -88 500 67'),
 'M': (710, 'M-18 0 L142 694 C172 771 151 471 154 355 L403 702 C448 797 361 269 395 74 C406 -16 450 -21 482 18 M480 18 Q581 19 710 80'),
 'N': (640, 'M5 0 L127 701 C173 514 211 231 324 17 L467 710 M324 17 Q452 -6 640 80'),
 'O': (580, 'M370 706 C124 763 -21 204 102 42 C251 -148 517 191 500 481 C486 701 352 765 245 645'),
 'P': (535, 'M46 0 L147 689 M-5 586 C162 787 504 749 443 516 C406 369 222 307 113 363'),
 'Q': (610, 'M373 706 C132 766 -20 208 103 42 C251 -148 516 192 499 480 C485 701 352 763 247 646 M234 143 C337 141 332 -117 611 -106'),
 'R': (580, 'M45 0 L147 688 M-7 586 C161 790 505 751 442 526 C405 390 228 346 123 382 C298 420 277 44 410 14 Q492 -7 580 80'),
 'S': (485, 'M445 583 C494 799 192 720 139 553 C86 386 392 343 371 173 C346 -31 31 -58 62 126'),
 'T': (530, 'M-33 586 C105 690 354 713 606 728 M314 699 C263 455 219 177 201 5'),
 'U': (600, 'M137 695 C90 441 -10 51 119 14 C276 -22 397 456 458 700 C420 470 332 47 430 16 Q511 -1 600 80'),
 'V': (560, 'M67 681 C34 504 42 170 98 0 C286 215 436 521 502 710'),
 'W': (790, 'M70 686 C30 468 39 169 93 0 C242 185 355 498 383 694 C342 452 345 153 408 1 C572 208 717 521 760 707'),
 'X': (560, 'M38 15 Q287 380 514 708 M58 661 C217 821 200 39 389 15 Q481 -2 560 80'),
 'Y': (540, 'M93 697 C43 463 79 297 179 311 C282 324 402 586 452 707 C386 439 326 24 206 -142 C109 -270 -1 -171 47 -68'),
 'Z': (550, 'M12 588 Q269 749 542 699 L43 14 C198 55 324 -57 550 82'),
}
DIGITS = {
 '0': (380,'M211 619 C42 635 -4 21 147 12 C308 -1 379 615 211 619'),
 '1': (270,'M17 451 L170 615 L78 14 M-4 5 L220 33'),
 '2': (380,'M34 451 C91 711 391 650 291 414 C225 256 60 138 12 16 Q180 51 350 12'),
 '3': (370,'M42 526 C155 697 394 615 270 419 Q223 368 141 338 C335 374 334 104 171 26 Q68 -18 20 76'),
 '4': (380,'M258 625 L17 218 L362 244 M276 490 L197 0'),
 '5': (370,'M356 617 L134 592 L63 330 C333 468 344 119 184 35 Q71 -25 20 74'),
 '6': (370,'M330 606 C110 636 -17 153 96 35 C208 -77 366 191 266 314 C181 413 79 287 66 191'),
 '7': (350,'M7 571 Q188 619 353 608 L108 0 M70 282 L291 307'),
 '8': (370,'M178 330 C-10 430 117 658 254 609 C399 554 217 382 154 323 C-58 191 45 -24 193 15 C378 67 292 247 178 330'),
 '9': (370,'M266 426 C291 655 114 689 59 470 C-5 230 223 202 279 455 C282 262 191 36 69 7'),
}
PUNCT = {
 '.': (150,'M65 18 L66 25'), ',':(150,'M78 28 Q68 -24 30 -61'),
 ':':(160,'M67 25 L68 32 M95 304 L96 311'), ';':(160,'M79 29 Q69 -24 31 -61 M97 304 L98 311'),
 '!':(190,'M88 147 L170 648 M67 20 L69 28'),
 '?':(330,'M35 489 C99 697 354 640 273 451 C232 365 132 360 118 163 M94 23 L95 30'),
 "'":(140,'M71 674 Q85 615 43 560'), '"':(230,'M75 674 Q86 613 44 560 M174 674 Q185 613 143 560'),
 '-':(280,'M44 245 L252 269'), '–':(450,'M35 247 L412 277'), '—':(720,'M36 242 L680 287'),
 '(': (230,'M233 702 C55 475 5 155 69 -97'), ')':(230,'M81 701 C182 437 112 94 -42 -99'),
 '[':(230,'M230 694 L105 689 L-8 -85 L115 -80'), ']':(230,'M90 699 L210 704 L98 -70 L-25 -75'),
 '/':(350,'M0 -54 L345 694'), '\\':(350,'M25 695 L285 -51'),
 '&':(520,'M437 284 C295 -29 42 -70 56 119 C68 282 304 417 295 568 C284 750 98 617 131 462 C166 289 293 -39 507 40'),
 '+':(360,'M50 275 L330 294 M208 440 L173 135'), '=':(360,'M49 225 L330 244 M67 363 L347 382'),
 '_':(410,'M0 -94 L385 -76'), '*':(280,'M141 597 L115 367 M28 520 L231 436 M25 411 L247 556'),
 '#':(450,'M166 593 L55 8 M355 599 L246 9 M36 200 L415 225 M67 389 L443 417'),
 '%':(590,'M59 5 L529 622 M148 613 C27 617 13 333 120 332 C231 331 254 615 148 613 M438 290 C318 297 303 6 414 6 C524 6 545 288 438 290'),
 '@':(700,'M461 324 C482 523 285 519 248 295 C209 75 402 99 453 363 L423 179 C476 65 613 239 584 445 C545 741 165 650 86 316 C-2 -42 330 -126 583 59'),
 '$':(420,'M354 509 C351 714 76 587 89 437 C108 320 352 297 296 125 C237 -30 10 31 37 135 M258 720 L121 -93'),
 '<':(350,'M322 450 L40 222 L266 55'), '>':(350,'M70 457 L305 260 L22 54'),
 '|':(160,'M122 692 L30 -91'), '^':(340,'M31 407 L180 639 L301 427'),
 '`':(180,'M51 690 L125 569'), '~':(380,'M23 268 C124 424 230 168 359 329'),
 '{':(260,'M245 700 C82 731 212 362 42 303 C174 274 -8 -110 158 -87'),
 '}':(260,'M95 700 C261 739 92 367 231 307 C63 264 177 -104 15 -88'),
}

class SamplePen(BasePen):
    def __init__(self):
        super().__init__(None)
        self.paths=[]
    def _moveTo(self,p): self.paths.append([p])
    def _lineTo(self,p):
        a=self.paths[-1][-1]
        steps=max(2,math.ceil(math.dist(a,p)/7))
        self.paths[-1].extend([(a[0]+(p[0]-a[0])*t/steps,a[1]+(p[1]-a[1])*t/steps) for t in range(1,steps+1)])
    def _curveToOne(self,b,c,d):
        a=self.paths[-1][-1]
        steps=max(16,math.ceil((math.dist(a,b)+math.dist(b,c)+math.dist(c,d))/7))
        for i in range(1,steps+1):
            t=i/steps; u=1-t
            self.paths[-1].append(tuple(u**3*a[j]+3*u*u*t*b[j]+3*u*t*t*c[j]+t**3*d[j] for j in (0,1)))
    def _qCurveToOne(self,b,c):
        a=self.paths[-1][-1]
        self._curveToOne(tuple(a[j]+2/3*(b[j]-a[j]) for j in (0,1)),tuple(c[j]+2/3*(b[j]-c[j]) for j in (0,1)),c)
    def _closePath(self): self._lineTo(self.paths[-1][0])
    def _endPath(self): pass

def outline(path, bold):
    pen=SamplePen(); parse_path(path,pen)
    pieces=[]
    for points in pen.paths:
        coords=[(x+.34*y+36,y) for x,y in points]
        radii=[]
        for i,p in enumerate(coords):
            a=points[max(0,i-1)]; b=points[min(len(points)-1,i+1)]
            dy=b[1]-a[1]; dx=b[0]-a[0]
            pressure=max(0,-dy)/max(.1,math.hypot(dx,dy))
            radius=(6.2+9.5*pressure) if not bold else (8.0+20*pressure)
            # Slight taper at the ends; the shape stays clean at small sizes.
            taper=min(1,.72+min(i,len(coords)-1-i)*.09)
            radii.append(radius*taper)
        for i,((x,y),r) in enumerate(zip(coords,radii)):
            pieces.append(Point(x,y).buffer(r,quad_segs=4))
            if not i: continue
            x0,y0=coords[i-1]; r0=radii[i-1]
            d=math.hypot(x-x0,y-y0)
            if d<.01: continue
            nx=-(y-y0)/d; ny=(x-x0)/d
            pieces.append(Polygon([(x0+nx*r0,y0+ny*r0),(x+nx*r,y+ny*r),(x-nx*r,y-ny*r),(x0-nx*r0,y0-ny*r0)]))
    if not pieces: return None
    return unary_union(pieces).simplify(.55,preserve_topology=True)

def to_glyph(shape):
    pen=TTGlyphPen(None)
    if shape is not None:
        for poly in ([shape] if shape.geom_type=='Polygon' else shape.geoms):
            poly=orient(poly,sign=-1)
            for ring in [poly.exterior,*poly.interiors]:
                coords=[(round(x),round(y)) for x,y in ring.coords[:-1]]
                pen.moveTo(coords[0])
                for p in coords[1:]: pen.lineTo(p)
                pen.closePath()
    return pen.glyph()

def build(bold):
    weight='Bold' if bold else 'Regular'
    designs={**LETTERS,**DIGITS,**PUNCT,' ':(230,''),'\u00a0':(230,'')}
    for alias,base in {'‘':"'",'’':"'",'“':'"','”':'"','…':'.'}.items(): designs[alias]=designs[base]
    shapes={c:outline(path,bold) if path else None for c,(width,path) in designs.items()}
    # Three separately drawn dots form the ellipsis.
    from shapely.affinity import translate
    shapes['…']=unary_union([translate(shapes['.'],xoff=x) for x in (0,140,280)])
    designs['…']=(430,'')
    # Accent support for common Spanish/French song titles, built from our own letters.
    import unicodedata
    accents={'\u0301':'M85 500 L187 613','\u0300':'M74 620 L138 501','\u0302':'M25 505 L120 608 L194 506','\u0303':'M20 532 C90 648 137 459 214 567','\u0308':'M56 547 L57 553 M177 547 L178 553','\u030a':'M108 514 C36 516 47 623 119 621 C183 619 171 513 108 514','\u0327':'M142 0 L109 -68 C244 -40 152 -198 70 -152'}
    for code in range(0xC0,0x100):
        c=chr(code); decomposition=unicodedata.normalize('NFD',c)
        if len(decomposition)==2 and decomposition[0] in LETTERS and decomposition[1] in accents:
            base,mark=decomposition
            markshape=outline(accents[mark],bold)
            if base.isupper() and mark!='\u0327': markshape=translate(markshape,xoff=95,yoff=240)
            shapes[c]=unary_union([shapes[base],markshape]); designs[c]=designs[base]
    cmap={ord(c):'uni%04X'%ord(c) for c in designs}
    glyphs={'.notdef':to_glyph(outline('M40 0 L40 600 L360 600 L360 0 Z',bold))}
    metrics={'.notdef':(450,40)}
    for c,name in ((c,cmap[ord(c)]) for c in designs):
        glyphs[name]=to_glyph(shapes[c])
        metrics[name]=(designs[c][0],round(shapes[c].bounds[0]) if shapes[c] is not None else 0)
    fb=FontBuilder(1000,isTTF=True)
    fb.setupGlyphOrder(list(glyphs)); fb.setupCharacterMap(cmap); fb.setupGlyf(glyphs)
    fb.setupHorizontalMetrics(metrics)
    fb.setupHorizontalHeader(ascent=1000,descent=-340,lineGap=0)
    fb.setupNameTable({'familyName':'Lexi Notebook','styleName':weight,'uniqueFontIdentifier':'LexiNotebook-1.000-'+weight,'fullName':'Lexi Notebook '+weight,'psName':'LexiNotebook-'+weight,'version':'Version 1.000','description':'Original handwriting designed for Lexi Robles from the notebook mockup.','licenseDescription':'Custom project lettering. See README.md for provenance and reuse notes.'})
    fb.setupOS2(version=4,sTypoAscender=1000,sTypoDescender=-340,sTypoLineGap=0,usWinAscent=1000,usWinDescent=340,usWeightClass=700 if bold else 400,fsSelection=0xA0 if bold else 0xC0,sxHeight=380,sCapHeight=710)
    fb.setupPost(italicAngle=-18.78,underlinePosition=-130,underlineThickness=20)
    fb.font['head'].macStyle=1 if bold else 0
    fb.setupMaxp()
    target=OUT/('LexiNotebook-'+weight+'.ttf'); fb.save(target)
    font=TTFont(target); font.flavor='woff2'; font.save(target.with_suffix('.woff2'))
    # Round-trip required characters, outline bounds, and name/style metadata.
    for file in (target,target.with_suffix('.woff2')):
        check=TTFont(file)
        assert set(map(ord,'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!?\'"&-')).issubset(check.getBestCmap())
        assert check['OS/2'].usWeightClass==(700 if bold else 400)
        for g in check['glyf'].glyphs.values():
            g.expand(check['glyf'])
            if g.numberOfContours: assert g.yMax<=1000 and g.yMin>=-340
        print(file.name,len(check.getBestCmap()),'characters',file.stat().st_size,'bytes')

if __name__=='__main__':
    build(False); build(True)
