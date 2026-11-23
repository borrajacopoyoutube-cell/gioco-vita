extends Camera3D
## Telecamera che gira attorno al borgo.
## Tasto sinistro + trascina: ruota. Rotellina: zoom. Tasto destro + trascina: sposta.
## Frecce / WASD: ruota e avvicina. Se non tocchi nulla gira piano da sola.

@export var bersaglio := Vector3(0, 3, 0)
@export var distanza := 72.0
@export var imbardata := 35.0      # gradi, rotazione orizzontale
@export var beccheggio := 36.0     # gradi, inclinazione verso il basso
@export var giro_automatico := true

var _fermo := 0.0


func _ready() -> void:
	far = 600.0
	fov = 50.0
	aggiorna()


func aggiorna() -> void:
	var b := deg_to_rad(beccheggio)
	var i := deg_to_rad(imbardata)
	var dir := Vector3(sin(i) * cos(b), sin(b), cos(i) * cos(b))
	position = bersaglio + dir * distanza
	look_at(bersaglio, Vector3.UP)


func _process(delta: float) -> void:
	_fermo += delta
	var ruota := Input.get_axis("ui_left", "ui_right")
	var zoom := Input.get_axis("ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A): ruota -= 1.0
	if Input.is_key_pressed(KEY_D): ruota += 1.0
	if Input.is_key_pressed(KEY_W): zoom -= 1.0
	if Input.is_key_pressed(KEY_S): zoom += 1.0
	if ruota != 0.0 or zoom != 0.0:
		_fermo = 0.0
	imbardata += ruota * 60.0 * delta
	distanza = clampf(distanza + zoom * 40.0 * delta, 12.0, 160.0)
	if giro_automatico and _fermo > 4.0:
		imbardata += 3.0 * delta
	aggiorna()


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion:
		if evento.button_mask & MOUSE_BUTTON_MASK_LEFT:
			imbardata -= evento.relative.x * 0.3
			beccheggio = clampf(beccheggio + evento.relative.y * 0.3, 8.0, 85.0)
			_fermo = 0.0
		elif evento.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			var destra := global_transform.basis.x
			var avanti := Vector3(-sin(deg_to_rad(imbardata)), 0, -cos(deg_to_rad(imbardata)))
			bersaglio += (-destra * evento.relative.x + avanti * evento.relative.y) * distanza * 0.0015
			_fermo = 0.0
	elif evento is InputEventMouseButton and evento.pressed:
		if evento.button_index == MOUSE_BUTTON_WHEEL_UP:
			distanza = maxf(12.0, distanza * 0.9)
			_fermo = 0.0
		elif evento.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distanza = minf(160.0, distanza * 1.1)
			_fermo = 0.0
