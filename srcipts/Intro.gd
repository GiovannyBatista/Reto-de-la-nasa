extends Control
# Prólogo: presenta la misión, la nave y la tripulación antes de la Fase 0 (la tienda).
# Son 4 páginas con dibujos; los textos salen del documento de diseño (GDD) y del Storytelling.

const Estilo = preload("res://srcipts/Estilo.gd")
const FondoEspacio = preload("res://srcipts/FondoEspacio.gd")

const TRIPULACION: Array = [
	{"id": "elena", "nombre": "Elena Marín", "edad": 42, "rol": "Comandante y Piloto",
	 "objetivo": "Que todos lleguen vivos.", "rasgo": "Toma la decisión final del grupo, incluso cuando es impopular."},
	{"id": "marcus", "nombre": "Marcus Chen", "edad": 35, "rol": "Ingeniero de Sistemas",
	 "objetivo": "Que la nave no falle.", "rasgo": "Prefiere ahorrar energía antes que cuidar el ánimo de la tripulación."},
	{"id": "sofia", "nombre": "Dra. Sofía Reyes", "edad": 38, "rol": "Médica y Bióloga",
	 "objetivo": "Salud física y mental.", "rasgo": "Defiende las raciones completas y el ejercicio, aunque gasten más recursos."},
	{"id": "leo", "nombre": "Leo Okafor", "edad": 29, "rol": "Ingeniero Mecánico",
	 "objetivo": "Ciencia y contacto con la Tierra.", "rasgo": "Quiere todos los instrumentos encendidos, cueste lo que cueste."},
]

var paginas: Array = []
var indice: int = 0
var zona: Control
var puntos: HBoxContainer
var boton_atras: Button
var boton_siguiente: Button
var nave_viaje: Sprite2D
var _t: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Estilo.tema()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var fondo = FondoEspacio.new()
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margen = MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 90)
	margen.add_theme_constant_override("margin_right", 90)
	margen.add_theme_constant_override("margin_top", 36)
	margen.add_theme_constant_override("margin_bottom", 30)
	add_child(margen)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margen.add_child(col)

	zona = Control.new()
	zona.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(zona)

	# Barra de navegación
	var barra = HBoxContainer.new()
	barra.add_theme_constant_override("separation", 16)
	col.add_child(barra)
	boton_atras = Estilo.nuevo_boton("ATRÁS", 24, 200, 56)
	boton_atras.pressed.connect(_cambiar.bind(-1))
	barra.add_child(boton_atras)
	var saltar: Button = Estilo.nuevo_boton("SALTAR", 16, 150, 56)
	Estilo.estilo_holo(saltar)
	saltar.pressed.connect(_terminar)
	barra.add_child(saltar)
	puntos = HBoxContainer.new()
	puntos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	puntos.alignment = BoxContainer.ALIGNMENT_CENTER
	puntos.add_theme_constant_override("separation", 10)
	barra.add_child(puntos)
	boton_siguiente = Estilo.nuevo_boton("SIGUIENTE", 24, 440, 56)
	boton_siguiente.pressed.connect(_cambiar.bind(1))
	barra.add_child(boton_siguiente)

	paginas = [_pagina_prologo(), _pagina_nave(), _pagina_tripulacion(), _pagina_mision()]
	for i in paginas.size():
		var p: Control = paginas[i]
		p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		p.visible = false
		zona.add_child(p)
		var punto = ColorRect.new()
		punto.custom_minimum_size = Vector2(16, 16)
		punto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		puntos.add_child(punto)
	_mostrar(0)
	Sonido.musica("musica_tension")
	Estilo.aparecer(self)

func _process(delta: float) -> void:
	_t += delta
	if nave_viaje != null and is_instance_valid(nave_viaje):
		# La nave va de la Tierra a la Luna y vuelve
		var ciclo: float = fposmod(_t / 9.0, 2.0)
		var f: float = ciclo if ciclo <= 1.0 else 2.0 - ciclo
		var ancho: float = nave_viaje.get_parent().size.x
		nave_viaje.position.x = lerpf(250.0, ancho - 250.0, f)
		nave_viaje.position.y = 96.0 + sin(_t * 2.0) * 4.0
		nave_viaje.flip_h = ciclo > 1.0

# ---------------------------------------------------------------
# Navegación
# ---------------------------------------------------------------
func _mostrar(i: int) -> void:
	indice = i
	for n in paginas.size():
		paginas[n].visible = (n == i)
		puntos.get_child(n).color = Estilo.C_AMARILLO if n == i else Color(0.3, 0.36, 0.5)
	paginas[i].modulate.a = 0.0
	create_tween().tween_property(paginas[i], "modulate:a", 1.0, 0.3)
	boton_atras.text = "MENÚ" if i == 0 else "ATRÁS"
	boton_siguiente.text = "IR A LA FASE 0: PREPARAR LA NAVE" if i == paginas.size() - 1 else "SIGUIENTE"
	boton_siguiente.add_theme_font_size_override("font_size", 16 if i == paginas.size() - 1 else 24)
	boton_siguiente.grab_focus.call_deferred()

func _cambiar(paso: int) -> void:
	var nuevo: int = indice + paso
	if nuevo < 0:
		Estilo.cambiar_escena(self, "res://scenes/main_menu.tscn")
	elif nuevo >= paginas.size():
		_terminar()
	else:
		_mostrar(nuevo)

func _terminar() -> void:
	Estilo.cambiar_escena(self, "res://scenes/shop.tscn")

# ---------------------------------------------------------------
# Piezas comunes
# ---------------------------------------------------------------
func _pagina(titulo: String, subtitulo: String) -> VBoxContainer:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	var t: Label = Estilo.con_borde(Estilo.nuevo_texto(titulo, 48, Estilo.C_AMARILLO), 8)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var s: Label = Estilo.con_borde(Estilo.nuevo_texto(subtitulo, 24, Estilo.C_CIAN))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	return v

func _dato(icono: String, titulo: String, detalle: String, tam_icono: int = 48) -> PanelContainer:
	var p: PanelContainer = Estilo.nuevo_panel(Estilo.C_PANEL, Estilo.C_BORDE, 12)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)
	h.add_child(Estilo.nuevo_icono(icono, tam_icono))
	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	h.add_child(v)
	v.add_child(Estilo.nuevo_texto(titulo, 24, Estilo.C_TEXTO))
	if detalle != "":
		v.add_child(Estilo.nuevo_texto(detalle, 16, Estilo.C_TEXTO_SUAVE))
	return p

# ---------------------------------------------------------------
# Página 1: el prólogo
# ---------------------------------------------------------------
func _pagina_prologo() -> Control:
	var v: VBoxContainer = _pagina("AÑO 2032", "La humanidad regresa a la Luna: misión Artemis-MYG")

	# Dibujo: Tierra ----- nave ----- Luna
	var dibujo = Control.new()
	dibujo.custom_minimum_size = Vector2(0, 230)
	v.add_child(dibujo)
	var linea = HBoxContainer.new()
	linea.set_anchors_and_offsets_preset(Control.PRESET_HCENTER_WIDE)
	linea.offset_left = 230
	linea.offset_right = -230
	linea.offset_top = 94
	linea.offset_bottom = 98
	linea.add_theme_constant_override("separation", 10)
	dibujo.add_child(linea)
	for i in 60:
		var punto = ColorRect.new()
		punto.color = Color(0.5, 0.66, 0.95, 0.8)
		punto.custom_minimum_size = Vector2(8, 4)
		punto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		linea.add_child(punto)
	var tierra = AnimatedSprite2D.new()
	tierra.sprite_frames = Estilo.cuadros_giro("res://assets/space/planet-terran-spin-24f.png")
	tierra.scale = Vector2(2, 2)
	tierra.position = Vector2(110, 96)
	tierra.play("default")
	dibujo.add_child(tierra)
	var luna = AnimatedSprite2D.new()
	luna.sprite_frames = Estilo.cuadros_giro("res://scenes/TileMaps/2x/planet-moon-spin-24f.png")
	luna.scale = Vector2(2, 2)
	luna.play("default")
	dibujo.add_child(luna)
	dibujo.resized.connect(func(): luna.position = Vector2(dibujo.size.x - 110, 96))
	nave_viaje = Sprite2D.new()
	nave_viaje.texture = load("res://assets/nave/orion.png")
	nave_viaje.scale = Vector2(1.5, 1.5)
	nave_viaje.position = Vector2(300, 96)
	dibujo.add_child(nave_viaje)
	var km: Label = Estilo.con_borde(Estilo.nuevo_texto("384.400 km  ·  14 días de misión", 24, Estilo.C_TEXTO))
	km.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	km.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	km.offset_top = 0
	dibujo.add_child(km)
	var e1: Label = Estilo.con_borde(Estilo.nuevo_texto("TIERRA", 16, Estilo.C_CIAN, false))
	e1.position = Vector2(74, 196)
	dibujo.add_child(e1)
	var e2: Label = Estilo.con_borde(Estilo.nuevo_texto("LUNA: Polo Sur", 16, Estilo.C_CIAN, false))
	e2.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	e2.position = Vector2(-210, 196)
	dibujo.add_child(e2)

	v.add_child(_dato("luna", "Objetivo: estudiar el hielo del Polo Sur lunar", "Catorce días para explorar, recolectar muestras científicas y regresar a salvo."))
	v.add_child(_dato("alarma", "No hay rescate inmediato", "Viajas en la Orión, una cápsula compacta. Lo que cargues antes de despegar es todo lo que tendrás."))
	v.add_child(_dato("confianza", "Tú tomas las decisiones", "Administra el agua, la comida, el oxígeno y la energía... y trae a los cuatro astronautas de vuelta."))
	return v

# ---------------------------------------------------------------
# Página 2: la nave
# ---------------------------------------------------------------
func _pagina_nave() -> Control:
	var v: VBoxContainer = _pagina("LA NAVE: ORIÓN", "Una cápsula de espacio profundo inspirada en el programa Artemis de la NASA")
	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 30)
	fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(fila)

	var izq = VBoxContainer.new()
	izq.add_theme_constant_override("separation", 10)
	izq.custom_minimum_size = Vector2(560, 0)
	fila.add_child(izq)
	var marco: PanelContainer = Estilo.nuevo_panel(Color(0.02, 0.04, 0.10, 0.75), Estilo.C_BORDE, 16)
	izq.add_child(marco)
	var img = TextureRect.new()
	img.texture = load("res://assets/nave/orion.png")
	img.custom_minimum_size = Vector2(480, 320)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	marco.add_child(img)
	var partes = HBoxContainer.new()
	partes.add_theme_constant_override("separation", 8)
	izq.add_child(partes)
	for texto in ["Motor y paneles solares", "Módulo de servicio: aire, agua, energía", "Cápsula: 4 tripulantes"]:
		var chip: PanelContainer = Estilo.nuevo_panel(Estilo.C_PANEL_CLARO, Estilo.C_BORDE, 8)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var l: Label = Estilo.nuevo_texto(texto, 16, Estilo.C_TEXTO)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.add_child(l)
		partes.add_child(chip)
	izq.add_child(_dato("integridad", "Carga útil máxima: 226,8 kg", "Cada kilo cuenta: más reservas significa menos instrumentos científicos.", 32))

	var der = VBoxContainer.new()
	der.add_theme_constant_override("separation", 10)
	der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(der)
	var t: Label = Estilo.con_borde(Estilo.nuevo_texto("SUMINISTROS PARA 4 ASTRONAUTAS Y 14 DÍAS", 24, Estilo.C_VERDE))
	der.add_child(t)
	der.add_child(_dato("agua", "Agua: 162,4 litros", "2,5 L para beber + 0,4 L de higiene por astronauta al día (estándar NASA)."))
	der.add_child(_dato("comida", "Comida: 169.960 kcal", "3.035 kcal por astronauta al día (requerimiento energético NASA)."))
	der.add_child(_dato("oxigeno", "Oxígeno y filtros de CO2", "El aire se recicla. Si los filtros se saturan, el CO2 intoxica a la tripulación."))
	der.add_child(_dato("electricidad", "Electricidad", "Paneles solares y celdas. Sin energía no funciona el soporte vital."))
	der.add_child(_dato("combustible", "Combustible", "Solo alcanza para las maniobras planeadas: ir, orbitar y volver."))
	return v

# ---------------------------------------------------------------
# Página 3: la tripulación
# ---------------------------------------------------------------
func _pagina_tripulacion() -> Control:
	var v: VBoxContainer = _pagina("LA TRIPULACIÓN", "Cuatro especialistas. Cada uno quiere algo distinto... y tú decides")
	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(fila)
	for t in TRIPULACION:
		var id: String = t["id"]
		var color: Color = Estilo.ACENTO[id]
		var tarjeta: PanelContainer = Estilo.nuevo_panel(Estilo.C_PANEL, color, 14)
		tarjeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tarjeta.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		fila.add_child(tarjeta)
		var c = VBoxContainer.new()
		c.add_theme_constant_override("separation", 8)
		tarjeta.add_child(c)
		c.add_child(Estilo.nuevo_retrato(id, "normal", 4))
		var nombre: Label = Estilo.nuevo_texto(String(t["nombre"]), 24, color)
		nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_child(nombre)
		var rol: Label = Estilo.nuevo_texto("%s  ·  %d años" % [t["rol"], t["edad"]], 16, Estilo.C_TEXTO_SUAVE)
		rol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_child(rol)
		c.add_child(HSeparator.new())
		c.add_child(Estilo.nuevo_texto("QUIERE:", 16, Estilo.C_AMARILLO))
		c.add_child(Estilo.nuevo_texto(String(t["objetivo"]), 16, Estilo.C_TEXTO))
		c.add_child(Estilo.nuevo_texto("CARÁCTER:", 16, Estilo.C_AMARILLO))
		c.add_child(Estilo.nuevo_texto(String(t["rasgo"]), 16, Estilo.C_TEXTO))
	return v

# ---------------------------------------------------------------
# Página 4: la misión
# ---------------------------------------------------------------
func _pagina_mision() -> Control:
	var v: VBoxContainer = _pagina("TU MISIÓN", "Sobrevivir 14 días, hacer ciencia y volver a casa")
	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 30)
	v.add_child(fila)

	var izq = VBoxContainer.new()
	izq.add_theme_constant_override("separation", 10)
	izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(izq)
	izq.add_child(Estilo.con_borde(Estilo.nuevo_texto("CADA DÍA", 24, Estilo.C_VERDE)))
	izq.add_child(_dato("racion_completa", "1. Da las órdenes", "Ración de comida, instrumentos científicos e higiene."))
	izq.add_child(_dato("reloj", "2. Decide contra reloj", "Una emergencia de la nave y una decisión de recursos."))
	izq.add_child(_dato("salud", "3. Cuida a tu gente", "El hambre y el estrés enferman a la tripulación y provocan errores."))
	izq.add_child(_dato("ciencia", "4. No olvides la ciencia", "Necesitas 70 % de progreso científico para el mejor final."))

	var der = VBoxContainer.new()
	der.add_theme_constant_override("separation", 10)
	der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(der)
	der.add_child(Estilo.con_borde(Estilo.nuevo_texto("TRES FINALES POSIBLES", 24, Estilo.C_VERDE)))
	der.add_child(_dato("resultado_bueno", "Misión cumplida", "Los cuatro vivos, reservas por encima de 15 % y las muestras lunares a bordo."))
	der.add_child(_dato("resultado_intermedio", "Misión abortada", "Regresan con vida, pero sin la ciencia o con pérdidas en la tripulación."))
	der.add_child(_dato("resultado_malo", "Silencio total", "Un recurso vital llega a cero y la última señal nunca llega a la Tierra."))
	der.add_child(_dato("memo", "Aprende con la NASA", "Después de cada decisión verás por qué funcionó o falló, con memos y enlaces reales."))
	return v
