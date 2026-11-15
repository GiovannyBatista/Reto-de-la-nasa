extends Control
# Fase 0: preparación en Cabo Cañaveral (estilo cabina pixel-art).
# De los 10.000 CM, 4.000 son suministros obligatorios y 6.000 se reparten entre Paquete A, B o personalizado.
# FONDO OPCIONAL: si existe res://assets/fondo_cabina.png se usa como fondo; si no, se dibuja un cielo con estrellas.

const C_PANEL: Color = Color(0.08, 0.11, 0.16, 0.92)
const C_PANEL_CLARO: Color = Color(0.12, 0.17, 0.24, 0.95)
const C_BORDE: Color = Color(0.36, 0.46, 0.58)
const C_VERDE: Color = Color(0.35, 0.85, 0.45)
const C_AMARILLO: Color = Color(0.95, 0.80, 0.25)
const C_TEXTO_SUAVE: Color = Color(0.72, 0.78, 0.85)
const COLOR_TEXTO_BOTON: Color = Color(0.08, 0.10, 0.16)   # texto de los botones con imagen (oscuro para botones claros)
const ICONOS: Dictionary = {"soporte": "💧", "celdas": "⚡", "filtros": "🌀", "instrumentos": "🔬"}

# --- Assets que eliges en el Inspector (selecciona el nodo raíz de shop.tscn y arrastra las imágenes) ---
@export var marco_icono: Texture2D        # marco de la ranura de cada icono
@export var icono_soporte: Texture2D
@export var icono_celdas: Texture2D
@export var icono_filtros: Texture2D
@export var icono_instrumentos: Texture2D
const TAM_RANURA: int = 52       # tamaño del cuadro del icono (px)
const TAM_ICONO: int = 32        # tamaño del icono dentro del cuadro (px)
const BORDE_MARCO: int = 4       # píxeles de borde del marco que no se estiran

var niveles: Dictionary = {}
var etiquetas_nivel: Dictionary = {}
var barras_nivel: Dictionary = {}
var etiqueta_presupuesto: Label
var etiqueta_mensaje: Label
var etiquetas_plan: Array = []
var etiqueta_nombre_plan: Label

const RUTA_FUENTE: String = "res://assets/Thin_Sans.ttf"

# Fuente pixel-art: se usa si el archivo existe; los acentos, la ñ y los símbolos que la fuente no tiene salen con una fuente del sistema.
func _aplicar_fuente() -> void:
	if not ResourceLoader.exists(RUTA_FUENTE):
		return
	var f: FontFile = load(RUTA_FUENTE)
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE          # sin suavizado: píxeles duros
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.fallbacks = [SystemFont.new()]
	var t = Theme.new()
	t.default_font = f
	t.default_font_size = 16   # IMPORTANTE: solo múltiplos de 8 (16, 24, 32); otros tamaños se ven borrosos
	theme = t
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_aplicar_fuente()
	for c in GameManager.controles:
		niveles[c["id"]] = 0
	_fondo()

	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var margen = MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for lado in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 40)
	margen.add_theme_constant_override("margin_top", 16)
	margen.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(margen)

	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margen.add_child(col)

	_construir_cabecera(col)
	_construir_presupuesto(col)
	_construir_paquetes(col)
	_construir_personalizada(col)
	_construir_resumen(col)

	etiqueta_mensaje = _texto(col, "", C_AMARILLO)
	etiqueta_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var iniciar = Button.new()
	iniciar.text = "INICIAR MISIÓN"
	iniciar.custom_minimum_size = Vector2(320, 54)
	iniciar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	iniciar.add_theme_font_size_override("font_size", 24)
	_estilo_boton(iniciar, Color(0.15, 0.5, 0.25), C_VERDE)
	iniciar.pressed.connect(_on_iniciar)
	col.add_child(iniciar)

	actualizar()

# ---------------------------------------------------------------
# Utilidades de estilo
# ---------------------------------------------------------------
func _caja(fondo: Color, borde: Color, grosor: int = 2, radio: int = 4) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = fondo
	s.border_color = borde
	s.set_border_width_all(grosor)
	s.set_corner_radius_all(radio)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

# Estilo con imagen pixel-art (se estira por el centro y mantiene las esquinas). Devuelve null si la imagen no existe.
const BORDE_9: int = 8   # píxeles de la imagen que son "esquina/borde" y no se estiran

func _caja_tex(ruta: String, tinte: Color = Color(1, 1, 1)) -> StyleBoxTexture:
	if not ResourceLoader.exists(ruta):
		return null
	var s = StyleBoxTexture.new()
	s.texture = load(ruta)
	s.texture_margin_left = BORDE_9
	s.texture_margin_right = BORDE_9
	s.texture_margin_top = BORDE_9
	s.texture_margin_bottom = BORDE_9
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	s.modulate_color = tinte
	return s

# Barras con imagen: assets/ui/barra_fondo.png (vacía) y assets/ui/barra_relleno.png (parte llena).
const BORDE_BARRA: int = 2   # píxeles de borde de la imagen de la barra que no se estiran

func _caja_barra(ruta: String) -> StyleBoxTexture:
	if not ResourceLoader.exists(ruta):
		return null
	var s = StyleBoxTexture.new()
	s.texture = load(ruta)
	s.texture_margin_left = BORDE_BARRA
	s.texture_margin_right = BORDE_BARRA
	s.texture_margin_top = BORDE_BARRA
	s.texture_margin_bottom = BORDE_BARRA
	return s

func _estilo_barra(b: ProgressBar) -> void:
	var fondo: StyleBoxTexture = _caja_barra("res://assets/ui/barra_fondo.png")
	var relleno: StyleBoxTexture = _caja_barra("res://assets/ui/barra_relleno.png")
	if fondo != null:
		b.add_theme_stylebox_override("background", fondo)
	if relleno != null:
		b.add_theme_stylebox_override("fill", relleno)

# Textura del icono: primero la del Inspector; si no hay, assets/ui/icono_<id>.png; si no, null (usa emoji).
func _textura_icono(id: String) -> Texture2D:
	var t: Texture2D = null
	match id:
		"soporte": t = icono_soporte
		"celdas": t = icono_celdas
		"filtros": t = icono_filtros
		"instrumentos": t = icono_instrumentos
	if t == null:
		var ruta: String = "res://assets/ui/icono_%s.png" % id
		if ResourceLoader.exists(ruta):
			t = load(ruta)
	return t

# Ranura cuadrada: marco (tu imagen) + icono centrado adentro.
func _ranura_icono(id: String) -> PanelContainer:
	var p = PanelContainer.new()
	p.custom_minimum_size = Vector2(TAM_RANURA, TAM_RANURA)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var marco: Texture2D = marco_icono
	if marco == null and ResourceLoader.exists("res://assets/ui/marco_icono.png"):
		marco = load("res://assets/ui/marco_icono.png")
	if marco != null:
		var s = StyleBoxTexture.new()
		s.texture = marco
		s.texture_margin_left = BORDE_MARCO
		s.texture_margin_right = BORDE_MARCO
		s.texture_margin_top = BORDE_MARCO
		s.texture_margin_bottom = BORDE_MARCO
		s.content_margin_left = 4
		s.content_margin_right = 4
		s.content_margin_top = 4
		s.content_margin_bottom = 4
		p.add_theme_stylebox_override("panel", s)
	else:
		var f: StyleBoxFlat = _caja(Color(0.04, 0.06, 0.1, 0.9), C_BORDE, 2, 2)
		f.content_margin_left = 4
		f.content_margin_right = 4
		f.content_margin_top = 4
		f.content_margin_bottom = 4
		p.add_theme_stylebox_override("panel", f)
	var tex: Texture2D = _textura_icono(id)
	if tex != null:
		var icono = TextureRect.new()
		icono.texture = tex
		icono.custom_minimum_size = Vector2(TAM_ICONO, TAM_ICONO)
		icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icono.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icono.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		p.add_child(icono)
	else:
		var e = Label.new()
		e.text = String(ICONOS.get(id, "?"))
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		e.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p.add_child(e)
	return p

func _panel(padre: Control, fondo: Color = C_PANEL, borde: Color = C_BORDE) -> VBoxContainer:
	var p = PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var estilo: StyleBox = _caja_tex("res://assets/ui/panel.png", Color(1, 1, 1) if fondo == C_PANEL else Color(1.2, 1.2, 1.2))
	if estilo == null:
		estilo = _caja(fondo, borde)
	p.add_theme_stylebox_override("panel", estilo)
	padre.add_child(p)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	return v

func _texto(padre: Control, texto: String, color: Color = Color(1, 1, 1)) -> Label:
	var l = Label.new()
	l.text = texto
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_color_override("font_color", color)
	padre.add_child(l)
	return l

func _estilo_boton(b: Button, color: Color, borde: Color) -> void:
	var ruta: String = "res://assets/ui/boton_iniciar.png" if b.text == "INICIAR MISIÓN" else "res://assets/ui/boton.png"
	if not ResourceLoader.exists(ruta):
		ruta = "res://assets/ui/boton.png"
	var normal: StyleBoxTexture = _caja_tex(ruta)
	if normal != null:
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", _caja_tex(ruta, Color(1.25, 1.25, 1.25)))
		b.add_theme_stylebox_override("pressed", _caja_tex(ruta, Color(0.7, 0.7, 0.7)))
		b.add_theme_stylebox_override("disabled", _caja_tex(ruta, Color(0.4, 0.4, 0.4)))
		# Color del texto sobre la imagen. Si tu botón es CLARO usa un color oscuro; si es OSCURO, cambia esto a Color(1, 1, 1).
		var texto_boton: Color = COLOR_TEXTO_BOTON
		for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(estado, texto_boton)
		b.add_theme_color_override("font_disabled_color", texto_boton.lightened(0.4))
		return
	b.add_theme_stylebox_override("normal", _caja(color, borde))
	b.add_theme_stylebox_override("hover", _caja(color.lightened(0.2), borde))
	b.add_theme_stylebox_override("pressed", _caja(color.darkened(0.2), borde))
	b.add_theme_stylebox_override("disabled", _caja(color.darkened(0.5), C_BORDE))

func _fondo() -> void:
	var base = ColorRect.new()
	base.color = Color(0.02, 0.03, 0.08)
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	var ruta: String = "res://assets/fondo_cabina.png"
	if ResourceLoader.exists(ruta):
		var tex = TextureRect.new()
		tex.texture = load(ruta)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(tex)
		return
	var tam: Vector2 = get_viewport_rect().size
	var rng = RandomNumberGenerator.new()
	rng.seed = 351
	for i in 90:
		var e = ColorRect.new()
		var lado: float = rng.randf_range(2.0, 4.0)
		e.size = Vector2(lado, lado)
		e.position = Vector2(rng.randf() * tam.x, rng.randf() * tam.y)
		e.color = Color(1, 1, 1, rng.randf_range(0.3, 0.9))
		add_child(e)
	var tierra = ColorRect.new()   # "Tierra" simple en la esquina
	tierra.size = Vector2(150, 150)
	tierra.position = Vector2(tam.x - 190, 60)
	tierra.color = Color(0.2, 0.45, 0.8)
	add_child(tierra)

# ---------------------------------------------------------------
# Bloques de la pantalla
# ---------------------------------------------------------------
func _construir_cabecera(col: VBoxContainer) -> void:
	var v = _panel(col)
	var t1 = _texto(v, "FASE 0: PREPARACIÓN EN CABO CAÑAVERAL")
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_font_size_override("font_size", 24)
	_texto(v, "Tres días antes del lanzamiento, los cuatro astronautas se reúnen frente a la consola de carga de la Orión. No habrá rescate inmediato: la Tierra está a 384.400 km. La misión dura 14 días y cada decisión de hoy te cobrará más adelante.", C_TEXTO_SUAVE)
	_texto(v, "Memo NASA: en misiones tripuladas fuera de la órbita baja, el soporte vital (ECLSS) debe tener márgenes de redundancia antes de asignar masa a cargas útiles secundarias.", C_VERDE)

func _construir_presupuesto(col: VBoxContainer) -> void:
	var v = _panel(col, C_PANEL_CLARO)
	var t = _texto(v, "PRESUPUESTO MISIONAL")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_presupuesto = _texto(v, "", C_AMARILLO)
	etiqueta_presupuesto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _construir_paquetes(col: VBoxContainer) -> void:
	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	col.add_child(fila)
	for clave in GameManager.paquetes:
		var v = _panel(fila)
		var partes: PackedStringArray = String(GameManager.paquetes[clave]["nombre"]).split(": ", true, 1)
		var b = Button.new()
		b.text = String(partes[0]).to_upper()      # botón corto: "PAQUETE A"
		_estilo_boton(b, Color(0.14, 0.22, 0.34), C_BORDE)
		b.pressed.connect(_on_paquete.bind(clave))
		v.add_child(b)
		if partes.size() > 1:
			_texto(v, String(partes[1]), C_AMARILLO)
		_texto(v, String(GameManager.paquetes[clave]["descripcion"]), C_TEXTO_SUAVE)
	var v3 = _panel(fila)
	var b3 = Button.new()
	b3.text = "PERSONALIZADA"
	_estilo_boton(b3, Color(0.14, 0.22, 0.34), C_BORDE)
	b3.pressed.connect(_on_reiniciar)
	v3.add_child(b3)
	_texto(v3, "Empezar de cero", C_AMARILLO)
	_texto(v3, "Reparte tú los 6.000 CM con los botones - y + de abajo.", C_TEXTO_SUAVE)

func _construir_personalizada(col: VBoxContainer) -> void:
	var v = _panel(col)
	var t = _texto(v, "CONFIGURACIÓN PERSONALIZADA")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	v.add_child(fila)
	for c in GameManager.controles:
		var id: String = c["id"]
		var tarjeta = _panel(fila, C_PANEL_CLARO)
		tarjeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cabeza = HBoxContainer.new()
		cabeza.add_theme_constant_override("separation", 8)
		tarjeta.add_child(cabeza)
		cabeza.add_child(_ranura_icono(id))
		var nombre_c = _texto(cabeza, String(c["nombre"]))
		nombre_c.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var linea = HBoxContainer.new()
		tarjeta.add_child(linea)
		var nivel = Label.new()
		nivel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		linea.add_child(nivel)
		var menos = Button.new()
		menos.text = " - "
		_estilo_boton(menos, Color(0.2, 0.28, 0.4), C_BORDE)
		menos.pressed.connect(_on_cambiar.bind(id, -1))
		linea.add_child(menos)
		var mas = Button.new()
		mas.text = " + "
		_estilo_boton(mas, Color(0.2, 0.28, 0.4), C_BORDE)
		mas.pressed.connect(_on_cambiar.bind(id, 1))
		linea.add_child(mas)
		_texto(tarjeta, "Costo: %d CM/nivel" % int(c["costo"]), C_AMARILLO)
		_texto(tarjeta, String(c["efecto"]), C_TEXTO_SUAVE)
		var barra = ProgressBar.new()
		barra.max_value = float(c["max"])
		barra.show_percentage = false
		barra.custom_minimum_size = Vector2(0, 12)
		_estilo_barra(barra)
		tarjeta.add_child(barra)
		etiquetas_nivel[id] = nivel
		barras_nivel[id] = barra

func _construir_resumen(col: VBoxContainer) -> void:
	var v = _panel(col)
	var fila = HBoxContainer.new()
	v.add_child(fila)
	var izq = VBoxContainer.new()
	izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(izq)
	etiqueta_nombre_plan = _texto(izq, "")
	var rejilla = GridContainer.new()
	rejilla.columns = 2
	rejilla.add_theme_constant_override("h_separation", 24)
	izq.add_child(rejilla)
	for i in 6:
		var l = _texto(rejilla, "", C_VERDE)
		etiquetas_plan.append(l)
	var der = VBoxContainer.new()
	fila.add_child(der)
	var sin_tiempo = CheckButton.new()
	sin_tiempo.text = "MODO APRENDIZAJE"
	sin_tiempo.tooltip_text = "Sin temporizador en las decisiones"
	sin_tiempo.button_pressed = GameManager.modo_sin_temporizador
	sin_tiempo.toggled.connect(_on_modo_sin_tiempo)
	# Interruptor con tus imágenes: assets/ui/switch_on.png (activado) y assets/ui/switch_off.png (apagado)
	for par in [["checked", "switch_on"], ["checked_disabled", "switch_on"], ["unchecked", "switch_off"], ["unchecked_disabled", "switch_off"]]:
		var ruta_sw: String = "res://assets/ui/%s.png" % par[1]
		if ResourceLoader.exists(ruta_sw):
			sin_tiempo.add_theme_icon_override(par[0], load(ruta_sw))
	der.add_child(sin_tiempo)
	_texto(der, "Sin temporizador\nen las decisiones", C_TEXTO_SUAVE)

# ---------------------------------------------------------------
# Lógica
# ---------------------------------------------------------------
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
	etiqueta_presupuesto.text = "PRESUPUESTO TOTAL: %d CM   |   SUMINISTROS OBLIGATORIOS: %d CM   |   GASTADO: %d CM   |   DISPONIBLE: %d CM" % [
		GameManager.PRESUPUESTO_TOTAL, GameManager.COSTO_OBLIGATORIO, gastado, GameManager.PRESUPUESTO_LIBRE - gastado]
	for c in GameManager.controles:
		var id: String = c["id"]
		etiquetas_nivel[id].text = "NIVEL: %d / %d" % [niveles[id], c["max"]]
		barras_nivel[id].value = float(niveles[id])
	var p: Dictionary = GameManager.parametros_plan(niveles)
	etiqueta_nombre_plan.text = "PLAN ACTUAL: " + GameManager.nombre_plan(niveles)
	var datos: Array = [
		"Agua, comida y O2: %.1f %%/día (NASA: 6,5)" % p["consumo_basico"],
		"Electricidad: %.1f %%/día" % p["consumo_elec"],
		"Filtros de CO2: %d cartuchos" % p["filtros"],
		"Estrés base: +%.1f / día" % p["estres_base"],
		"Ciencia máx: %d %% (final bueno: 70 %%)" % roundi(p["ciencia_max"]),
		"Costo maniobras: x%.2f" % p["mult_combustible"],
	]
	for i in datos.size():
		etiquetas_plan[i].text = "✔ " + String(datos[i])

func _on_iniciar():
	if _gastado() > GameManager.PRESUPUESTO_LIBRE:
		etiqueta_mensaje.text = "Te pasaste del presupuesto."
		return
	GameManager.nueva_partida()
	GameManager.aplicar_plan(niveles, GameManager.nombre_plan(niveles))
	get_tree().change_scene_to_file("res://scenes/mission.tscn")
