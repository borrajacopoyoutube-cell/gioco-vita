extends Node
## Strumento: salva alcune viste PNG del borgo 3D.
## Uso: godot --path . res://tools/cattura3d.tscn -- <cartella_uscita>

const VISTE := [
	{"nome": "panoramica", "imbardata": 35.0, "beccheggio": 38.0, "distanza": 80.0, "bersaglio": Vector3(0, 2, 0)},
	{"nome": "piazza", "imbardata": 0.0, "beccheggio": 30.0, "distanza": 36.0, "bersaglio": Vector3(0, 2, -2)},
	{"nome": "giardino", "imbardata": -60.0, "beccheggio": 26.0, "distanza": 15.0, "bersaglio": Vector3(16.5, 1.5, -9.5)},
	{"nome": "porta", "imbardata": 5.0, "beccheggio": 14.0, "distanza": 34.0, "bersaglio": Vector3(0, 5, 30)},
	{"nome": "dall_alto", "imbardata": 0.0, "beccheggio": 70.0, "distanza": 110.0, "bersaglio": Vector3(0, 0, 0)},
]

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var uscita := "user://" if args.is_empty() else args[0]
	var borgo = load("res://borgo/borgo3d.tscn").instantiate()
	add_child(borgo)
	var cam: Camera3D = borgo.get_node("Camera")
	cam.giro_automatico = false
	cam.set_process(false)
	for v in VISTE:
		cam.imbardata = v["imbardata"]
		cam.beccheggio = v["beccheggio"]
		cam.distanza = v["distanza"]
		cam.bersaglio = v["bersaglio"]
		cam.aggiorna()
		for i in 4:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(uscita.path_join("borgo_%s.png" % v["nome"]))
	get_tree().quit()
