extends Control
# Menú principal de MYG-351: Last Signal.
# Fondo espacial animado + título + botones. Desde aquí se va al prólogo (intro.tscn).

const Estilo = preload("res://srcipts/Estilo.gd")
const FondoEspacio = preload("res://srcipts/FondoEspacio.gd")
const Memos = preload("res://srcipts/Memos.gd")

var fondo: Control
var nave: Sprite2D
var onda: Line2D
var capa_ventana: Control
var boton_sonido: TextureButton
var _t: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Estilo.tema()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# --- Fondo: estrellas, Luna grande, Tierra lejana y la Orión cruzando ---
	fondo = FondoEspacio.new()
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.colocar("luna", Vector2(0.80, 0.60), 6.0)
	fondo.colocar("tierra", Vector2(0.58, 0.16), 1.0)

	nave = Sprite2D.new()
	nave.texture = load("res://assets/nave/orion.png")
	nave.scale = Vector2(3, 3)
	nave.position = Vector2(-200, 620)
	add_child(nave)

	# --- Título ---
	var margen = MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 110)
	margen.add_theme_constant_override("margin_top", 48)
	margen.add_theme_constant_override("margin_bottom", 40)
	margen.add_theme_constant_override("margin_right", 60)
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margen)

	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(col)

	col.add_child(Estilo.con_borde(Estilo.nuevo_texto("MISIÓN ARTEMIS-MYG  ·  AÑO 2032", 16, Estilo.C_CIAN, false)))
	col.add_child(Estilo.con_borde(Estilo.nuevo_texto("MYG-351", 48, Estilo.C_AMARILLO, false), 8))
	var titulo: Label = Estilo.con_borde(Estilo.nuevo_texto("LAST SIGNAL", 96, Color(1, 1, 1), false), 12)
	titulo.add_theme_color_override("font_shadow_color", Color(0.2, 0.6, 1.0, 0.8))
	titulo.add_theme_constant_override("shadow_offset_x", 6)
	titulo.add_theme_constant_override("shadow_offset_y", 6)
	col.add_child(titulo)

	# Onda de radio que se va apagando: la "última señal"
	var caja_onda = Control.new()
	caja_onda.custom_minimum_size = Vector2(620, 56)
	caja_onda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(caja_onda)
	onda = Line2D.new()
	onda.width = 4.0
	onda.default_color = Estilo.C_CIAN
	onda.antialiased = false
	caja_onda.add_child(onda)

	col.add_child(Estilo.con_borde(Estilo.nuevo_texto("14 días. 4 astronautas. Cada decisión cuenta.", 24, Estilo.C_TEXTO, false)))

	var espacio = Control.new()
	espacio.custom_minimum_size = Vector2(0, 14)
	col.add_child(espacio)

	# --- Botones ---
	var botones = VBoxContainer.new()
	botones.add_theme_constant_override("separation", 12)
	botones.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(botones)
	var b_jugar: Button = Estilo.nuevo_boton("NUEVA MISIÓN", 32, 420, 68)
	b_jugar.pressed.connect(_on_jugar)
	botones.add_child(b_jugar)
	var b_como: Button = Estilo.nuevo_boton("CÓMO JUGAR", 24, 420, 54)
	b_como.pressed.connect(_abrir_como_jugar)
	botones.add_child(b_como)
	var b_refs: Button = Estilo.nuevo_boton("REFERENCIAS NASA", 24, 420, 54)
	b_refs.pressed.connect(_abrir_referencias)
	botones.add_child(b_refs)
	var b_salir: Button = Estilo.nuevo_boton("SALIR", 24, 420, 54)
	b_salir.pressed.connect(func(): get_tree().quit())
	botones.add_child(b_salir)
	b_jugar.grab_focus.call_deferred()
	# Los botones entran uno tras otro con un pequeño salto
	var orden: int = 0
	for boton in botones.get_children():
		Estilo.saltar(boton, 0.5 + 0.09 * float(orden), 0.8)
		orden += 1
	Estilo.saltar(titulo, 0.15, 0.9)

	# --- Pie y botón de sonido ---
	var pie: Label = Estilo.con_borde(Estilo.nuevo_texto("Reto NASA  ·  Datos de NASA Crew Systems y Habitability Functions Vol. 2  ·  Hecho con Godot", 16, Estilo.C_TEXTO_SUAVE, false))
	pie.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	pie.position = Vector2(110, -44)
	pie.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(pie)

	boton_sonido = TextureButton.new()
	boton_sonido.ignore_texture_size = true
	boton_sonido.stretch_mode = TextureButton.STRETCH_SCALE
	boton_sonido.custom_minimum_size = Vector2(48, 48)
	boton_sonido.size = Vector2(48, 48)
	boton_sonido.tooltip_text = "Activar o silenciar el sonido"
	boton_sonido.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	boton_sonido.position = Vector2(-72, 24)
	boton_sonido.pressed.connect(_on_sonido)
	add_child(boton_sonido)
	_pintar_sonido()

	# --- Selector de idioma (EN / ES), a la izquierda del botón de sonido ---
	var caja_idioma = HBoxContainer.new()
	caja_idioma.add_theme_constant_override("separation", 8)
	caja_idioma.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	caja_idioma.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	caja_idioma.position = Vector2(-136, 24)
	add_child(caja_idioma)
	for cod in ["en", "es"]:
		var bi: Button = Estilo.nuevo_boton(cod.to_upper(), 16, 56, 48)
		bi.tooltip_text = "English" if cod == "en" else "Español"
		bi.disabled = (Idioma.idioma == cod)
		bi.pressed.connect(_on_idioma.bind(cod))
		caja_idioma.add_child(bi)

	# --- Capa para las ventanas (cómo jugar / referencias) ---
	capa_ventana = Control.new()
	capa_ventana.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa_ventana.visible = false
	add_child(capa_ventana)

	Sonido.zumbido(false)
	Sonido.musica("musica_tension")
	Estilo.aparecer(self, 0.8)

func _process(delta: float) -> void:
	_t += delta
	# La nave cruza la pantalla de izquierda a derecha y vuelve a empezar
	var ancho: float = size.x + 500.0
	nave.position.x = fposmod(_t * 26.0 + 950.0, ancho) - 250.0
	nave.position.y = size.y * 0.72 + sin(_t * 0.9) * 10.0
	nave.rotation = sin(_t * 0.6) * 0.03
	# Onda: fuerte a la izquierda, plana a la derecha
	var puntos = PackedVector2Array()
	var n: int = 78
	for i in n:
		var x: float = float(i) * 8.0
		var fuerza: float = pow(1.0 - float(i) / float(n), 2.2)
		var y: float = 28.0 + sin(float(i) * 0.9 - _t * 5.0) * 22.0 * fuerza * (0.6 + 0.4 * sin(_t * 1.3 + float(i) * 0.13))
		puntos.append(Vector2(x, roundf(y / 2.0) * 2.0))
	onda.points = puntos

func _pintar_sonido() -> void:
	boton_sonido.texture_normal = Estilo.icono("sonido_off" if Sonido.silenciado else "sonido_on")

func _on_sonido() -> void:
	Sonido.alternar_silencio()
	_pintar_sonido()

func _on_idioma(cod: String) -> void:
	if Idioma.idioma == cod:
		return
	Idioma.cambiar(cod)
	get_tree().reload_current_scene()   # reconstruye el menú en el idioma nuevo

func _on_jugar() -> void:
	Estilo.cambiar_escena(self, "res://scenes/intro.tscn")

# ---------------------------------------------------------------
# Ventanas
# ---------------------------------------------------------------
func _abrir_ventana(titulo: String, ancho: int) -> VBoxContainer:
	for hijo in capa_ventana.get_children():
		hijo.queue_free()
	var velo = ColorRect.new()
	velo.color = Color(0, 0, 0, 0.65)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa_ventana.add_child(velo)
	var centro = CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa_ventana.add_child(centro)
	var panel: PanelContainer = Estilo.nuevo_panel(Color(0.03, 0.05, 0.11, 0.98), Estilo.C_CIAN, 24)
	panel.custom_minimum_size = Vector2(ancho, 0)
	centro.add_child(panel)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)
	var t: Label = Estilo.nuevo_texto(titulo, 32, Estilo.C_AMARILLO)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	var cuerpo = VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 12)
	col.add_child(cuerpo)
	var cerrar: Button = Estilo.nuevo_boton("CERRAR", 24, 240, 52)
	cerrar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cerrar.pressed.connect(func(): capa_ventana.visible = false)
	col.add_child(cerrar)
	capa_ventana.visible = true
	cerrar.grab_focus.call_deferred()
	return cuerpo

func _abrir_como_jugar() -> void:
	var cuerpo: VBoxContainer = _abrir_ventana("CÓMO JUGAR", 1180)
	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	cuerpo.add_child(fila)
	var pasos: Array = [
		["racion_completa", "1. DA LAS ÓRDENES", "Cada mañana eliges la ración de comida, los instrumentos científicos y la higiene. Gastar menos cuida los recursos, pero sube el hambre y el estrés."],
		["reloj", "2. DECIDE A TIEMPO", "Cada día hay 2 decisiones contra reloj. En las emergencias, tú mismo haces la reparación en un minijuego."],
		["alarma", "3. VIGILA LAS BARRAS", "Si el agua, el oxígeno, la electricidad o el combustible llegan a 0, la misión termina. Cuida también la salud y el estrés de los cuatro."],
		["tierra", "4. VUELVE A CASA", "Sobrevive 14 días, reúne 70 % de ciencia y trae a todos vivos para lograr el mejor final."],
	]
	for p in pasos:
		var tarjeta: PanelContainer = Estilo.nuevo_panel(Estilo.C_PANEL_CLARO, Estilo.C_BORDE, 14)
		tarjeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(tarjeta)
		var v = VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		tarjeta.add_child(v)
		var ic: TextureRect = Estilo.nuevo_icono(String(p[0]), 64)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
		var t: Label = Estilo.nuevo_texto(String(p[1]), 24, Estilo.C_CIAN)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(t)
		v.add_child(Estilo.nuevo_texto(String(p[2]), 16, Estilo.C_TEXTO))
	var nota: Label = Estilo.nuevo_texto("Consejo: en la Fase 0 puedes activar el MODO APRENDIZAJE para jugar sin temporizador.", 16, Estilo.C_VERDE)
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cuerpo.add_child(nota)

func _abrir_referencias() -> void:
	var cuerpo: VBoxContainer = _abrir_ventana("REFERENCIAS NASA", 980)
	cuerpo.add_child(Estilo.nuevo_texto("El juego usa datos reales de la NASA: 2,5 L de agua para beber y 0,4 L de higiene por astronauta al día, y 3.035 kcal diarias por persona. Pulsa una referencia para abrirla en el navegador.", 16, Estilo.C_TEXTO))
	for ref in Memos.REFERENCIAS:
		var b: Button = Estilo.nuevo_boton(String(ref["nombre"]), 16, 0, 44)
		Estilo.estilo_holo(b)
		b.icon = Estilo.icono("memo")
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.tooltip_text = String(ref["url"])
		b.pressed.connect(OS.shell_open.bind(String(ref["url"])))
		cuerpo.add_child(b)
