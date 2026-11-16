extends SceneTree
# PRUEBAS AUTOMÁTICAS: juega solo y guarda capturas de pantalla (no hace falta para jugar).
#
# Dibuja el juego dentro de un SubViewport de 1600x900. La ventana real es pequeña y queda siempre
# visible, porque Godot deja de dibujar una ventana que está tapada por otra.
#
# Cómo se usa (desde la carpeta del proyecto; cambia GODOT por la ruta de tu Godot_..._console.exe):
#   GODOT --path . --audio-driver Dummy --resolution 160x90 -s tools/probar_juego.gd -- <modo> ...
#
# Modos (lo que va después de "--"):
#   foto <escena.tscn> <salida.png> [espera]
#       abre una escena y le toma una foto
#   partida <carpeta> [paquete A|B] [buena|mala|0|1] [semilla] [fotos extra: d02_config,d05_decision1...]
#       juega los 14 días solo y fotografía el día 1 y las fases que pidas
#   final <carpeta> <bueno|intermedio|malo>
#       muestra un final concreto
#   guion <carpeta> <escena.tscn> <metodo,espera,metodo,espera...>
#       llama métodos de la escena uno por uno (con parámetros: _on_paquete:A) y fotografía cada paso
#   minis <carpeta>
#       muestra los 4 minijuegos de reparación

var vp: SubViewport
var gm: Node
var carpeta: String = ""
var vistos: Dictionary = {}

func _initialize() -> void:
	_correr()

func _preparar() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_size(Vector2i(160, 90))
	var pantalla: Vector2i = DisplayServer.screen_get_size()
	DisplayServer.window_set_position(Vector2i(pantalla.x - 170, pantalla.y - 150))
	vp = SubViewport.new()
	vp.size = Vector2i(1600, 900)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.gui_embed_subwindows = true
	root.add_child(vp)
	# Vista previa pequeña en la ventana real
	var vista = TextureRect.new()
	vista.texture = vp.get_texture()
	vista.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vista.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(vista)
	gm = root.get_node("/root/GameManager")

# Mueve la escena actual (la que carga el juego bajo root) al SubViewport
func _adoptar() -> Node:
	var escena: Node = current_scene
	if escena != null and escena.get_parent() == root:
		for viejo in vp.get_children():
			viejo.queue_free()
		root.remove_child(escena)
		vp.add_child(escena)
	return escena

func _escena() -> Node:
	_adoptar()
	var ultimo: Node = null
	for hijo in vp.get_children():
		if not hijo.is_queued_for_deletion():
			ultimo = hijo
	return ultimo

func _abrir(ruta: String, espera: float = 1.0) -> Node:
	change_scene_to_file(ruta)
	await process_frame
	await process_frame
	_adoptar()
	await create_timer(espera).timeout
	return _escena()

func _esperar(seg: float) -> void:
	var fin: float = Time.get_ticks_msec() / 1000.0 + seg
	while Time.get_ticks_msec() / 1000.0 < fin:
		await process_frame
		_adoptar()

func _foto(nombre: String) -> void:
	await process_frame
	await process_frame
	_adoptar()
	await process_frame
	var img: Image = vp.get_texture().get_image()
	var ruta: String = nombre if nombre.ends_with(".png") else carpeta + "/" + nombre + ".png"
	img.save_png(ruta)
	print("FOTO ", nombre)

func _correr() -> void:
	await process_frame
	_preparar()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var modo: String = args[0] if args.size() > 0 else "foto"
	match modo:
		"foto":
			await _abrir(args[1], float(args[3]) if args.size() > 3 else 1.5)
			await _foto(args[2])
		"partida":
			await _partida(args)
		"final":
			await _final(args)
		"guion":
			await _guion(args)
		"minis":
			await _minis(args)
	quit(0)

# ---------------------------------------------------------------
func _guion(args: PackedStringArray) -> void:
	carpeta = args[1]
	var escena: Node = await _abrir(args[2], 1.2)
	await _foto("g00_inicio")
	var pasos: PackedStringArray = args[3].split(",") if args.size() > 3 else PackedStringArray()
	var n: int = 1
	var i: int = 0
	while i + 1 < pasos.size():
		escena = _escena()
		var partes: PackedStringArray = pasos[i].split(":")
		var metodo: String = partes[0]
		var params: Array = []
		for j in range(1, partes.size()):
			var p: String = partes[j]
			params.append(int(p) if p.is_valid_int() else p)
		if escena != null and escena.has_method(metodo):
			escena.callv(metodo, params)
		else:
			print("SIN METODO ", metodo)
		await _esperar(float(pasos[i + 1]))
		await _foto("g%02d_%s" % [n, metodo.trim_prefix("_")])
		n += 1
		i += 2

# ---------------------------------------------------------------
func _final(args: PackedStringArray) -> void:
	carpeta = args[1]
	var tipo: String = args[2]
	gm.nueva_partida()
	gm.aplicar_plan(gm.paquetes["B"]["niveles"], "Paquete B")
	gm.dia_actual = 14
	gm.decisiones_totales = 26
	gm.decisiones_buenas = 17
	gm.ciencia = 82.0
	gm.nave = {"agua": 31.0, "comida": 44.0, "oxigeno": 38.0, "electricidad": 52.0, "combustible": 47.0}
	gm.tripulantes["marcus"]["salud"] = 62.0
	gm.tripulantes["leo"]["estres"] = 55.0
	if tipo == "intermedio":
		gm.ciencia = 48.0
		gm.tripulantes["marcus"]["salud"] = 0.0
		gm.tripulantes["sofia"]["salud"] = 38.0
		gm.nave["agua"] = 12.0
	elif tipo == "malo":
		gm.dia_actual = 9
		gm.nave["oxigeno"] = 0.0
		gm.ciencia = 35.0
		gm.tripulantes["elena"]["salud"] = 20.0
	await _abrir("res://scenes/final.tscn", 3.0)
	await _foto("final_%s_1" % tipo)
	await _esperar(4.5)
	await _foto("final_%s_2" % tipo)
	var fin: Node = _escena()
	fin.call("_abrir_informe")
	await _esperar(2.4)
	await _foto("final_%s_informe" % tipo)

# ---------------------------------------------------------------
func _partida(args: PackedStringArray) -> void:
	carpeta = args[1]
	var paquete: String = args[2] if args.size() > 2 else "B"
	var modo_op: String = args[3] if args.size() > 3 else "buena"
	var semilla: int = int(args[4]) if args.size() > 4 else 351
	var extra: PackedStringArray = args[5].split(",") if args.size() > 5 else PackedStringArray()
	gm.nueva_partida()
	gm.rng.seed = semilla
	seed(semilla)
	gm.aplicar_plan(gm.paquetes[paquete]["niveles"], "Paquete " + paquete)
	await _abrir("res://scenes/mission.tscn", 1.2)

	var pasos: int = 0
	var ultima: String = ""
	while pasos < 500:
		pasos += 1
		var escena: Node = _escena()
		if escena == null:
			await _esperar(0.2)
			continue
		if escena.name == "Final":
			break
		var fase: String = String(escena.get("fase"))
		var dia: int = int(gm.dia_actual)
		var clave: String = "d%02d_%s" % [dia, fase]
		if fase == "decision" or fase == "feedback":
			clave += str(escena.get("numero_decision"))
		var quiero: bool = dia == 1 or clave in extra
		if fase == "minijuego":
			clave = "d%02d_minijuego" % dia
			quiero = quiero or ("minijuego" in extra and not ("mini" in vistos))
			if quiero:
				vistos["mini"] = true
		if quiero and clave != ultima and fase not in ["transicion", "saliendo", "aviso"]:
			await _esperar(0.9)
			await _foto(clave)
		if clave != ultima:
			print("T %6.1f  %s  fps=%d" % [Time.get_ticks_msec() / 1000.0, clave, Engine.get_frames_per_second()])
		ultima = clave
		match fase:
			"config":
				escena.call("_on_iniciar_dia")
			"registro", "feedback", "resumen":
				escena.call("_on_continuar")
			"minijuego":
				var mini = escena.get("minijuego")
				if mini != null and is_instance_valid(mini) and mini.get("activo"):
					mini.call("forzar", -1.0 if modo_op == "mala" else 1.0)
			"decision":
				var orden: Array = escena.get("orden_opciones")
				var d: Dictionary = escena.get("decision_actual")
				var idx: int = int(orden[0]) if orden.size() > 0 else 0
				if modo_op == "mala":
					for i in orden:
						var o: Dictionary = d["opciones"][i]
						if o.get("trampa", false) or String(o.get("tier_fijo", "")) == "malo":
							idx = int(i)
				elif modo_op == "buena":
					# La de mejor puntaje esperado según el propio GameManager
					var mejor: float = -99.0
					for i in orden:
						var o2: Dictionary = d["opciones"][i]
						var p: float = 0.0
						if o2.has("tier_fijo"):
							p = {"bueno": 1.0, "intermedio": 0.0, "malo": -1.0}[String(o2["tier_fijo"])]
						else:
							p = float(gm.calcular_p(d, o2, false, []))
						if p > mejor:
							mejor = p
							idx = int(i)
				elif orden.size() > 0:
					idx = int(orden[mini(int(modo_op), orden.size() - 1)])
				escena.call("_on_opcion", idx)
		await _esperar(0.6)

	print("PASOS ", pasos, " DIA ", gm.dia_actual, " FINAL ", gm.evaluar_final(), " PUNTAJE ", gm.puntaje()["total"])
	print("NAVE ", gm.nave, " CIENCIA ", gm.ciencia, " VIVOS ", gm.vivos())
	await _esperar(7.5)
	await _foto("final_escena")
	var fin: Node = _escena()
	if fin != null and fin.has_method("_abrir_informe"):
		fin.call("_abrir_informe")
		await _esperar(2.4)
		await _foto("final_informe")

# ---------------------------------------------------------------
# Muestra los 4 minijuegos (uno tras otro) y los fotografía a medio jugar y terminados
func _minis(args: PackedStringArray) -> void:
	carpeta = args[1]
	var Mini = load("res://srcipts/Minijuego.gd")
	var Est = load("res://srcipts/Estilo.gd")
	var raiz = Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.theme = Est.tema()
	vp.add_child(raiz)
	var fondo = ColorRect.new()
	fondo.color = Color(0.03, 0.05, 0.11)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.add_child(fondo)
	var y: float = 10.0
	var lista: Array = []
	for tipo in ["sellar", "alinear"]:
		var m = Mini.new()
		raiz.add_child(m)
		m.position = Vector2(60, y)
		m.size = Vector2(1000, 330)
		y += 350.0
		m.iniciar(tipo, 1.0)
		lista.append(m)
	await _esperar(1.2)
	lista[0].call("_clic", lista[0].fugas[0]["pos"])
	lista[0].call("_clic", lista[0].fugas[1]["pos"])
	lista[1].call("_intento_alinear")
	await _esperar(0.3)
	await _foto("minis_1")
	for m in lista:
		m.queue_free()
	lista = []
	y = 10.0
	for tipo in ["secuencia", "valvula"]:
		var m2 = Mini.new()
		raiz.add_child(m2)
		m2.position = Vector2(60, y)
		m2.size = Vector2(1000, 330)
		y += 350.0
		m2.iniciar(tipo, 1.0)
		lista.append(m2)
	lista[1].set("_pulsado", true)
	await _esperar(1.3)
	await _foto("minis_2")
	await _esperar(2.4)
	lista[0].call("_clic", lista[0].call("_rect_interruptor", int(lista[0].orden[0])).get_center())
	await _esperar(0.15)
	await _foto("minis_3")
	lista[0].call("forzar", 1.0)
	lista[1].call("forzar", -0.6)
	await _esperar(0.4)
	await _foto("minis_4")
