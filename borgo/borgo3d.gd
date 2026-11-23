extends Node3D
## Borgo medievale 3D, generato interamente via codice.
## Le case delle chat sono attorno alla piazza: ognuna ha un'insegna col nome.
## Per cambiare nomi, colori o frasi modifica l'elenco CHAT qui sotto.

const R_PIAZZA := 11.0
const R_MURA := 36.0
const PIANO_PIATTO := 54.0   # fino a questa distanza dal centro il terreno è piatto

# Le chat che abitano nel borgo: nome, frase nel fumetto, angolo attorno alla piazza
const CHAT := [
	{"nome": "Studio", "frase": "Chi mi interroga?", "angolo": 30.0},
	{"nome": "Lavoro", "frase": "Riunione al pozzo!", "angolo": 60.0},
	{"nome": "Salute", "frase": "Giro delle mura?", "angolo": 120.0},
	{"nome": "Casa", "frase": "Stasera zuppa!", "angolo": 150.0},
	{"nome": "Idee", "frase": "Ho un'idea!", "angolo": 210.0},
	{"nome": "Soldi", "frase": "Il mercato è aperto", "angolo": 330.0},
]
const R_CASE := 21.0         # distanza delle case dal centro della piazza
const GIARDINO_DAVANTI := 4.5
const GIARDINO_LATI := 2.1
const GIARDINO_DIETRO := 1.6

const INTONACI := [Color("efe3c8"), Color("e8d4ad"), Color("f3ebda"), Color("dcb67a"), Color("e7c7b2"), Color("d9cdb8")]
const TETTI := [Color("a8472f"), Color("8f3a28"), Color("6e4a35"), Color("4c505c"), Color("b5583a")]

var rng := RandomNumberGenerator.new()
var rumore := FastNoiseLite.new()
var pale_mulino: Node3D

var _cache := {}
var _sh_terreno: Shader = preload("res://borgo/shader/terreno.gdshader")
var _sh_ciottoli: Shader = preload("res://borgo/shader/ciottoli.gdshader")
var _sh_pietra: Shader = preload("res://borgo/shader/pietra.gdshader")
var _sh_tegole: Shader = preload("res://borgo/shader/tegole.gdshader")

var m_legno: StandardMaterial3D
var m_legno_chiaro: StandardMaterial3D
var m_vetro: StandardMaterial3D
var m_pietra: ShaderMaterial
var m_pietra_scura: ShaderMaterial


func _ready() -> void:
	rng.seed = 1234
	rumore.seed = 7
	rumore.frequency = 0.012
	m_legno = mat(Color("4a3222"))
	m_legno_chiaro = mat(Color("8a6240"))
	m_vetro = mat(Color("2b3646"), 0.3)
	m_pietra = mat_shader(_sh_pietra, {"colore": Color("a39a88")})
	m_pietra_scura = mat_shader(_sh_pietra, {"colore": Color("857d70"), "dim": Vector2(0.7, 0.35)})
	_ambiente()
	_terreno()
	_strade()
	_piazza()
	_chiesa()
	_mura()
	_case()
	_campi_e_mulino()
	_alberi()


func _process(delta: float) -> void:
	if pale_mulino:
		pale_mulino.rotate_z(delta * 0.6)


# --- Materiali e forme di base ---------------------------------------------

func mat(col: Color, rough: float = 0.9) -> StandardMaterial3D:
	var k := "m" + col.to_html() + str(rough)
	if not _cache.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.roughness = rough
		_cache[k] = m
	return _cache[k]

func mat_shader(sh: Shader, parametri: Dictionary) -> ShaderMaterial:
	var k := sh.resource_path + str(parametri)
	if not _cache.has(k):
		var m := ShaderMaterial.new()
		m.shader = sh
		for p in parametri:
			m.set_shader_parameter(p, parametri[p])
		_cache[k] = m
	return _cache[k]

func tegole(col: Color, conico: bool = false) -> ShaderMaterial:
	return mat_shader(_sh_tegole, {"colore": col, "modo": 1 if conico else 0})

func _istanza(genitore: Node3D, mesh: Mesh, pos: Vector3, m: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.rotation = rot
	genitore.add_child(mi)
	return mi

func blocco(genitore: Node3D, dim: Vector3, pos: Vector3, m: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = dim
	return _istanza(genitore, bm, pos, m, rot)

func cilindro(genitore: Node3D, r_sopra: float, r_sotto: float, h: float, pos: Vector3, m: Material, segmenti: int = 20, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = r_sopra
	cm.bottom_radius = r_sotto
	cm.height = h
	cm.radial_segments = segmenti
	cm.rings = 1
	return _istanza(genitore, cm, pos, m, rot)

func sfera(genitore: Node3D, r: float, pos: Vector3, m: Material, schiaccia: float = 1.0) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0 * schiaccia
	sm.radial_segments = 12
	sm.rings = 6
	return _istanza(genitore, sm, pos, m)

func prisma(genitore: Node3D, dim: Vector3, pos: Vector3, m: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var pm := PrismMesh.new()
	pm.size = dim
	return _istanza(genitore, pm, pos, m, rot)

func tetto_a_falde(genitore: Node3D, larg: float, prof: float, y: float, alt: float, m: Material, sporgenza: float = 0.45) -> void:
	## Due falde inclinate, colmo lungo l'asse Z (il timpano guarda avanti).
	var a := larg * 0.5 + sporgenza
	var lung := sqrt(a * a + alt * alt) + 0.12
	var ang := atan2(alt, a)
	blocco(genitore, Vector3(lung, 0.18, prof + sporgenza * 2.0), Vector3(-a * 0.5, y + alt * 0.5 + 0.05, 0), m, Vector3(0, 0, ang))
	blocco(genitore, Vector3(lung, 0.18, prof + sporgenza * 2.0), Vector3(a * 0.5, y + alt * 0.5 + 0.05, 0), m, Vector3(0, 0, -ang))
	blocco(genitore, Vector3(0.22, 0.22, prof + sporgenza * 2.0 + 0.05), Vector3(0, y + alt + 0.1, 0), m_legno)

func altezza(x: float, z: float) -> float:
	var r := Vector2(x, z).length()
	var t := smoothstep(PIANO_PIATTO, PIANO_PIATTO + 50.0, r)
	var colline := t * (5.0 + 14.0 * (rumore.get_noise_2d(x, z) * 0.5 + 0.5))
	var monti := smoothstep(150.0, 290.0, r) * (30.0 + 55.0 * (rumore.get_noise_2d(x * 2.3 + 100.0, z * 2.3) * 0.5 + 0.5))
	return colline + monti

func etichetta(genitore: Node3D, testo: String, pos: Vector3, dim: int = 64, fumetto: bool = false) -> Label3D:
	var l := Label3D.new()
	l.text = testo
	l.font_size = dim
	l.pixel_size = 0.009
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color("2b2118")
	l.outline_modulate = Color(1, 0.98, 0.92) if fumetto else Color("f6e7c1")
	l.outline_size = 30 if fumetto else 14
	l.no_depth_test = fumetto
	l.render_priority = 10 if fumetto else 0
	genitore.add_child(l)
	return l


# --- Ambiente: cielo, sole, nebbia -----------------------------------------

func _ambiente() -> void:
	var sole := DirectionalLight3D.new()
	sole.rotation_degrees = Vector3(-38, -42, 0)
	sole.light_color = Color("fff0d6")
	sole.light_energy = 1.15
	sole.shadow_enabled = true
	sole.directional_shadow_max_distance = 160.0
	add_child(sole)

	var cielo_mat := ProceduralSkyMaterial.new()
	cielo_mat.sky_top_color = Color("4a86cf")
	cielo_mat.sky_horizon_color = Color("cfe0ee")
	cielo_mat.ground_horizon_color = Color("9fb07e")
	cielo_mat.ground_bottom_color = Color("5d7a3a")
	var cielo := Sky.new()
	cielo.sky_material = cielo_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = cielo
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	env.ambient_light_sky_contribution = 0.55
	env.ambient_light_color = Color("d9d2c2")
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.fog_enabled = true
	env.fog_light_color = Color("bcd0e0")
	env.fog_density = 0.0009
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


# --- Terreno ---------------------------------------------------------------

func _terreno() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var passo := 4.0
	var meta := 300.0
	var n := int(meta * 2.0 / passo)
	for i in n:
		for j in n:
			var x0 := -meta + i * passo
			var z0 := -meta + j * passo
			var x1 := x0 + passo
			var z1 := z0 + passo
			var a := Vector3(x0, altezza(x0, z0), z0)
			var b := Vector3(x1, altezza(x1, z0), z0)
			var c := Vector3(x1, altezza(x1, z1), z1)
			var d := Vector3(x0, altezza(x0, z1), z1)
			st.add_vertex(a)
			st.add_vertex(b)
			st.add_vertex(c)
			st.add_vertex(a)
			st.add_vertex(c)
			st.add_vertex(d)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat_shader(_sh_terreno, {"raggio_borgo": R_MURA - 1.0})
	add_child(mi)


func _strade() -> void:
	var ciottoli := mat_shader(_sh_ciottoli, {})
	blocco(self, Vector3(4.6, 0.12, R_MURA - R_PIAZZA + 2), Vector3(0, 0.06, (R_MURA + R_PIAZZA) * 0.5), ciottoli)
	blocco(self, Vector3(R_MURA - R_PIAZZA - 4, 0.12, 4.0), Vector3((R_MURA + R_PIAZZA) * 0.5 - 2, 0.06, 0), ciottoli)
	blocco(self, Vector3(R_MURA - R_PIAZZA - 4, 0.12, 4.0), Vector3(-(R_MURA + R_PIAZZA) * 0.5 + 2, 0.06, 0), ciottoli)
	# sentiero di terra fuori dalla porta, che segue il terreno
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var z := R_MURA
	while z < 135.0:
		var z2 := z + 2.0
		var x := sin(z * 0.03) * 6.0 * smoothstep(R_MURA, 70.0, z)
		var x2 := sin(z2 * 0.03) * 6.0 * smoothstep(R_MURA, 70.0, z2)
		var a := Vector3(x - 1.8, altezza(x - 1.8, z) + 0.06, z)
		var b := Vector3(x + 1.8, altezza(x + 1.8, z) + 0.06, z)
		var c := Vector3(x2 + 1.8, altezza(x2 + 1.8, z2) + 0.06, z2)
		var d := Vector3(x2 - 1.8, altezza(x2 - 1.8, z2) + 0.06, z2)
		for v in [a, c, b, a, d, c]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
		z = z2
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat(Color("8f7652"))
	add_child(mi)


# --- Piazza: pozzo, mercato, abitanti --------------------------------------

func _piazza() -> void:
	cilindro(self, R_PIAZZA, R_PIAZZA, 0.14, Vector3(0, 0.07, 0), mat_shader(_sh_ciottoli, {"scala": 2.6}), 48)
	cilindro(self, R_PIAZZA + 0.25, R_PIAZZA + 0.25, 0.1, Vector3(0, 0.05, 0), m_pietra_scura, 48)
	# pozzo
	cilindro(self, 1.3, 1.4, 1.0, Vector3(0, 0.6, 0), m_pietra, 20)
	cilindro(self, 1.05, 1.05, 0.05, Vector3(0, 1.08, 0), mat(Color("2c4a5c"), 0.2), 20)
	for s in [-1, 1]:
		blocco(self, Vector3(0.18, 2.2, 0.18), Vector3(s * 1.1, 2.1, 0), m_legno)
	blocco(self, Vector3(2.4, 0.12, 0.12), Vector3(0, 2.6, 0), m_legno)
	var t := Node3D.new()
	add_child(t)
	tetto_a_falde(t, 2.2, 1.6, 3.15, 0.8, tegole(Color("8f3a28")), 0.25)
	t.rotation.y = PI * 0.5
	# bancarelle del mercato
	var tende := [Color("b8352a"), Color("2f5d9b"), Color("d9a43a"), Color("3d7a45")]
	for i in 4:
		var ang := deg_to_rad(45.0 + i * 90.0)
		var p := Vector3(cos(ang), 0, sin(ang)) * 6.5
		_bancarella(p, -ang + PI * 0.5, tende[i])
	# abitanti (le chat in piazza)
	var colori := [Color("c0392b"), Color("2e86c1"), Color("27ae60"), Color("8e44ad"), Color("e67e22"), Color("16a085")]
	for i in colori.size():
		var ang := deg_to_rad(15.0 + i * 61.0)
		var r := 3.2 + (i % 2) * 1.6
		_persona(Vector3(cos(ang) * r, 0.14, sin(ang) * r), colori[i])
	# botti e casse
	for p in [Vector3(-8.5, 0, 3.5), Vector3(8.2, 0, -4.2), Vector3(3.8, 0, 8.6)]:
		cilindro(self, 0.42, 0.42, 0.95, p + Vector3(0, 0.6, 0), m_legno_chiaro, 12)
		blocco(self, Vector3(0.8, 0.7, 0.8), p + Vector3(0.9, 0.5, 0.3), m_legno_chiaro, Vector3(0, 0.4, 0))


func _bancarella(pos: Vector3, rot_y: float, tenda: Color) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = rot_y
	add_child(n)
	blocco(n, Vector3(2.8, 0.9, 1.2), Vector3(0, 0.6, 0), m_legno_chiaro)
	for x in [-1.3, 1.3]:
		for z in [-0.55, 0.55]:
			blocco(n, Vector3(0.12, 2.6, 0.12), Vector3(x, 1.4, z), m_legno)
	blocco(n, Vector3(3.2, 0.1, 1.9), Vector3(0, 2.75, 0.2), mat(tenda), Vector3(-0.25, 0, 0))
	for i in 5:
		var c: Color = [Color("e3b23c"), Color("c0392b"), Color("6aa84f"), Color("f0e0b0"), Color("e67e22")][i]
		sfera(n, 0.18, Vector3(-1.0 + i * 0.5, 1.15, 0.1), mat(c))


func _persona(pos: Vector3, veste: Color) -> void:
	var cm := CapsuleMesh.new()
	cm.radius = 0.28
	cm.height = 1.2
	_istanza(self, cm, pos + Vector3(0, 0.6, 0), mat(veste))
	sfera(self, 0.22, pos + Vector3(0, 1.42, 0), mat(Color("f1c9a5")))


# --- Chiesa con campanile --------------------------------------------------

func _chiesa() -> void:
	var n := Node3D.new()
	n.position = Vector3(0, 0, -21.5)
	add_child(n)
	var w := 9.0
	var d := 15.0
	var h := 8.0
	blocco(n, Vector3(w, h, d), Vector3(0, h * 0.5, 0), m_pietra)
	prisma(n, Vector3(w, 4.2, d), Vector3(0, h + 2.1, 0), m_pietra, Vector3(0, PI * 0.5, 0) * 0)
	tetto_a_falde(n, w, d, h, 4.2, tegole(Color("4c505c")), 0.5)
	# portale ad arco
	blocco(n, Vector3(2.2, 3.4, 0.3), Vector3(0, 1.7, d * 0.5 + 0.05), m_legno)
	cilindro(n, 1.1, 1.1, 0.3, Vector3(0, 3.4, d * 0.5 + 0.05), m_legno, 16, Vector3(PI * 0.5, 0, 0))
	blocco(n, Vector3(3.0, 0.3, 1.2), Vector3(0, 0.15, d * 0.5 + 0.6), m_pietra_scura)
	# rosone
	cilindro(n, 1.2, 1.2, 0.2, Vector3(0, h + 0.6, d * 0.5 + 0.02), m_pietra_scura, 24, Vector3(PI * 0.5, 0, 0))
	cilindro(n, 0.95, 0.95, 0.24, Vector3(0, h + 0.6, d * 0.5 + 0.03), mat(Color("3a5a8c"), 0.2), 24, Vector3(PI * 0.5, 0, 0))
	# finestre alte sui fianchi
	for s in [-1, 1]:
		for k in 4:
			blocco(n, Vector3(0.2, 2.2, 0.8), Vector3(s * w * 0.5, 4.6, -5.0 + k * 3.2), m_vetro)
	# campanile sul retro
	var tz := -d * 0.5 - 2.4
	blocco(n, Vector3(4.8, 19.0, 4.8), Vector3(0, 9.5, tz), m_pietra)
	for s in [-1, 1]:
		blocco(n, Vector3(1.2, 2.4, 4.9), Vector3(s * 1.2 * 0, 16.2, tz), m_vetro)
		blocco(n, Vector3(4.9, 2.4, 1.2), Vector3(0, 16.2, tz), m_vetro)
	blocco(n, Vector3(5.2, 0.4, 5.2), Vector3(0, 19.2, tz), m_pietra_scura)
	cilindro(n, 0.0, 3.7, 7.0, Vector3(0, 22.9, tz), tegole(Color("4c505c"), true), 4, Vector3(0, PI * 0.25, 0))
	blocco(n, Vector3(0.15, 1.6, 0.15), Vector3(0, 27.1, tz), mat(Color("c9a640"), 0.4))
	blocco(n, Vector3(0.9, 0.15, 0.15), Vector3(0, 27.3, tz), mat(Color("c9a640"), 0.4))


# --- Mura con torri e porta ------------------------------------------------

func _mura() -> void:
	var lati := 8
	var vertici := []
	for i in lati:
		var a := deg_to_rad(22.5 + i * 45.0)
		vertici.append(Vector3(cos(a), 0, sin(a)) * R_MURA)
	var tetto_torre := tegole(Color("a8472f"), true)
	for i in lati:
		var p1: Vector3 = vertici[i]
		var p2: Vector3 = vertici[(i + 1) % lati]
		var centro := (p1 + p2) * 0.5
		var lung := p1.distance_to(p2)
		var dir := (p2 - p1).normalized()
		var rot := atan2(-dir.z, dir.x)
		if centro.z > R_MURA * 0.8:
			# lato sud: porta d'ingresso
			var pezzo := (lung - 6.0) * 0.5
			for s in [-1, 1]:
				_tratto_mura(centro + dir * s * (3.0 + pezzo * 0.5), pezzo, rot)
			_porta(centro, rot)
		else:
			_tratto_mura(centro, lung, rot)
		cilindro(self, 2.5, 2.7, 9.0, p1 + Vector3(0, 4.5, 0), m_pietra, 20)
		cilindro(self, 2.75, 2.75, 0.4, p1 + Vector3(0, 9.2, 0), m_pietra_scura, 20)
		cilindro(self, 0.0, 3.1, 4.6, p1 + Vector3(0, 11.7, 0), tetto_torre, 20)
		for k in 3:
			var a := rot + k * 2.1
			blocco(self, Vector3(0.18, 1.0, 0.5), p1 + Vector3(cos(a) * 2.55, 6.5, -sin(a) * 2.55), m_vetro, Vector3(0, a, 0))


func _tratto_mura(centro: Vector3, lung: float, rot: float) -> void:
	var n := Node3D.new()
	n.position = centro
	n.rotation.y = rot
	add_child(n)
	blocco(n, Vector3(lung, 6.0, 1.8), Vector3(0, 3.0, 0), m_pietra)
	blocco(n, Vector3(lung, 0.3, 2.2), Vector3(0, 6.1, 0), m_pietra_scura)
	var k := int(lung / 1.3)
	for i in k:
		var x := -lung * 0.5 + 0.65 + i * (lung - 1.3) / maxf(k - 1, 1)
		for s in [-1, 1]:
			blocco(n, Vector3(0.65, 0.9, 0.4), Vector3(x, 6.7, s * 0.9), m_pietra)


func _porta(centro: Vector3, rot: float) -> void:
	var n := Node3D.new()
	n.position = centro
	n.rotation.y = rot
	add_child(n)
	for s in [-1, 1]:
		blocco(n, Vector3(3.4, 10.0, 4.0), Vector3(s * 4.6, 5.0, 0), m_pietra)
		tetto_piramide(n, Vector3(s * 4.6, 10.0, 0), 4.2)
	blocco(n, Vector3(5.8, 3.4, 3.2), Vector3(0, 7.6, 0), m_pietra)
	for i in 5:
		blocco(n, Vector3(0.6, 0.9, 0.5), Vector3(-2.4 + i * 1.2, 9.75, 1.4), m_pietra)
	# grata della porta (sollevata)
	for i in 6:
		blocco(n, Vector3(0.1, 1.2, 0.1), Vector3(-2.2 + i * 0.88, 5.6, 1.7), m_legno)
	blocco(n, Vector3(5.0, 0.12, 0.12), Vector3(0, 5.0, 1.7), m_legno)
	# stendardi
	for s in [-1, 1]:
		blocco(n, Vector3(1.0, 2.2, 0.05), Vector3(s * 4.6, 6.5, 2.03), mat(Color("9b2c24")))
		blocco(n, Vector3(0.5, 0.5, 0.06), Vector3(s * 4.6, 6.8, 2.05), mat(Color("d9b23c")), Vector3(0, 0, PI * 0.25))


func tetto_piramide(genitore: Node3D, pos: Vector3, lato: float) -> void:
	cilindro(genitore, 0.0, lato * 0.72, 3.2, pos + Vector3(0, 1.6, 0), tegole(Color("a8472f"), true), 4, Vector3(0, PI * 0.25, 0))


# --- Case a graticcio ------------------------------------------------------

func _case() -> void:
	for c in CHAT:
		var ang := deg_to_rad(c["angolo"])
		var p := Vector3(cos(ang), 0, sin(ang)) * R_CASE
		casa(p, atan2(-p.x, -p.z), 5.2 + rng.randf() * 0.6, 6.0, 3 if rng.randf() > 0.4 else 2, c["nome"], c["frase"])


func casa(pos: Vector3, rot_y: float, w: float, d: float, piani: int, nome: String = "", frase: String = "") -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = rot_y
	add_child(n)
	var intonaco := mat(INTONACI[rng.randi() % INTONACI.size()])
	var tetto := tegole(TETTI[rng.randi() % TETTI.size()])
	var piano_terra_pietra := rng.randf() > 0.45
	blocco(n, Vector3(w + 0.2, 0.6, d + 0.2), Vector3(0, 0.3, 0), m_pietra_scura)
	var h1 := 2.8
	blocco(n, Vector3(w, h1, d), Vector3(0, 0.6 + h1 * 0.5, 0), m_pietra if piano_terra_pietra else intonaco)
	# porta e finestre del piano terra
	blocco(n, Vector3(1.15, 2.1, 0.12), Vector3(-w * 0.18, 1.65, d * 0.5 + 0.04), m_legno)
	blocco(n, Vector3(1.35, 0.18, 0.16), Vector3(-w * 0.18, 2.75, d * 0.5 + 0.06), m_legno_chiaro)
	_finestra(n, Vector3(w * 0.24, 2.0, d * 0.5), false)
	_finestra(n, Vector3(w * 0.5, 2.0, 0), true)
	_finestra(n, Vector3(-w * 0.5, 2.0, 0), true)
	var y := 0.6 + h1
	var wt := w
	var dt := d
	for p in range(1, piani):
		wt += 0.45
		dt += 0.45
		blocco(n, Vector3(wt + 0.1, 0.26, dt + 0.1), Vector3(0, y + 0.13, 0), m_legno)
		blocco(n, Vector3(wt, 2.5, dt), Vector3(0, y + 0.26 + 1.25, 0), intonaco)
		_graticcio(n, wt, dt, y + 0.26, 2.5)
		for x in [-wt * 0.25, wt * 0.25]:
			_finestra(n, Vector3(x, y + 1.5, dt * 0.5), false)
		_finestra(n, Vector3(wt * 0.5, y + 1.5, -dt * 0.15), true)
		_finestra(n, Vector3(-wt * 0.5, y + 1.5, dt * 0.15), true)
		y += 2.76
	# timpano + tetto
	var alt := wt * 0.55 + 0.6
	prisma(n, Vector3(wt, alt, dt), Vector3(0, y + alt * 0.5, 0), intonaco)
	blocco(n, Vector3(0.16, alt * 0.9, 0.06), Vector3(0, y + alt * 0.45, dt * 0.5 + 0.03), m_legno)
	blocco(n, Vector3(wt * 0.6, 0.16, 0.06), Vector3(0, y + alt * 0.4, dt * 0.5 + 0.03), m_legno)
	blocco(n, Vector3(0.5, 0.6, 0.08), Vector3(0, y + alt * 0.62, dt * 0.5 + 0.03), m_vetro)
	tetto_a_falde(n, wt, dt, y, alt, tetto)
	blocco(n, Vector3(0.75, 2.0, 0.75), Vector3(wt * 0.22, y + alt * 0.7, -dt * 0.2), m_pietra_scura)
	# fioriera sotto una finestra
	if rng.randf() > 0.5:
		blocco(n, Vector3(1.0, 0.22, 0.3), Vector3(w * 0.24, 1.42, d * 0.5 + 0.2), m_legno_chiaro)
		for i in 3:
			sfera(n, 0.13, Vector3(w * 0.24 - 0.3 + i * 0.3, 1.6, d * 0.5 + 0.22), mat([Color("d6455a"), Color("f2c14e"), Color("e86a92")][i]))
	_giardino(n, w, d, -w * 0.18)
	if nome != "":
		# insegna appesa con il nome della chat
		blocco(n, Vector3(0.1, 0.1, 1.1), Vector3(w * 0.1, 3.0, d * 0.5 + 0.55), m_legno)
		blocco(n, Vector3(1.9, 0.75, 0.08), Vector3(w * 0.1, 2.5, d * 0.5 + 1.0), m_legno_chiaro, Vector3(0, PI * 0.5, 0) * 0)
		var l := Label3D.new()
		l.text = nome
		l.font_size = 48
		l.pixel_size = 0.0085
		l.modulate = Color("2b1a0e")
		l.outline_size = 0
		l.position = Vector3(w * 0.1, 2.5, d * 0.5 + 1.05)
		n.add_child(l)
		var l2 := l.duplicate() as Label3D
		l2.position.z = d * 0.5 + 0.95
		l2.rotation.y = PI
		n.add_child(l2)
		var testo := nome if frase == "" else nome + ": " + frase
		etichetta(n, testo, Vector3(0, y + alt + 1.8, 0), 64, frase != "")


func _finestra(genitore: Node3D, pos: Vector3, laterale: bool) -> void:
	var colore_scuri: Color = [Color("3d6b45"), Color("7a2e25"), Color("2f4f7a"), Color("6b4a2e")][rng.randi() % 4]
	if laterale:
		blocco(genitore, Vector3(0.1, 0.95, 0.75), pos, m_vetro)
		blocco(genitore, Vector3(0.12, 0.12, 0.95), pos + Vector3(0, -0.53, 0), m_legno)
		for s in [-1, 1]:
			blocco(genitore, Vector3(0.08, 0.95, 0.36), pos + Vector3(signf(pos.x) * 0.03, 0, s * 0.58), mat(colore_scuri))
	else:
		blocco(genitore, Vector3(0.75, 0.95, 0.1), pos, m_vetro)
		blocco(genitore, Vector3(0.95, 0.12, 0.12), pos + Vector3(0, -0.53, 0), m_legno)
		for s in [-1, 1]:
			blocco(genitore, Vector3(0.36, 0.95, 0.08), pos + Vector3(s * 0.58, 0, 0.03), mat(colore_scuri))


func _graticcio(genitore: Node3D, w: float, d: float, y0: float, h: float) -> void:
	## Travi di legno a vista sui 4 lati del piano.
	for lato in 4:
		var lungo := w if lato < 2 else d
		var s := 1.0 if lato % 2 == 0 else -1.0
		var colonne := int(lungo / 1.3) + 1
		var n := Node3D.new()
		genitore.add_child(n)
		if lato < 2:
			n.position = Vector3(0, 0, s * (d * 0.5 + 0.03))
		else:
			n.position = Vector3(s * (w * 0.5 + 0.03), 0, 0)
			n.rotation.y = PI * 0.5
		for i in colonne + 1:
			var x := -lungo * 0.5 + 0.08 + i * (lungo - 0.16) / colonne
			blocco(n, Vector3(0.16, h, 0.06), Vector3(x, y0 + h * 0.5, 0), m_legno)
		blocco(n, Vector3(lungo, 0.16, 0.06), Vector3(0, y0 + h - 0.08, 0), m_legno)
		blocco(n, Vector3(lungo, 0.14, 0.06), Vector3(0, y0 + h * 0.36, 0), m_legno)
		var pw := (lungo - 0.16) / colonne
		var diag := sqrt(pw * pw + h * h)
		var ang := atan2(h, pw)
		blocco(n, Vector3(diag, 0.13, 0.05), Vector3(-lungo * 0.5 + 0.08 + pw * 0.5, y0 + h * 0.5, 0), m_legno, Vector3(0, 0, ang))
		blocco(n, Vector3(diag, 0.13, 0.05), Vector3(lungo * 0.5 - 0.08 - pw * 0.5, y0 + h * 0.5, 0), m_legno, Vector3(0, 0, -ang))


# --- Giardino recintato con vialetto ---------------------------------------

func _giardino(n: Node3D, w: float, d: float, porta_x: float) -> void:
	var x0 := -w * 0.5 - GIARDINO_LATI
	var x1 := w * 0.5 + GIARDINO_LATI
	var z0 := -d * 0.5 - GIARDINO_DIETRO
	var z1 := d * 0.5 + GIARDINO_DAVANTI
	var prato := mat_shader(_sh_terreno, {"raggio_borgo": -100.0})
	blocco(n, Vector3(x1 - x0, 0.05, z1 - z0), Vector3((x0 + x1) * 0.5, 0.03, (z0 + z1) * 0.5), prato)
	# recinzione con cancelletto davanti alla porta
	var legno_recinto := mat([Color("b08a5a"), Color("e8e2d4"), Color("9a6b45")][rng.randi() % 3])
	_recinto(n, Vector3(x0, 0, z0), Vector3(x1, 0, z0), legno_recinto)
	_recinto(n, Vector3(x0, 0, z0), Vector3(x0, 0, z1), legno_recinto)
	_recinto(n, Vector3(x1, 0, z0), Vector3(x1, 0, z1), legno_recinto)
	_recinto(n, Vector3(x0, 0, z1), Vector3(porta_x - 0.75, 0, z1), legno_recinto)
	_recinto(n, Vector3(porta_x + 0.75, 0, z1), Vector3(x1, 0, z1), legno_recinto)
	# cancelletto aperto
	var cancello := Node3D.new()
	cancello.position = Vector3(porta_x + 0.75, 0, z1)
	cancello.rotation.y = -1.45
	n.add_child(cancello)
	for i in 4:
		blocco(cancello, Vector3(0.08, 0.85, 0.06), Vector3(-0.15 - i * 0.38, 0.5, 0), legno_recinto)
	for y in [0.3, 0.75]:
		blocco(cancello, Vector3(1.4, 0.08, 0.05), Vector3(-0.72, y, 0), legno_recinto)
	# vialetto: lastre di pietra dentro, ghiaia fuori fino alla piazza
	var z := d * 0.5 + 0.45
	while z < z1 - 0.2:
		cilindro(n, 0.38, 0.4, 0.07, Vector3(porta_x + sin(z * 2.0) * 0.08, 0.08, z), m_pietra_scura, 10)
		z += 0.75
	var fuori := R_CASE - z1 - R_PIAZZA + 0.6
	if fuori > 0.0:
		blocco(n, Vector3(1.3, 0.06, fuori), Vector3(porta_x, 0.04, z1 + fuori * 0.5), mat(Color("9c8f7a")))
	# aiuola di fiori lungo il vialetto
	var fiori := [Color("d6455a"), Color("f2c14e"), Color("e86a92"), Color("ffffff"), Color("9b6ad6")]
	for lato in [-1, 1]:
		var xa: float = porta_x + lato * 0.9
		blocco(n, Vector3(0.5, 0.12, z1 - d * 0.5 - 1.0), Vector3(xa, 0.07, (d * 0.5 + z1) * 0.5), mat(Color("5a4030")))
		var zz := d * 0.5 + 0.7
		while zz < z1 - 0.4:
			sfera(n, 0.16, Vector3(xa + rng.randf_range(-0.12, 0.12), 0.25, zz), mat(fiori[rng.randi() % fiori.size()]))
			sfera(n, 0.12, Vector3(xa, 0.16, zz + 0.2), mat(Color("4f8a3a")))
			zz += 0.42
	# orto sul lato destro
	var ox := (porta_x + 1.4 + x1) * 0.5
	var larg_orto := x1 - porta_x - 2.0
	for k in 3:
		var oz := d * 0.5 + 1.0 + k * 1.1
		blocco(n, Vector3(larg_orto, 0.18, 0.6), Vector3(ox, 0.09, oz), mat(Color("6b4a32")))
		var px := ox - larg_orto * 0.5 + 0.3
		while px < ox + larg_orto * 0.5 - 0.2:
			sfera(n, 0.2, Vector3(px, 0.32, oz), mat(Color("5f9e3a") if k != 1 else Color("7cb342")), 0.8)
			if k == 2:
				sfera(n, 0.08, Vector3(px + 0.1, 0.42, oz + 0.1), mat(Color("d8402a")))
			px += 0.45
	# alberello da frutto nell'angolo a sinistra, cespugli e panchina
	var at := Vector3(x0 + 1.1, 0, z1 - 1.1)
	cilindro(n, 0.12, 0.18, 1.6, at + Vector3(0, 0.8, 0), mat(Color("5a3d28")), 8)
	sfera(n, 1.0, at + Vector3(0, 2.2, 0), mat(Color("4f8a34")), 0.9)
	for i in 6:
		var a := i * 1.05
		sfera(n, 0.09, at + Vector3(cos(a) * 0.75, 2.0 + (i % 2) * 0.5, sin(a) * 0.75), mat(Color("d93a2b") if i % 2 == 0 else Color("f2b233")))
	for p in [Vector3(x0 + 0.6, 0, z0 + 0.6), Vector3(x1 - 0.6, 0, z0 + 0.6), Vector3(x0 + 0.6, 0, d * 0.5 + 0.3)]:
		sfera(n, 0.55, p + Vector3(0, 0.45, 0), mat(Color("3f6b2e")), 0.85)
	var pb := Vector3(x0 + 0.55, 0, d * 0.5 + 1.6)
	blocco(n, Vector3(0.45, 0.08, 1.4), pb + Vector3(0, 0.45, 0), m_legno_chiaro)
	blocco(n, Vector3(0.08, 0.45, 1.4), pb + Vector3(-0.2, 0.7, 0), m_legno_chiaro)
	for s in [-0.6, 0.6]:
		blocco(n, Vector3(0.4, 0.42, 0.08), pb + Vector3(0, 0.21, s), m_legno)


func _recinto(genitore: Node3D, a: Vector3, b: Vector3, m: Material) -> void:
	var lung := a.distance_to(b)
	if lung < 0.2:
		return
	var dir := (b - a) / lung
	var pali := int(lung / 0.9) + 1
	for i in pali + 1:
		var p := a + dir * (lung * i / pali)
		blocco(genitore, Vector3(0.1, 0.95, 0.1), p + Vector3(0, 0.48, 0), m)
		blocco(genitore, Vector3(0.12, 0.08, 0.12), p + Vector3(0, 0.98, 0), m)
	var rot := Vector3(0, atan2(-dir.z, dir.x), 0)
	for y in [0.35, 0.75]:
		blocco(genitore, Vector3(lung, 0.07, 0.05), (a + b) * 0.5 + Vector3(0, y, 0), m, rot)


# --- Campagna: campi, mulino, alberi ---------------------------------------

func _campi_e_mulino() -> void:
	var colori := [Color("d9b24a"), Color("8fae3c"), Color("7a5a3a"), Color("c7a23f")]
	var campi := [
		[Vector3(-46, 0, 8), 0.3], [Vector3(-44, 0, -14), -0.2], [Vector3(46, 0, 14), 0.15],
		[Vector3(44, 0, -8), -0.35], [Vector3(-24, 0, 46), 0.5], [Vector3(26, 0, 46), -0.4],
	]
	for i in campi.size():
		var n := Node3D.new()
		n.position = campi[i][0]
		n.rotation.y = campi[i][1]
		add_child(n)
		var c: Color = colori[i % colori.size()]
		for k in 9:
			blocco(n, Vector3(13.0, 0.28, 0.7), Vector3(0, 0.12, -5.0 + k * 1.25), mat(c.darkened(0.06 * (k % 2))))
		blocco(n, Vector3(14.0, 0.06, 12.0), Vector3(0, 0.03, 0), mat(c.darkened(0.35)))
	# covoni di fieno
	for p in [Vector3(-38, 0, 2), Vector3(-39.5, 0, 4), Vector3(52, 0, 20)]:
		cilindro(self, 0.0, 1.0, 1.6, p + Vector3(0, 0.8, 0), mat(Color("d8b552")), 10)
	# mulino a vento
	var m := Node3D.new()
	m.position = Vector3(47, 0, -27)
	add_child(m)
	cilindro(m, 2.0, 3.0, 9.0, Vector3(0, 4.5, 0), m_pietra, 16)
	cilindro(m, 0.0, 2.5, 3.0, Vector3(0, 10.5, 0), tegole(Color("6e4a35"), true), 16)
	blocco(m, Vector3(1.2, 2.0, 0.2), Vector3(0, 1.0, 2.9), m_legno, Vector3(-0.1, 0, 0))
	m.rotation.y = atan2(-m.position.x, -m.position.z)
	pale_mulino = Node3D.new()
	pale_mulino.position = Vector3(0, 8.5, 2.4)
	m.add_child(pale_mulino)
	cilindro(pale_mulino, 0.3, 0.3, 0.6, Vector3.ZERO, m_legno, 10, Vector3(PI * 0.5, 0, 0))
	for k in 4:
		var braccio := Node3D.new()
		braccio.rotation.z = k * PI * 0.5
		pale_mulino.add_child(braccio)
		blocco(braccio, Vector3(0.2, 7.0, 0.15), Vector3(0, 3.5, 0.2), m_legno)
		blocco(braccio, Vector3(1.4, 5.5, 0.05), Vector3(0.75, 4.0, 0.25), mat(Color("efe6d2")))


func _alberi() -> void:
	var tronco := CylinderMesh.new()
	tronco.top_radius = 0.18
	tronco.bottom_radius = 0.28
	tronco.height = 2.2
	tronco.radial_segments = 8
	var chioma := SphereMesh.new()
	chioma.radius = 1.6
	chioma.height = 2.8
	chioma.radial_segments = 10
	chioma.rings = 6
	var cono := CylinderMesh.new()
	cono.top_radius = 0.0
	cono.bottom_radius = 1.5
	cono.height = 3.4
	cono.radial_segments = 10
	var verdi := [mat(Color("3f6b2e")), mat(Color("4f7d34")), mat(Color("35592a")), mat(Color("5b8a3a"))]
	var m_tronco := mat(Color("5a3d28"))
	var piantati := 0
	var tentativi := 0
	while piantati < 230 and tentativi < 3000:
		tentativi += 1
		var x := rng.randf_range(-130, 130)
		var z := rng.randf_range(-130, 130)
		var r := Vector2(x, z).length()
		if r < R_MURA + 5.0:
			continue
		if absf(x - sin(z * 0.03) * 6.0) < 5.0 and z > 0:
			continue
		if r < PIANO_PIATTO and rng.randf() > 0.25:
			continue
		if Vector2(x - 47, z + 27).length() < 7.0:
			continue
		var y := altezza(x, z)
		var s := rng.randf_range(0.8, 1.4)
		var n := Node3D.new()
		n.position = Vector3(x, y, z)
		n.scale = Vector3.ONE * s
		add_child(n)
		_istanza(n, tronco, Vector3(0, 1.1, 0), m_tronco)
		var v: Material = verdi[rng.randi() % verdi.size()]
		if rng.randf() > 0.45:
			_istanza(n, chioma, Vector3(0, 3.2, 0), v)
			_istanza(n, chioma, Vector3(0.7, 2.6, 0.3), v).scale = Vector3.ONE * 0.7
		else:
			_istanza(n, cono, Vector3(0, 2.8, 0), v)
			_istanza(n, cono, Vector3(0, 4.0, 0), v).scale = Vector3.ONE * 0.75
		piantati += 1
	# qualche albero dentro le mura
	for p in [Vector3(-14, 0, -26), Vector3(14, 0, -26), Vector3(8, 0, 30), Vector3(-29, 0, 8), Vector3(29, 0, -6), Vector3(-26, 0, -16)]:
		var n := Node3D.new()
		n.position = p
		add_child(n)
		_istanza(n, tronco, Vector3(0, 1.1, 0), m_tronco)
		_istanza(n, chioma, Vector3(0, 3.2, 0), verdi[1])
