extends Control
# Fase 0: preparación en Cabo Cañaveral. De los 10.000 CM, 4.000 ya están gastados en los suministros
# básicos obligatorios y 6.000 se reparten entre el Paquete A, el Paquete B o una configuración personalizada.

var niveles: Dictionary = {}
var etiquetas_nivel: Dictionary = {}
var botones_menos: Dictionary = {}
var botones_mas: Dictionary = {}
var etiqueta_presupuesto: Label
var etiqueta_resultado: Label
var etiqueta_mensaje: Label
var etiqueta_plan: Label

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in GameManager.controles:
		niveles[c["id"]] = 0

	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	scroll.add_child(col)

	_texto(col, "MYG-351: LAST SIGNAL")
	_texto(col, "FASE 0: PREPARACIÓN EN CABO CAÑAVERAL")
	_texto(col, "Tres días antes del lanzamiento, los cuatro astronautas se reúnen frente a la consola de carga de la Orión. La capacidad de carga es limitada y no habrá rescate inmediato: la Tierra está a 384.400 km. La misión dura 14 días y cada decisión de hoy te cobrará más adelante.")
	_texto(col, "Memo NASA: en misiones tripuladas fuera de la órbita baja, el soporte vital (ECLSS) debe tener márgenes de redundancia antes de asignar masa a cargas útiles secundarias.")
	col.add_child(HSeparator.new())

	etiqueta_presupuesto = _texto(col, "")

	var fila_paquetes = HBoxContainer.new()
	col.add_child(fila_paquetes)
	for clave in GameManager.paquetes:
		var b = Button.new()
		b.text = String(GameManager.paquetes[clave]["nombre"])
		b.tooltip_text = String(GameManager.paquetes[clave]["descripcion"])
		b.pressed.connect(_on_paquete.bind(clave))
		fila_paquetes.add_child(b)
	var b_reiniciar = Button.new()
	b_reiniciar.text = "Empezar de cero"
	b_reiniciar.pressed.connect(_on_reiniciar)
	fila_paquetes.add_child(b_reiniciar)

	for clave in GameManager.paquetes:
		_texto(col, "%s: %s" % [String(GameManager.paquetes[clave]["nombre"]).split(":")[0], GameManager.paquetes[clave]["descripcion"]])

	col.add_child(HSeparator.new())
	_texto(col, "CONFIGURACIÓN PERSONALIZADA (usa - y + para repartir los 6.000 CM)")
	for c in GameManager.controles:
		var bloque = VBoxContainer.new()
		col.add_child(bloque)
		var fila = HBoxContainer.new()
		bloque.add_child(fila)
		var nombre = Label.new()
		nombre.text = "%s (%d CM por nivel)" % [c["nombre"], c["costo"]]
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nombre)
		var menos = Button.new()
		menos.text = " - "
		menos.pressed.connect(_on_cambiar.bind(c["id"], -1))
		fila.add_child(menos)
		var nivel = Label.new()
		nivel.custom_minimum_size = Vector2(70, 0)
		nivel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fila.add_child(nivel)
		var mas = Button.new()
		mas.text = " + "
		mas.pressed.connect(_on_cambiar.bind(c["id"], 1))
		fila.add_child(mas)
		var ayuda = _texto(bloque, String(c["efecto"]))
		ayuda.modulate = Color(0.75, 0.75, 0.75)
		etiquetas_nivel[c["id"]] = nivel
		botones_menos[c["id"]] = menos
		botones_mas[c["id"]] = mas

	col.add_child(HSeparator.new())
	etiqueta_plan = _texto(col, "")
	etiqueta_resultado = _texto(col, "")

	var sin_tiempo = CheckButton.new()
	sin_tiempo.text = "Modo aprendizaje (sin temporizador en las decisiones)"
	sin_tiempo.button_pressed = GameManager.modo_sin_temporizador
	sin_tiempo.toggled.connect(_on_modo_sin_tiempo)
	col.add_child(sin_tiempo)

	etiqueta_mensaje = _texto(col, "")
	var iniciar = Button.new()
	iniciar.text = "INICIAR MISIÓN"
	iniciar.custom_minimum_size = Vector2(0, 48)
	iniciar.pressed.connect(_on_iniciar)
	col.add_child(iniciar)

	actualizar()

func _texto(padre: Control, texto: String) -> Label:
	var l = Label.new()
	l.text = texto
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padre.add_child(l)
	return l

func _gastado() -> int:
	return GameManager.costo_plan(niveles)

func _on_paquete(clave: String):
	niveles = GameManager.paquetes[clave]["niveles"].duplicate()
	etiqueta_mensaje.text = ""
	actualizar()

func _on_reiniciar():
	for c in GameManager.controles:
		niveles[c["id"]] = 0
	etiqueta_mensaje.text = ""
	actualizar()

func _on_cambiar(id: String, delta: int):
	var control: Dictionary = {}
	for c in GameManager.controles:
		if c["id"] == id:
			control = c
	var nuevo: int = int(niveles[id]) + delta
	if nuevo < 0 or nuevo > int(control["max"]):
		return
	if delta > 0 and _gastado() + int(control["costo"]) > GameManager.PRESUPUESTO_LIBRE:
		etiqueta_mensaje.text = "No alcanza el presupuesto: quedan %d CM." % (GameManager.PRESUPUESTO_LIBRE - _gastado())
		return
	niveles[id] = nuevo
	etiqueta_mensaje.text = ""
	actualizar()

func _on_modo_sin_tiempo(activado: bool):
	GameManager.modo_sin_temporizador = activado

func actualizar():
	var gastado: int = _gastado()
	etiqueta_presupuesto.text = "Presupuesto total: %d CM  |  Suministros básicos obligatorios: %d CM  |  Gastado en tu configuración: %d CM  |  Disponible: %d CM" % [
		GameManager.PRESUPUESTO_TOTAL, GameManager.COSTO_OBLIGATORIO, gastado, GameManager.PRESUPUESTO_LIBRE - gastado]
	for c in GameManager.controles:
		var id: String = c["id"]
		etiquetas_nivel[id].text = "%d / %d" % [niveles[id], c["max"]]
	var p: Dictionary = GameManager.parametros_plan(niveles)
	etiqueta_plan.text = "Plan actual: " + GameManager.nombre_plan(niveles)
	etiqueta_resultado.text = "Así despegará Orión:\n- Agua, comida y oxígeno: -%.1f %% por día (la referencia NASA es 6,5 %%)\n- Electricidad: -%.1f %% por día\n- Filtros de CO2: %d cartuchos\n- Estrés base: +%.1f por día\n- Ciencia máxima alcanzable: %d %% (el final bueno exige 70 %%)\n- Costo de maniobras de combustible: x%.2f" % [
		p["consumo_basico"], p["consumo_elec"], p["filtros"], p["estres_base"], roundi(p["ciencia_max"]), p["mult_combustible"]]

func _on_iniciar():
	if _gastado() > GameManager.PRESUPUESTO_LIBRE:
		etiqueta_mensaje.text = "Te pasaste del presupuesto."
		return
	GameManager.nueva_partida()
	GameManager.aplicar_plan(niveles, GameManager.nombre_plan(niveles))
	get_tree().change_scene_to_file("res://scenes/mission.tscn")
