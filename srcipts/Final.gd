extends Control
# Pantalla de los 3 finales (cada uno con su propia escena dibujada):
#   bueno      -> la Orión baja con sus paracaídas y ameriza al amanecer
#   intermedio -> la cápsula flota sola bajo la lluvia
#   malo       -> la nave a la deriva en el espacio y la telemetría se vuelve una línea plana
# Qué final toca lo decide GameManager.evaluar_final(); aquí solo se dibuja y se muestra el informe.

const Estilo = preload("res://srcipts/Estilo.gd")
const FondoEspacio = preload("res://srcipts/FondoEspacio.gd")
const Memos = preload("res://srcipts/Memos.gd")

const SUBTITULO: Dictionary = {"bueno": "FINAL BUENO", "intermedio": "FINAL INTERMEDIO", "malo": "FINAL MALO"}
const TITULO: Dictionary = {"bueno": "MISIÓN CUMPLIDA", "intermedio": "MISIÓN ABORTADA", "malo": "SILENCIO TOTAL"}
const NARRATIVA: Dictionary = {
	"bueno": "Los paracaídas de la Orión se despliegan sobre el océano Pacífico. Elena, Marcus, Sofía y Leo regresan como héroes.",
	"intermedio": "La cápsula ameriza entre silencio radiofónico. Están vivos, pero la ciencia fracasó y el costo humano los acompañará siempre.",
	"malo": "La Orión queda a la deriva en órbita silenciosa. En Houston, la línea de telemetría se vuelve plana bajo un último registro: MYG-351: Last Signal.",
}
const PUNTOS: Array = [
	["supervivencia", "Supervivencia", 400.0, "salud"],
	["ciencia", "Ciencia", 250.0, "ciencia"],
	["recursos", "Recursos", 150.0, "agua"],
	["decisiones", "Buenas decisiones", 150.0, "resultado_bueno"],
	["cohesion", "Cohesión del equipo", 50.0, "confianza"],
]

var tipo: String = "malo"
var color: Color = Color(1, 1, 1)

var grupo_capsula: Node2D
var capsula: Sprite2D
var paracaidas: Sprite2D
var agua: ColorRect
var nave: Sprite2D
var linea_vida: Line2D
var etq_senal: Label
var bloque_titulo: VBoxContainer
var boton_informe: Button
var capa_informe: Control
var etq_total: Label

var _t: float = 0.0
var _amerizo: bool = false
var _x_capsula: float = 0.72

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Estilo.tema()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tipo = GameManager.evaluar_final()
	color = Estilo.COLOR_RESULTADO[tipo]

	Sonido.zumbido(false)
	Sonido.musica("")
	match tipo:
		"bueno":
			_escena_mar("res://assets/finales/final_bueno.png", true)
			Sonido.efecto("final_bueno", 2.0)
		"intermedio":
			_escena_mar("res://assets/finales/final_intermedio.png", false)
			Sonido.efecto("final_intermedio", 2.0)
		_:
			_escena_espacio()
			Sonido.efecto("linea_plana", 0.0)
	_construir_titulo()
	_construir_informe()
	Estilo.aparecer(self, 1.2)

# ---------------------------------------------------------------
# Escenas
# ---------------------------------------------------------------
func _escena_mar(ruta_fondo: String, con_paracaidas: bool) -> void:
	var fondo = TextureRect.new()
	fondo.texture = load(ruta_fondo)
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	grupo_capsula = Node2D.new()
	grupo_capsula.scale = Vector2(5, 5)
	add_child(grupo_capsula)
	capsula = Sprite2D.new()
	capsula.texture = load("res://assets/nave/capsula.png" if con_paracaidas else "res://assets/nave/capsula_flotando.png")
	grupo_capsula.add_child(capsula)
	if con_paracaidas:
		paracaidas = Sprite2D.new()
		paracaidas.texture = load("res://assets/nave/paracaidas.png")
		paracaidas.position = Vector2(0, -41)
		grupo_capsula.add_child(paracaidas)
		grupo_capsula.position = Vector2(size.x * _x_capsula, -260.0)
	else:
		_amerizo = true

	# Franja de agua delante de la base de la cápsula (para que se vea "metida" en el mar)
	agua = ColorRect.new()
	agua.color = Color(0.10, 0.30, 0.58, 0.62) if con_paracaidas else Color(0.16, 0.22, 0.34, 0.66)
	agua.mouse_filter = Control.MOUSE_FILTER_IGNORE
	agua.size = Vector2(300, 46)
	agua.visible = not con_paracaidas
	add_child(agua)

func _escena_espacio() -> void:
	var fondo = FondoEspacio.new()
	fondo.velocidad = Vector2(3.0, 1.0)
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.colocar("tierra", Vector2(0.86, 0.20), 1.0)
	nave = Sprite2D.new()
	nave.texture = load("res://assets/nave/orion.png")
	nave.scale = Vector2(4, 4)
	nave.modulate = Color(0.42, 0.46, 0.58)      # luces apagadas
	add_child(nave)

	linea_vida = Line2D.new()
	linea_vida.width = 4.0
	linea_vida.default_color = Estilo.C_ROJO
	linea_vida.antialiased = false
	add_child(linea_vida)
	etq_senal = Estilo.con_borde(Estilo.nuevo_texto("TELEMETRÍA ORIÓN", 16, Estilo.C_VERDE, false))
	add_child(etq_senal)

func _process(delta: float) -> void:
	_t += delta
	if tipo == "malo":
		_animar_espacio()
	else:
		_animar_mar()

func _animar_mar() -> void:
	var linea_agua: float = size.y * 0.735
	var x: float = size.x * _x_capsula
	if not _amerizo:
		# Descenso con paracaídas (5 segundos) y balanceo suave
		var f: float = clampf(_t / 5.0, 0.0, 1.0)
		var suave: float = 1.0 - pow(1.0 - f, 2.0)
		grupo_capsula.position = Vector2(x + sin(_t * 1.3) * 14.0, lerpf(-260.0, linea_agua - 60.0, suave))
		grupo_capsula.rotation = sin(_t * 1.3) * 0.06
		if f >= 1.0:
			_amerizo = true
			_t = 0.0
			capsula.texture = load("res://assets/nave/capsula_flotando.png")
			agua.visible = true
			Sonido.efecto("estatica", -4.0)
			var tw: Tween = create_tween().set_parallel(true)
			tw.tween_property(paracaidas, "modulate:a", 0.0, 1.6)
			tw.tween_property(paracaidas, "position", Vector2(26, -30), 1.6)
			tw.tween_property(paracaidas, "rotation", 0.5, 1.6)
		return
	# Flotando: sube y baja con las olas
	var inclinacion: float = 0.05 if tipo == "bueno" else 0.11
	grupo_capsula.position = Vector2(x, linea_agua - 60.0 + sin(_t * 1.6) * 6.0)
	grupo_capsula.rotation = sin(_t * 1.1) * inclinacion + (0.0 if tipo == "bueno" else 0.08)
	agua.position = Vector2(x - 150.0, linea_agua + 6.0 + sin(_t * 1.6 + 0.8) * 3.0)

func _animar_espacio() -> void:
	nave.position = Vector2(size.x * 0.64 + sin(_t * 0.13) * 60.0, size.y * 0.42 + cos(_t * 0.17) * 30.0)
	nave.rotation = _t * 0.07
	# Monitor cardiaco: tres pulsos y después la línea plana
	var y0: float = size.y * 0.86
	var x_ini: float = size.x * 0.05
	var ancho: float = size.x * 0.90
	var cabeza: float = minf(_t / 6.0, 1.0) * ancho
	var puntos = PackedVector2Array()
	var x: float = 0.0
	while x <= cabeza:
		var tau: float = x / ancho * 6.0
		var y: float = 0.0
		for latido in [0.25, 1.15, 2.05]:
			var d: float = tau - latido
			if absf(d) < 0.12:
				y = -70.0 * (1.0 - absf(d) / 0.12) if d < 0.0 else 34.0 * (1.0 - absf(d) / 0.12)
		puntos.append(Vector2(x_ini + x, y0 + y))
		x += 6.0
	linea_vida.points = puntos
	var perdida: bool = _t > 2.9
	linea_vida.default_color = Estilo.C_ROJO if perdida else Estilo.C_VERDE
	etq_senal.position = Vector2(x_ini, y0 - 130.0)
	if perdida:
		etq_senal.text = "SEÑAL PERDIDA"
		etq_senal.add_theme_color_override("font_color", Estilo.C_ROJO)
		etq_senal.modulate.a = 1.0 if fmod(_t, 1.0) < 0.6 else 0.2

# ---------------------------------------------------------------
# Título y narrativa
# ---------------------------------------------------------------
func _construir_titulo() -> void:
	var margen = MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 70)
	margen.add_theme_constant_override("margin_top", 60)
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margen)
	bloque_titulo = VBoxContainer.new()
	bloque_titulo.add_theme_constant_override("separation", 10)
	bloque_titulo.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bloque_titulo.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bloque_titulo.custom_minimum_size = Vector2(820, 0)
	bloque_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(bloque_titulo)
	bloque_titulo.add_child(Estilo.con_borde(Estilo.nuevo_texto(String(SUBTITULO[tipo]), 24, color)))
	bloque_titulo.add_child(Estilo.con_borde(Estilo.nuevo_texto(String(TITULO[tipo]), 80, Color(1, 1, 1)), 12))
	bloque_titulo.add_child(Estilo.con_borde(Estilo.nuevo_texto(String(NARRATIVA[tipo]), 24, Estilo.C_TEXTO), 8))
	var espacio = Control.new()
	espacio.custom_minimum_size = Vector2(0, 10)
	bloque_titulo.add_child(espacio)
	boton_informe = Estilo.nuevo_boton("VER EL INFORME DE LA MISIÓN", 24, 520, 60)
	boton_informe.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	boton_informe.pressed.connect(_abrir_informe)
	bloque_titulo.add_child(boton_informe)
	bloque_titulo.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(bloque_titulo, "modulate:a", 1.0, 1.0)
	boton_informe.grab_focus.call_deferred()

# ---------------------------------------------------------------
# Informe de la misión
# ---------------------------------------------------------------
# Las mismas razones que explicaba la versión de texto (Mission.gd)
func _motivos() -> Array:
	var m: Array = []
	var vitales: Array = ["agua", "comida", "oxigeno", "electricidad", "combustible"]
	if tipo == "malo":
		if GameManager.forzar_final != "":
			m.append("La acumulación de CO2 dejó inconsciente a la tripulación antes del amerizaje.")
		if GameManager.vivos().is_empty():
			m.append("Todos los tripulantes murieron antes del amerizaje.")
		for b in ["agua", "oxigeno", "electricidad", "combustible"]:
			if float(GameManager.nave[b]) <= 0.0:
				m.append(Idioma.t("%s llegó a 0 %%.") % GameManager.ETIQUETAS[b])
		if GameManager.integridad <= GameManager.INTEGRIDAD_REENTRADA:
			m.append(Idioma.t("El escudo térmico no resistió la reentrada (integridad %d %%).") % roundi(GameManager.integridad))
	elif tipo == "intermedio":
		if GameManager.mision_abortada:
			m.append("Se soltó la carga científica en el Día 10.")
		var muertos: int = GameManager.TRIPULANTES.size() - GameManager.vivos().size()
		if muertos > 0:
			m.append(Idioma.t("Murieron %d tripulante(s).") % muertos)
		if not GameManager.mision_abortada and GameManager.ciencia < GameManager.CIENCIA_FINAL_BUENO:
			m.append(Idioma.t("El progreso científico fue de %d %% (el final bueno exige %d %%).") % [roundi(GameManager.ciencia), int(GameManager.CIENCIA_FINAL_BUENO)])
		for b in vitales:
			if float(GameManager.nave[b]) <= GameManager.UMBRAL_FINAL_BUENO:
				m.append(Idioma.t("%s terminó en %d %% (el final bueno exige más de %d %%).") % [GameManager.ETIQUETAS[b], roundi(GameManager.nave[b]), int(GameManager.UMBRAL_FINAL_BUENO)])
	else:
		m.append(Idioma.t("Los cuatro astronautas sobreviven, todas las reservas superan %d %% y la ciencia llegó a %d %%.") % [int(GameManager.UMBRAL_FINAL_BUENO), roundi(GameManager.ciencia)])
	return m

func _construir_informe() -> void:
	capa_informe = Control.new()
	capa_informe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa_informe.visible = false
	add_child(capa_informe)
	var velo = ColorRect.new()
	velo.color = Color(0, 0, 0, 0.55)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa_informe.add_child(velo)
	var centro = CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa_informe.add_child(centro)
	var panel: PanelContainer = Estilo.nuevo_panel(Color(0.03, 0.05, 0.11, 0.96), color, 20)
	panel.custom_minimum_size = Vector2(1240, 0)
	centro.add_child(panel)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	var cab = HBoxContainer.new()
	cab.add_theme_constant_override("separation", 14)
	col.add_child(cab)
	cab.add_child(Estilo.nuevo_icono("resultado_" + tipo, 64))
	var vt = VBoxContainer.new()
	vt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vt.add_theme_constant_override("separation", 0)
	cab.add_child(vt)
	vt.add_child(Estilo.nuevo_texto("INFORME DE LA MISIÓN MYG-351", 16, Estilo.C_TEXTO_SUAVE))
	vt.add_child(Estilo.nuevo_texto("%s: %s" % [SUBTITULO[tipo], TITULO[tipo]], 32, color))
	col.add_child(HSeparator.new())

	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 24)
	col.add_child(fila)

	# --- Columna izquierda: por qué, tripulación y datos ---
	var izq = VBoxContainer.new()
	izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	izq.add_theme_constant_override("separation", 6)
	fila.add_child(izq)
	izq.add_child(Estilo.nuevo_texto("POR QUÉ ESTE FINAL", 16, Estilo.C_CIAN))
	for motivo in _motivos():
		izq.add_child(Estilo.nuevo_texto("- " + String(motivo), 16, Estilo.C_TEXTO))
	izq.add_child(Estilo.nuevo_texto("TRIPULACIÓN", 16, Estilo.C_CIAN))
	var gente = HBoxContainer.new()
	gente.add_theme_constant_override("separation", 10)
	izq.add_child(gente)
	for id in GameManager.TRIPULANTES:
		var t: Dictionary = GameManager.tripulantes[id]
		var salud: float = float(t["salud"])
		var v = VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gente.add_child(v)
		v.add_child(Estilo.nuevo_retrato(String(id), Estilo.expresion(salud, float(t["estres"])), 2))
		var n: Label = Estilo.nuevo_texto(String(GameManager.NOMBRES_TRIPULANTE[id]), 16, Estilo.ACENTO[id])
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(n)
		var estado: String = Idioma.t("Salud %d %%") % roundi(salud)
		var c_estado: Color = Estilo.color_nivel(salud)
		if salud <= 0.0:
			estado = "No sobrevivió"
			c_estado = Color(0.7, 0.7, 0.78)
		var e: Label = Estilo.nuevo_texto(estado, 16, c_estado)
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(e)
	izq.add_child(Estilo.nuevo_texto("DATOS DE LA MISIÓN", 16, Estilo.C_CIAN))
	izq.add_child(Estilo.nuevo_texto(Idioma.t("%s  ·  Día %d de %d  ·  Decisiones buenas: %d de %d  ·  Ciencia: %d %%") % [
		GameManager.plan_nombre, GameManager.dia_actual, GameManager.DIAS_TOTALES,
		GameManager.decisiones_buenas, GameManager.decisiones_totales, roundi(GameManager.ciencia)], 16, Estilo.C_TEXTO))

	# --- Columna derecha: puntuación y memo ---
	var der = VBoxContainer.new()
	der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	der.add_theme_constant_override("separation", 6)
	fila.add_child(der)
	der.add_child(Estilo.nuevo_texto("PUNTUACIÓN", 16, Estilo.C_CIAN))
	var pt: Dictionary = GameManager.puntaje()
	for p in PUNTOS:
		var linea = HBoxContainer.new()
		linea.add_theme_constant_override("separation", 8)
		der.add_child(linea)
		linea.add_child(Estilo.nuevo_icono(String(p[3]), 24))
		var nombre: Label = Estilo.nuevo_texto(String(p[1]), 16, Estilo.C_TEXTO, false)
		nombre.custom_minimum_size = Vector2(200, 0)
		linea.add_child(nombre)
		var barra: ProgressBar = Estilo.nueva_barra(color, 14)
		barra.max_value = float(p[2])
		barra.value = float(pt[p[0]])
		linea.add_child(barra)
		var valor: Label = Estilo.nuevo_texto("%d / %d" % [roundi(float(pt[p[0]])), int(p[2])], 16, Estilo.C_TEXTO_SUAVE, false)
		valor.custom_minimum_size = Vector2(96, 0)
		valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		linea.add_child(valor)
	etq_total = Estilo.nuevo_texto("TOTAL: 0 / 1000", 32, Estilo.C_AMARILLO, false)
	etq_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	der.add_child(etq_total)

	var memo: Dictionary = Memos.para_final(tipo)
	var caja: PanelContainer = Estilo.nuevo_panel(Color(0.05, 0.12, 0.10, 0.95), Estilo.C_VERDE, 10)
	der.add_child(caja)
	var vm = VBoxContainer.new()
	vm.add_theme_constant_override("separation", 4)
	caja.add_child(vm)
	vm.add_child(Estilo.nuevo_texto(Idioma.t("MEMO NASA: ") + String(memo["titulo"]), 16, Estilo.C_VERDE))
	vm.add_child(Estilo.nuevo_texto(String(memo["texto"]), 16, Estilo.C_TEXTO))
	var enlace: Button = Estilo.nuevo_boton(Idioma.t("Abrir: ") + String(memo["fuente"]), 16, 0, 36)
	Estilo.estilo_holo(enlace, Estilo.C_VERDE)
	enlace.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	enlace.focus_mode = Control.FOCUS_NONE
	enlace.tooltip_text = String(memo["url"])
	enlace.pressed.connect(OS.shell_open.bind(String(memo["url"])))
	vm.add_child(enlace)

	# --- Botones ---
	col.add_child(HSeparator.new())
	var botones = HBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	botones.add_theme_constant_override("separation", 16)
	col.add_child(botones)
	var otra: Button = Estilo.nuevo_boton("JUGAR DE NUEVO", 24, 340, 56)
	otra.name = "BotonOtra"
	otra.pressed.connect(_jugar_de_nuevo)
	botones.add_child(otra)
	var ver: Button = Estilo.nuevo_boton("VER LA ESCENA", 24, 300, 56)
	ver.pressed.connect(func():
		capa_informe.visible = false
		bloque_titulo.visible = true
		boton_informe.grab_focus())
	botones.add_child(ver)
	var menu: Button = Estilo.nuevo_boton("MENÚ PRINCIPAL", 24, 340, 56)
	menu.pressed.connect(_ir_al_menu)
	botones.add_child(menu)
	panel.tooltip_text = Idioma.t("Semilla de esta partida: %d (sirve para repetirla y depurar errores)") % GameManager.semilla

func _abrir_informe() -> void:
	bloque_titulo.visible = false
	capa_informe.visible = true
	capa_informe.modulate.a = 0.0
	var total: float = float(GameManager.puntaje()["total"])
	var tw: Tween = create_tween()
	tw.tween_property(capa_informe, "modulate:a", 1.0, 0.3)
	tw.tween_method(func(v: float): etq_total.text = Idioma.t("TOTAL: %d / 1000") % roundi(v), 0.0, total, 1.4)
	var otra: Button = capa_informe.find_child("BotonOtra", true, false)
	if otra != null:
		otra.grab_focus.call_deferred()

func _jugar_de_nuevo() -> void:
	GameManager.nueva_partida()
	Estilo.cambiar_escena(self, "res://scenes/shop.tscn")

func _ir_al_menu() -> void:
	GameManager.nueva_partida()
	Estilo.cambiar_escena(self, "res://scenes/main_menu.tscn")
