@tool
extends VillaggioBase
## Villaggio 3 - Funghinia: case a fungo, cristalli, fiori giganti e lucciole.

const STRADA := Color("cdb6ea")
const MURO := Color("fff1d6")

# x, y, raggio cappello, altezza, colore cappello, nome della chat
var case := [
	[3, 3, 1.35, 52, Color("e2504c"), "Studio"],
	[5.8, 5.6, 1.1, 42, Color("9b6ad6"), "Idee"],
	[12.2, 3, 1.4, 56, Color("f08a3c"), "Lavoro"],
	[14.6, 6, 1.1, 44, Color("ef6fa8"), "Soldi"],
	[3, 12.2, 1.25, 48, Color("4fa8d8"), "Svago"],
	[6, 14.4, 1.3, 52, Color("e2504c"), "Salute"],
	[14, 11.8, 1.3, 50, Color("9b6ad6"), "Casa"],
	[15.4, 15.2, 1.05, 42, Color("f08a3c"), "Cucina"],
]


func prepara() -> void:
	nome = "Funghinia"
	sottotitolo = "Case a fungo, cristalli magici e lucciole"
	cielo_alto = Color("a99af0")
	cielo_basso = Color("ffd8ea")
	colore_bordo = Color("8b6a9e")
	titolo_sfondo = Color(0.3, 0.15, 0.4, 0.45)
	colori_terreno = {
		"erba": Color("97dc86"),
		"strada": STRADA,
		"piazza": Color("ebdcf7"),
		"acqua": Color("78d3ec"),
	}
	segna(8, 0, 2, N, "strada")
	segna(0, 8, N, 2, "strada")
	segna(7, 7, 4, 4, "piazza")
	segna(0, 0, 3, 2, "acqua")
	for c in case:
		occupa(c[0] - 1.5, c[1] - 1.5, 3.0, 3.0)


func sfondo() -> void:
	for i in 40:
		var p := Vector2(rumore(i, 1) * SCHERMO.x, rumore(i, 2) * 260)
		draw_circle(p, 1.5 + rumore(i, 3) * 1.5, Color(1, 1, 1, 0.5 + 0.4 * sin(tempo * 2 + i)))
	draw_circle(Vector2(1120, 110), 34, Color("fff6d8"))
	draw_circle(Vector2(1135, 100), 30, cielo_alto.lerp(cielo_basso, 0.25))


func terreno_extra() -> void:
	for c in case:
		var px: float = c[0]
		var py: float = c[1] + 1.2
		var vx := 8.0 if px < 9 else 10.0
		vialetto(px, py, 8.0, vx, STRADA.lightened(0.1))
	# sassolini colorati sulla strada
	for gx in N:
		for gy in N:
			if tipo_di(gx, gy) == "strada" and rumore(gx, gy) > 0.5:
				ellisse(iso(gx + rumore(gy, gx), gy + 0.5), 4, 2, STRADA.darkened(0.12))
	# cerchio magico in piazza
	var anello := ellisse_punti(iso(9, 9), 1.75 * RX, 1.75 * RY, 48)
	anello.append(anello[0])
	draw_polyline(anello, Color("b48cf0"), 2.5, true)
	var bordo_lago := PackedVector2Array([iso(0, 2), iso(3, 2), iso(3, 0)])
	draw_polyline(bordo_lago, Color("f6e6ff"), 3.0, true)


func casa_fungo(cx: float, cy: float, r: float, h: float, cappello: Color) -> void:
	ellisse_terra(cx, cy, r * 0.9, Color(0, 0, 0, 0.15), 0, false)
	var rb := r * 0.62
	cilindro(cx, cy, rb, h, MURO)
	var c := iso(cx, cy)
	# porta ad arco
	var porta := c + Vector2(-2, rb * RY - 2)
	draw_rect(Rect2(porta.x - 7, porta.y - 16, 14, 16), Color("8a5a3a"))
	draw_circle(porta - Vector2(0, 16), 7, Color("8a5a3a"))
	draw_circle(porta + Vector2(4, -8), 1.5, Color("ffd34d"))
	# finestre tonde
	for o in [Vector2(-rb * RX * 0.6, rb * RY * 0.4 - h * 0.55), Vector2(rb * RX * 0.55, rb * RY * 0.4 - h * 0.6)]:
		cerchio(c + o, 5, Color("ffe49a"))
		draw_line(c + o - Vector2(5, 0), c + o + Vector2(5, 0), Color("8a5a3a"), 1.0)
	cupola(cx, cy, r, h - 4, r * 40.0, cappello)
	# pois bianchi
	var cc := iso(cx, cy, h - 4)
	for p in [Vector2(-0.5, -0.45), Vector2(0.05, -0.75), Vector2(0.45, -0.35), Vector2(-0.15, -0.25)]:
		ellisse(cc + Vector2(p.x * r * RX, p.y * r * 40.0), 5.5 * r, 3.5 * r, Color(1, 1, 1, 0.92))


func cristallo(x: float, y: float, col: Color) -> void:
	var b := iso(x + 0.5, y + 0.5)
	alone(b - Vector2(0, 14), 12, col, 0.7)
	for o in [Vector2(-8, 2), Vector2(7, 3), Vector2(0, 0)]:
		var alt := 30.0 if o.x == 0 else 20.0
		var p: Vector2 = b + o
		_poly([p + Vector2(-5, 0), p + Vector2(0, -alt), p + Vector2(5, 0), p + Vector2(0, 4)], col)
		_poly([p + Vector2(0, -alt), p + Vector2(5, 0), p + Vector2(0, 4)], col.darkened(0.2), false)


func fiore(x: float, y: float, col: Color) -> void:
	var b := iso(x + 0.5, y + 0.5)
	var cima := b - Vector2(0, 32)
	draw_line(b, cima, Color("4a9a40"), 3.0)
	ellisse(b - Vector2(-8, 16), 9, 4, Color("5bb04c"), true)
	for i in 6:
		var a := TAU * i / 6.0 + tempo * 0.2
		cerchio(cima + Vector2(cos(a), sin(a) * 0.6) * 7, 5.5, col)
	cerchio(cima, 4, Color("ffd34d"))


func albero_magico(cx: float, cy: float) -> void:
	var b := iso(cx, cy)
	ellisse(b + Vector2(0, 3), 40, 18, Color(0, 0, 0, 0.15))
	_poly([b + Vector2(-14, 0), b + Vector2(14, 0), b + Vector2(7, -80), b + Vector2(-7, -80)], Color("6e4a63"))
	draw_line(b + Vector2(0, -60), b + Vector2(-22, -84), Color("6e4a63"), 6.0)
	draw_line(b + Vector2(0, -64), b + Vector2(24, -86), Color("6e4a63"), 6.0)
	for p in [Vector2(-34, -92), Vector2(34, -94), Vector2(-14, -118), Vector2(16, -120), Vector2(0, -96)]:
		cerchio(b + p, 25, Color("f2a0cf").darkened(0.12 if p.y > -100 else -0.04))
	for i in 7:
		var p := b + Vector2(-42 + i * 14, -70 - (i % 2) * 8)
		draw_line(p - Vector2(0, 12), p, Color("6e4a63"), 1.0)
		alone(p, 4, Color("fff2a0"), 1.2)
		draw_circle(p, 3, Color("fff6c8"))


func costruisci() -> void:
	for c in case:
		aggiungi(c[0] + c[1] + 1.0, casa_fungo.bind(c[0], c[1], c[2], c[3], c[4]))
	aggiungi(18, albero_magico.bind(9, 9))
	aggiungi(1, func(): ellisse(iso(1.2, 0.8), 10, 5, Color("6cc05a"), true))
	var colori_cristalli := [Color("7fe3ff"), Color("c28cff"), Color("ff9ad5")]
	var colori_fiori := [Color("ff7ab8"), Color("ffb347"), Color("7fb2ff")]
	for gx in N:
		for gy in N:
			if not libero(gx, gy):
				continue
			var r := rumore(gx, gy)
			var scelta := int(rumore(gy, gx) * 3) % 3
			if r > 0.86:
				aggiungi(gx + gy + 1, cristallo.bind(gx, gy, colori_cristalli[scelta]))
			elif r > 0.8:
				aggiungi(gx + gy + 1, fiore.bind(gx, gy, colori_fiori[scelta]))
			elif r > 0.6 and (gx <= 1 or gy <= 1 or gx >= 16 or gy >= 16):
				aggiungi(gx + gy + 1, cespuglio.bind(gx, gy, Color("62b86a"), Color("fff0a0")))


func sopra() -> void:
	# lucciole
	for i in 30:
		var gx := rumore(i, 7) * N
		var gy := rumore(i, 9) * N
		var p := iso(gx, gy, 30 + rumore(i, 11) * 60) + Vector2(sin(tempo * 1.3 + i) * 8, cos(tempo + i * 2) * 6)
		var forza := 0.6 + 0.4 * sin(tempo * 3 + i)
		alone(p, 3, Color("fff38a"), forza * 1.5)
		draw_circle(p, 2, Color(1, 1, 0.7, forza))
	var battute := {
		"Idee": "Ho un'idea magica!",
		"Svago": "Festa sotto l'albero!",
		"Lavoro": "Prima il dovere...",
		"Casa": "Chi annaffia i fiori?",
	}
	for c in case:
		if battute.has(c[5]):
			fumetto(iso(c[0], c[1], c[3] + c[2] * 40.0 + 20), c[5] + ": " + battute[c[5]], Color("fffaff"), Color("5a3a7a"), Color("b48cf0"))
