@tool
class_name VillaggioBase
extends Node2D
## Base comune per disegnare un villaggio isometrico in stile "diorama".
## Ogni villaggio estende questo script e riempie: prepara(), costruisci(), sopra().
## Tutto è disegnato via codice (niente immagini esterne), così è facile da modificare.

const TW := 64.0          # larghezza di una casella isometrica
const TH := 32.0          # altezza di una casella isometrica
const N := 18             # il villaggio è una griglia N x N
const SCHERMO := Vector2(1280, 720)
const RX := 45.25         # raggio orizzontale (px) di un cerchio di 1 casella a terra
const RY := 22.63         # raggio verticale (px) di un cerchio di 1 casella a terra

var origin := Vector2(640, 96)
var nome := "Villaggio"
var sottotitolo := ""
var cielo_alto := Color("7ec8f5")
var cielo_basso := Color("e3f4ff")
var colore_bordo := Color("8a6440")
var colori_terreno := {"erba": Color("7cc35b")}
var contorno := Color(0, 0, 0, 0.30)
var titolo_sfondo := Color(0, 0, 0, 0.35)
var titolo_testo := Color.WHITE

var tempo := 1.3
var animato := true

var mappa := {}        # Vector2i -> tipo di terreno
var occupato := {}     # Vector2i -> true (case, vialetti, acqua...)
var font: Font
var _coda: Array = []


func _ready() -> void:
	font = ThemeDB.fallback_font
	mappa.clear()
	occupato.clear()
	prepara()
	queue_redraw()


func _process(delta: float) -> void:
	if animato:
		tempo += delta
		queue_redraw()


# --- Da personalizzare nei villaggi ----------------------------------------

func prepara() -> void:
	pass

func sfondo() -> void:
	pass

func terreno_extra() -> void:
	pass

func costruisci() -> void:
	pass

func sopra() -> void:
	pass


# --- Disegno principale -----------------------------------------------------

func _draw() -> void:
	if font == null:
		font = ThemeDB.fallback_font
	if mappa.is_empty():
		prepara()
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(SCHERMO.x, 0), SCHERMO, Vector2(0, SCHERMO.y)]),
		PackedColorArray([cielo_alto, cielo_alto, cielo_basso, cielo_basso]))
	sfondo()
	_base_diorama()
	for gx in N:
		for gy in N:
			tile(gx, gy, colore_tile(gx, gy))
	terreno_extra()
	_coda.clear()
	costruisci()
	_coda.sort_custom(func(a, b): return a[0] < b[0])
	for e in _coda:
		(e[1] as Callable).call()
	sopra()
	_titolo()


func aggiungi(profondita: float, f: Callable) -> void:
	_coda.append([profondita, f])


# --- Griglia e terreno ------------------------------------------------------

func iso(x: float, y: float, z: float = 0.0) -> Vector2:
	return origin + Vector2((x - y) * TW * 0.5, (x + y) * TH * 0.5 - z)

func rumore(x: float, y: float) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)

func segna(x: int, y: int, w: int, d: int, tipo: String) -> void:
	for i in range(x, x + w):
		for j in range(y, y + d):
			if i >= 0 and j >= 0 and i < N and j < N:
				mappa[Vector2i(i, j)] = tipo

func tipo_di(x: int, y: int) -> String:
	return mappa.get(Vector2i(x, y), "erba")

func occupa(x: float, y: float, w: float, d: float) -> void:
	for i in range(floori(x), ceili(x + w)):
		for j in range(floori(y), ceili(y + d)):
			occupato[Vector2i(i, j)] = true

func libero(x: int, y: int) -> bool:
	return tipo_di(x, y) == "erba" and not occupato.has(Vector2i(x, y))

func colore_tile(x: int, y: int) -> Color:
	var tipo := tipo_di(x, y)
	var c: Color = colori_terreno.get(tipo, Color.MAGENTA)
	var r := rumore(x, y) - 0.5
	if tipo == "acqua":
		return c.lightened(0.06 * sin(tempo * 1.6 + (x + y) * 0.9) + 0.03)
	if tipo == "piazza":
		c = c.darkened(0.06) if (x + y) % 2 == 0 else c
	return c.lightened(r * 0.10) if r > 0 else c.darkened(-r * 0.10)

func _base_diorama() -> void:
	var p := -40.0
	_poly([iso(0, N), iso(N, N), iso(N, N, p), iso(0, N, p)], colore_bordo)
	_poly([iso(N, 0), iso(N, N), iso(N, N, p), iso(N, 0, p)], colore_bordo.darkened(0.25))
	draw_line(iso(0, N, -10), iso(N, N, -10), colore_bordo.lightened(0.15), 2.0)
	draw_line(iso(N, N, -10), iso(N, 0, -10), colore_bordo.darkened(0.1), 2.0)

func tile(x: float, y: float, col: Color, z: float = 0.0, w: float = 1.0, d: float = 1.0) -> void:
	draw_colored_polygon(PackedVector2Array([iso(x, y, z), iso(x + w, y, z), iso(x + w, y + d, z), iso(x, y + d, z)]), col)

func vialetto(px: float, py: float, verso_y: float, verso_x: float, col: Color) -> void:
	## Disegna un vialetto dalla porta (px, py) fino alla strada.
	if verso_y > py:
		tile(px - 0.4, py, col, 0, 0.8, verso_y - py)
		occupa(px - 0.4, py, 0.8, verso_y - py)
	else:
		tile(px - 0.4, py, col, 0, 0.8, 1.4)
		var x0 := minf(px - 0.4, verso_x)
		var x1 := maxf(px + 0.4, verso_x)
		tile(x0, py + 0.6, col, 0, x1 - x0, 0.8)
		occupa(px - 0.4, py, 0.8, 1.4)
		occupa(x0, py + 0.6, x1 - x0, 0.8)


# --- Primitive di disegno ---------------------------------------------------

func _poly(punti, col: Color, linea: bool = true) -> void:
	var p := PackedVector2Array(punti)
	draw_colored_polygon(p, col)
	if linea:
		var chiuso := p.duplicate()
		chiuso.append(p[0])
		draw_polyline(chiuso, contorno, 1.0, true)

func ellisse_punti(c: Vector2, rx: float, ry: float, n: int = 28) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		p.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return p

func ellisse(c: Vector2, rx: float, ry: float, col: Color, linea: bool = false) -> void:
	_poly(ellisse_punti(c, rx, ry), col, linea)

func ellisse_terra(x: float, y: float, r: float, col: Color, z: float = 0.0, linea: bool = true) -> void:
	ellisse(iso(x, y, z), r * RX, r * RY, col, linea)

func cerchio(c: Vector2, r: float, col: Color, linea: bool = true) -> void:
	draw_circle(c, r, col)
	if linea:
		draw_arc(c, r, 0, TAU, 24, contorno, 1.0, true)

func alone(c: Vector2, r: float, col: Color, forza: float = 1.0) -> void:
	for i in 4:
		draw_circle(c, r * (1.0 + i * 0.6), Color(col, 0.16 * forza / (i + 1)))

func box(x: float, y: float, w: float, d: float, h: float, col: Color, z0: float = 0.0) -> void:
	_poly([iso(x, y + d, z0), iso(x + w, y + d, z0), iso(x + w, y + d, z0 + h), iso(x, y + d, z0 + h)], col)
	_poly([iso(x + w, y, z0), iso(x + w, y + d, z0), iso(x + w, y + d, z0 + h), iso(x + w, y, z0 + h)], col.darkened(0.22))
	_poly([iso(x, y, z0 + h), iso(x + w, y, z0 + h), iso(x + w, y + d, z0 + h), iso(x, y + d, z0 + h)], col.lightened(0.12))

func quad_y(x: float, y: float, w: float, d: float, u0: float, u1: float, z0: float, z1: float, col: Color) -> void:
	## Rettangolo disegnato sulla facciata frontale-sinistra (lato +y) di un blocco.
	_poly([iso(x + u0 * w, y + d, z0), iso(x + u1 * w, y + d, z0), iso(x + u1 * w, y + d, z1), iso(x + u0 * w, y + d, z1)], col)

func quad_x(x: float, y: float, w: float, d: float, u0: float, u1: float, z0: float, z1: float, col: Color) -> void:
	## Rettangolo disegnato sulla facciata frontale-destra (lato +x) di un blocco.
	_poly([iso(x + w, y + u0 * d, z0), iso(x + w, y + u1 * d, z0), iso(x + w, y + u1 * d, z1), iso(x + w, y + u0 * d, z1)], col)

func cilindro(cx: float, cy: float, r: float, h: float, col: Color, z0: float = 0.0) -> void:
	var c := iso(cx, cy, z0)
	var rx := r * RX
	var ry := r * RY
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var n := 16
	for i in n + 1:
		var a := PI - PI * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		cols.append(col.darkened(0.25) if cos(a) > 0.25 else col)
	for i in n + 1:
		var a := -PI * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry - h))
		cols.append(col.darkened(0.25) if cos(a) > 0.25 else col)
	draw_polygon(pts, cols)
	var chiuso := pts.duplicate()
	chiuso.append(pts[0])
	draw_polyline(chiuso, contorno, 1.0, true)
	ellisse(c - Vector2(0, h), rx, ry, col.lightened(0.12), true)

func cupola(cx: float, cy: float, r: float, z: float, alt: float, col: Color) -> void:
	## Cupola/cappello: mezza ellisse sopra un'ellisse a terra.
	var c := iso(cx, cy, z)
	var rx := r * RX
	var ry := r * RY
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var n := 18
	for i in n + 1:
		var a := PI - PI * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		cols.append(col.darkened(0.3) if cos(a) > 0.3 else col.darkened(0.08))
	for i in range(1, n):
		var a := -PI * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * alt))
		cols.append(col.darkened(0.22) if cos(a) > 0.35 else col.lightened(0.1))
	draw_polygon(pts, cols)
	var chiuso := pts.duplicate()
	chiuso.append(pts[0])
	draw_polyline(chiuso, contorno, 1.0, true)


# --- Elementi del villaggio -------------------------------------------------

func casa(x: float, y: float, w: float, d: float, h: float, muro: Color, tetto: Color,
		tipo: String = "capanna", finestra: Color = Color("ffe49a"), porta: Color = Color("5a3b22"), rh: float = 26.0) -> void:
	box(x, y, w, d, h, muro)
	var dw := 0.18 / w
	quad_y(x, y, w, d, 0.5 - dw, 0.5 + dw, 0, minf(h * 0.62, 24.0), porta)
	for u in [0.3, 0.72]:
		quad_x(x, y, w, d, u - 0.14 / d, u + 0.14 / d, h * 0.42, h * 0.74, finestra)
	if w >= 2:
		for u in [0.17, 0.83]:
			quad_y(x, y, w, d, u - 0.07, u + 0.07, h * 0.42, h * 0.74, finestra)
	match tipo:
		"capanna":
			tetto_capanna(x, y, w, d, h, rh, tetto, muro)
		"piramide":
			tetto_piramide(x, y, w, d, h, rh, tetto)
		"piatto":
			box(x - 0.06, y - 0.06, w + 0.12, d + 0.12, 5, tetto, h)
		"cupola":
			box(x - 0.06, y - 0.06, w + 0.12, d + 0.12, 4, muro.darkened(0.05), h)
			cupola(x + w * 0.5, y + d * 0.5, minf(w, d) * 0.36, h + 4, rh, tetto)

func tetto_capanna(x: float, y: float, w: float, d: float, h: float, rh: float, col: Color, muro: Color) -> void:
	var e := 0.16
	var m := y + d * 0.5
	_poly([iso(x - e, y - e, h), iso(x + w + e, y - e, h), iso(x + w + e, m, h + rh), iso(x - e, m, h + rh)], col.darkened(0.3))
	_poly([iso(x + w, y, h), iso(x + w, y + d, h), iso(x + w, m, h + rh)], muro.darkened(0.12))
	_poly([iso(x - e, y + d + e, h), iso(x + w + e, y + d + e, h), iso(x + w + e, m, h + rh), iso(x - e, m, h + rh)], col)
	for i in range(1, 4):
		var t := i / 4.0
		var yy := lerpf(y + d + e, m, t)
		draw_line(iso(x - e, yy, h + rh * t), iso(x + w + e, yy, h + rh * t), col.darkened(0.15), 1.0)
	draw_line(iso(x - e, m, h + rh), iso(x + w + e, m, h + rh), col.lightened(0.3), 2.0)

func tetto_piramide(x: float, y: float, w: float, d: float, h: float, rh: float, col: Color) -> void:
	var e := 0.16
	var cima := iso(x + w * 0.5, y + d * 0.5, h + rh)
	var a := iso(x - e, y + d + e, h)
	var b := iso(x + w + e, y + d + e, h)
	var c := iso(x + w + e, y - e, h)
	_poly([a, b, cima], col)
	_poly([b, c, cima], col.darkened(0.25))

func pino(x: float, y: float, s: float = 1.0, col: Color = Color("2f7d4a")) -> void:
	var b := iso(x + 0.5, y + 0.5)
	ellisse(b + Vector2(0, 2), 16 * s, 7 * s, Color(0, 0, 0, 0.18))
	draw_rect(Rect2(b.x - 3 * s, b.y - 12 * s, 6 * s, 12 * s), Color("6b4226"))
	for i in 3:
		var by := b.y - 10 * s - i * 13 * s
		var lw := (21.0 - i * 5.0) * s
		var c := col.lightened(i * 0.07)
		_poly([Vector2(b.x - lw, by), Vector2(b.x + lw, by), Vector2(b.x, by - 26 * s)], c)
		_poly([Vector2(b.x, by), Vector2(b.x + lw, by), Vector2(b.x, by - 26 * s)], c.darkened(0.2), false)

func albero(x: float, y: float, s: float = 1.0, col: Color = Color("4f9d3a"), tronco: Color = Color("7a4b2a")) -> void:
	var b := iso(x + 0.5, y + 0.5)
	ellisse(b + Vector2(0, 2), 18 * s, 8 * s, Color(0, 0, 0, 0.18))
	draw_rect(Rect2(b.x - 3.5 * s, b.y - 20 * s, 7 * s, 20 * s), tronco)
	cerchio(b + Vector2(-9, -30) * s, 13 * s, col.darkened(0.15))
	cerchio(b + Vector2(9, -30) * s, 13 * s, col.darkened(0.25))
	cerchio(b + Vector2(0, -40) * s, 15 * s, col)
	draw_circle(b + Vector2(-5, -46) * s, 5 * s, col.lightened(0.25))

func cespuglio(x: float, y: float, col: Color = Color("5aa843"), fiori: Color = Color.TRANSPARENT) -> void:
	var b := iso(x + 0.5, y + 0.5)
	cerchio(b + Vector2(-6, -6), 8, col.darkened(0.1))
	cerchio(b + Vector2(6, -6), 8, col.darkened(0.2))
	cerchio(b + Vector2(0, -11), 9, col)
	if fiori.a > 0:
		for o in [Vector2(-5, -12), Vector2(4, -9), Vector2(1, -16)]:
			draw_circle(b + o, 2.2, fiori)

func lampione(x: float, y: float, luce: Color = Color("ffe38a"), acceso: bool = false, palo: Color = Color("3b3b46")) -> void:
	var b := iso(x, y)
	draw_line(b, b - Vector2(0, 38), palo, 3.0)
	if acceso:
		alone(b - Vector2(0, 40), 9, luce, 1.4)
	cerchio(b - Vector2(0, 40), 5, luce)

func fontana(cx: float, cy: float, pietra: Color = Color("a7a49c"), acqua: Color = Color("6cc1f0")) -> void:
	ellisse_terra(cx, cy, 1.25, Color(0, 0, 0, 0.15), -2, false)
	cilindro(cx, cy, 1.1, 10, pietra)
	ellisse(iso(cx, cy, 10), 1.0 * RX, 1.0 * RY, acqua)
	cilindro(cx, cy, 0.18, 26, pietra.lightened(0.1), 10)
	for i in 6:
		var a := TAU * i / 6.0 + tempo * 0.6
		var p := iso(cx, cy, 36)
		var q := iso(cx + cos(a) * 0.6, cy + sin(a) * 0.6, 12)
		var m := (p + q) * 0.5 - Vector2(0, 10)
		draw_polyline(PackedVector2Array([p, m, q]), Color(1, 1, 1, 0.75), 2.0, true)

func fumetto(p: Vector2, testo: String, bg: Color = Color.WHITE, fg: Color = Color("2b2b2b"), bordo: Color = Color(0, 0, 0, 0.25), fs: int = 14) -> void:
	var dim := font.get_string_size(testo, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var r := Rect2(p.x - dim.x * 0.5 - 10, p.y - dim.y - 20, dim.x + 20, dim.y + 10)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(9)
	sb.border_color = bordo
	sb.set_border_width_all(2)
	draw_style_box(sb, r)
	var fondo := r.position.y + r.size.y
	draw_colored_polygon(PackedVector2Array([Vector2(p.x - 7, fondo - 1), Vector2(p.x + 7, fondo - 1), Vector2(p.x, fondo + 9)]), bg)
	draw_polyline(PackedVector2Array([Vector2(p.x - 7, fondo), Vector2(p.x, fondo + 9), Vector2(p.x + 7, fondo)]), bordo, 2.0, true)
	draw_string(font, Vector2(r.position.x + 10, r.position.y + 5 + font.get_ascent(fs)), testo, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, fg)

func _titolo() -> void:
	var dim1 := font.get_string_size(nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
	var dim2 := font.get_string_size(sottotitolo, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
	var r := Rect2(20, 18, maxf(dim1.x, dim2.x) + 32, 78)
	var sb := StyleBoxFlat.new()
	sb.bg_color = titolo_sfondo
	sb.set_corner_radius_all(12)
	draw_style_box(sb, r)
	draw_string(font, Vector2(36, 54), nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, titolo_testo)
	draw_string(font, Vector2(36, 80), sottotitolo, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(titolo_testo, 0.85))
