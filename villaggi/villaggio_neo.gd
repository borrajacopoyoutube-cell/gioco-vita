@tool
extends VillaggioBase
## Villaggio 4 - Neo Borgo: villaggio futuristico di notte, luci al neon e ologramma in piazza.

const CIANO := Color("38e8ff")
const MAGENTA := Color("ff4fd8")
const GIALLO := Color("ffd84a")
const MURO := Color("2c3152")

# x, y, larghezza, profondità, altezza, colore neon, nome della chat
var case := [
	[2, 2, 2, 2, 110, CIANO, "Studio"],
	[5, 4, 2, 2, 70, MAGENTA, "Idee"],
	[11, 2, 2, 2, 130, MAGENTA, "Lavoro"],
	[13, 5, 2, 2, 80, GIALLO, "Soldi"],
	[2, 11, 2, 2, 76, MAGENTA, "Svago"],
	[5, 13, 2, 2, 96, CIANO, "Salute"],
	[13, 11, 2, 2, 88, GIALLO, "Casa"],
	[14, 15, 2, 2, 64, CIANO, "Cucina"],
]


func prepara() -> void:
	nome = "Neo Borgo"
	sottotitolo = "Villaggio del futuro: neon, torri e un ologramma in piazza"
	cielo_alto = Color("070a22")
	cielo_basso = Color("33205a")
	colore_bordo = Color("1c1f38")
	titolo_sfondo = Color(0.05, 0.08, 0.2, 0.75)
	titolo_testo = Color("c9f7ff")
	contorno = Color(0, 0, 0, 0.5)
	colori_terreno = {
		"erba": Color("262b48"),
		"strada": Color("15182c"),
		"piazza": Color("323866"),
		"acqua": Color("1b5a8a"),
	}
	segna(8, 0, 2, N, "strada")
	segna(0, 8, N, 2, "strada")
	segna(7, 7, 4, 4, "piazza")
	segna(14, 0, 3, 3, "acqua")
	for c in case:
		occupa(c[0] - 0.3, c[1] - 0.3, c[2] + 0.6, c[3] + 0.6)


func sfondo() -> void:
	for i in 90:
		var p := Vector2(rumore(i, 1) * SCHERMO.x, rumore(i, 2) * 330)
		var f := 0.4 + 0.5 * sin(tempo * 2.5 + i * 1.7)
		draw_circle(p, 1.0 + rumore(i, 3) * 1.2, Color(1, 1, 1, f))
	draw_circle(Vector2(1110, 120), 36, Color("e8e6ff"))
	alone(Vector2(1110, 120), 36, Color("9a8cff"), 0.9)
	# skyline lontana
	for i in 22:
		var w := 30.0 + rumore(i, 5) * 40.0
		var h := 60.0 + rumore(i, 6) * 120.0
		var x := i * 60.0
		draw_rect(Rect2(x, 420 - h, w, h + 300), Color("1a1838"))
		if rumore(i, 8) > 0.4:
			draw_rect(Rect2(x + 6, 430 - h, w - 12, 2), Color(MAGENTA, 0.5))


func terreno_extra() -> void:
	# griglia luminosa
	for i in N + 1:
		draw_line(iso(i, 0, 0), iso(i, N, 0), Color(CIANO, 0.12), 1.0)
		draw_line(iso(0, i, 0), iso(N, i, 0), Color(CIANO, 0.12), 1.0)
	# linee tratteggiate sulle strade
	for i in N:
		if i >= 7 and i <= 10:
			continue
		draw_line(iso(9, i + 0.2), iso(9, i + 0.7), Color(MAGENTA, 0.9), 2.0)
		draw_line(iso(i + 0.2, 9), iso(i + 0.7, 9), Color(MAGENTA, 0.9), 2.0)
	# bordo luminoso della piazza
	var piazza := PackedVector2Array([iso(7, 7), iso(11, 7), iso(11, 11), iso(7, 11), iso(7, 7)])
	draw_polyline(piazza, Color(CIANO, 0.35), 6.0, true)
	draw_polyline(piazza, CIANO, 2.0, true)
	# vasca luminosa
	var vasca := PackedVector2Array([iso(14, 0), iso(17, 0), iso(17, 3), iso(14, 3), iso(14, 0)])
	draw_polyline(vasca, Color(CIANO, 0.8), 2.0, true)
	for c in case:
		var px: float = c[0] + c[2] * 0.5
		var py: float = c[1] + c[3]
		var vx := 8.0 if px < 9 else 10.0
		vialetto(px, py, 8.0, vx, Color("1d2140"))


func torre(x: float, y: float, w: float, d: float, h: float, neon: Color) -> void:
	alone(iso(x + w * 0.5, y + d * 0.5), 34, neon, 0.35)
	box(x, y, w, d, h, MURO)
	var colori := [CIANO, MAGENTA, GIALLO, Color("ffffff")]
	var piani := int((h - 30) / 14)
	for p in piani:
		var z0 := 26.0 + p * 14.0
		for k in 3:
			var u := 0.2 + k * 0.3
			if rumore(x * 3 + k, y * 5 + p) > 0.35:
				var col: Color = colori[int(rumore(p, k + x) * 4) % 4]
				quad_x(x, y, w, d, u - 0.08, u + 0.08, z0, z0 + 7, Color(col, 0.9))
			if rumore(y * 3 + k, x * 5 + p) > 0.4:
				var col2: Color = colori[int(rumore(k + y, p) * 4) % 4]
				quad_y(x, y, w, d, u - 0.08, u + 0.08, z0, z0 + 7, Color(col2, 0.9))
	# porta luminosa
	quad_y(x, y, w, d, 0.42, 0.58, 0, 18, Color(neon, 0.85))
	# bordo del tetto al neon
	var tetto := PackedVector2Array([iso(x, y, h), iso(x + w, y, h), iso(x + w, y + d, h), iso(x, y + d, h), iso(x, y, h)])
	draw_polyline(tetto, Color(neon, 0.3), 7.0, true)
	draw_polyline(tetto, neon, 2.0, true)
	# striscia verticale sullo spigolo
	draw_line(iso(x + w, y + d, 4), iso(x + w, y + d, h - 4), Color(neon, 0.8), 2.0)
	# antenna
	if h > 90:
		var a := iso(x + w * 0.5, y + d * 0.5, h)
		draw_line(a, a - Vector2(0, 30), Color("9aa3c7"), 2.0)
		var lamp := 0.5 + 0.5 * sin(tempo * 4 + x)
		alone(a - Vector2(0, 32), 4, Color("ff4a4a"), lamp * 1.5)
		draw_circle(a - Vector2(0, 32), 2.5, Color("ff6a6a"))


func ologramma(cx: float, cy: float) -> void:
	cilindro(cx, cy, 0.9, 8, Color("3a4170"))
	var base := iso(cx, cy, 8)
	var anello := ellisse_punti(base, 0.8 * RX, 0.8 * RY, 40)
	anello.append(anello[0])
	draw_polyline(anello, CIANO, 2.0, true)
	_poly([base + Vector2(-34, 0), base + Vector2(34, 0), base + Vector2(16, -110), base + Vector2(-16, -110)], Color(CIANO, 0.12), false)
	var centro := base - Vector2(0, 70 + sin(tempo * 1.5) * 6)
	var s := 26.0
	var k := cos(tempo * 1.2)
	var gemma := [centro + Vector2(0, -s * 1.3), centro + Vector2(s * k, 0), centro + Vector2(0, s * 1.3), centro + Vector2(-s * k, 0)]
	alone(centro, 20, CIANO, 1.2)
	_poly(gemma, Color(CIANO, 0.55), false)
	var bordo := PackedVector2Array(gemma)
	bordo.append(gemma[0])
	draw_polyline(bordo, Color("e8fdff"), 2.0, true)
	for i in 3:
		var r := 0.5 + i * 0.25 + fposmod(tempo * 0.3, 0.25)
		var giro := ellisse_punti(base - Vector2(0, 10 + i * 30), r * RX, r * RY, 36)
		giro.append(giro[0])
		draw_polyline(giro, Color(CIANO, 0.35), 1.5, true)


func albero_neon(x: float, y: float, col: Color) -> void:
	var b := iso(x + 0.5, y + 0.5)
	draw_line(b, b - Vector2(0, 26), Color("6c7399"), 3.0)
	alone(b - Vector2(0, 38), 13, col, 0.9)
	cerchio(b - Vector2(0, 38), 13, Color(col, 0.85))
	draw_arc(b - Vector2(0, 38), 9, PI * 1.1, PI * 1.6, 8, Color(1, 1, 1, 0.6), 2.0, true)


func veicolo(i: int) -> void:
	var y := 200.0 + i * 55.0
	var x := fposmod(tempo * (90 + i * 25) + i * 400, SCHERMO.x + 200) - 100
	var dir := 1.0 if i % 2 == 0 else -1.0
	if dir < 0:
		x = SCHERMO.x - x
	var col: Color = [CIANO, MAGENTA, GIALLO][i % 3]
	draw_line(Vector2(x, y), Vector2(x - dir * 60, y), Color(col, 0.25), 3.0)
	draw_rect(Rect2(x - 9, y - 4, 18, 7), Color("c9d2f5"))
	draw_circle(Vector2(x + dir * 9, y), 2.5, col)


func costruisci() -> void:
	for c in case:
		aggiungi(c[0] + c[2] + c[1] + c[3], torre.bind(c[0], c[1], c[2], c[3], c[4], c[5]))
	aggiungi(18, ologramma.bind(9, 9))
	var luci := [CIANO, MAGENTA]
	for p in [Vector2(7, 7), Vector2(11, 7), Vector2(7, 11), Vector2(11, 11)]:
		aggiungi(p.x + p.y, lampione.bind(p.x, p.y, luci[int(p.x + p.y) % 2], true, Color("8890b8")))
	var colori := [CIANO, MAGENTA, Color("7dff9a")]
	for gx in N:
		for gy in N:
			if libero(gx, gy) and rumore(gx, gy) > 0.72:
				aggiungi(gx + gy + 1, albero_neon.bind(gx, gy, colori[int(rumore(gy, gx) * 3) % 3]))


func sopra() -> void:
	for i in 3:
		veicolo(i)
	var battute := {
		"Lavoro": "Report inviato!",
		"Idee": "Nuovo progetto?",
		"Salute": "10.000 passi!",
		"Casa": "Robot aspirapolvere: ON",
	}
	for c in case:
		if battute.has(c[6]):
			var col: Color = c[5]
			fumetto(iso(c[0] + c[2] * 0.5, c[1] + c[3] * 0.5, c[4] + (58 if c[4] > 90 else 26)), c[6] + ": " + battute[c[6]], Color(0.04, 0.06, 0.16, 0.92), col.lightened(0.4), col)
