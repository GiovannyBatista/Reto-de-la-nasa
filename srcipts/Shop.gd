extends Control
# Fase 0: preparación en Cabo Cañaveral (estilo cabina pixel-art).
# De los 10.000 CM, 4.000 son suministros obligatorios y 6.000 se reparten entre Paquete A, B o personalizado.
# FONDO OPCIONAL: si existe res://assets/fondo_cabina.png se usa como fondo; si no, se dibuja un cielo con estrellas.
#
# La pantalla está organizada en 3 pasos, de izquierda a derecha, para que se entienda de un vistazo:
#   1. ELIGE UN PLAN     -> Paquete A, Paquete B o Personalizada (las tarjetas se comparan con las mismas 4 filas)
#   2. AJUSTA TU NAVE    -> los 4 controles con - y +
#   3. ASÍ QUEDA TU NAVE -> qué significa tu elección: cuántos días duran las reservas, ciencia máxima, etc.
# Las reglas (costos y efectos) siguen viniendo de GameManager; aquí solo se muestran.

const Estilo = preload("res://srcipts/Estilo.gd")

const C_PANEL: Color = Color(0.05, 0.07, 0.12, 0.97)          # el último número (0.97) es la opacidad: 1.0 = nada transparente
const C_PANEL_CLARO: Color = Color(0.09, 0.13, 0.20, 0.98)
const C_BORDE: Color = Color(0.36, 0.46, 0.58)
const C_VERDE: Color = Color(0.55, 1.0, 0.65)
const C_AMARILLO: Color = Color(1.0, 0.88, 0.40)
const C_ROJO: Color = Color(1.0, 0.45, 0.45)
const C_TEXTO_SUAVE: Color = Color(0.93, 0.96, 1.0)
const COLOR_TEXTO_BOTON: Color = Color(0.08, 0.10, 0.16)   # texto de los botones con imagen (oscuro para botones claros)
const ICONOS: Dictionary = {"soporte": "💧", "celdas": "⚡", "filtros": "🌀", "instrumentos": "🔬"}

# Quién recomienda cada paquete (se muestran sus retratos en la tarjeta)
const QUIEN_RECOMIENDA: Dictionary = {"A": ["marcus", "sofia"], "B": ["leo", "elena"]}
# Explicación corta de cada control (la larga de GameManager sale al dejar el ratón encima)
const EFECTO_CORTO: Dictionary = {
	"soporte": "Más reservas, menos estrés.",
	"celdas": "Más energía, maniobras baratas.",
	"filtros": "+1 cartucho de CO2.",
	"instrumentos": "+20 % de ciencia máxima.",
}
# Nombre corto de cada control para su tarjeta (el nombre completo sale al dejar el ratón encima)
const NOMBRE_CORTO: Dictionary = {"soporte": "Soporte vital", "celdas": "Celdas y combustible", "filtros": "Filtros de CO2", "instrumentos": "Instrumentos"}
const DIAS_MISION: float = 14.0

# --- Assets que eliges en el Inspector (selecciona el nodo raíz de shop.tscn y arrastra las imágenes) ---
@export var marco_icono: Texture2D        # marco de la ranura de cada icono
@export var icono_soporte: Texture2D
@export var icono_celdas: Texture2D
@export var icono_filtros: Texture2D
@export var icono_instrumentos: Texture2D
const ESCALA_SWITCH: int = 3     # cuántas veces se agranda el interruptor (2, 3, 4...)
const TAM_RANURA: int = 52      # tamaño del cuadro del icono (px)
const TAM_ICONO: int = 32        # tamaño del icono dentro del cuadro (px)
const BORDE_MARCO: int = 4       # píxeles de borde del marco que no se estiran

var niveles: Dictionary = {}
var etiquetas_nivel: Dictionary = {}
var barras_nivel: Dictionary = {}
var botones_nivel: Dictionary = {}       # id -> {"menos": Button, "mas": Button}
var etiqueta_presupuesto: Label
var etiqueta_mensaje: Label
var etiqueta_nombre_plan: Label
var barra_presupuesto: Control
var tarjetas_plan: Dictionary = {}       # "A", "B", "personalizada" -> PanelContainer
var indicadores: Dictionary = {}         # clave -> {"valor": Label, "nota": Label}
var caja_veredicto: PanelContainer
var etiqueta_veredicto: Label
var _gastado_mostrado: float = 0.0       # para animar la barra del presupuesto

const RUTA_FUENTE: String = "res://assets/Thin_Sans.ttf"

# Fuente pixel-art: se usa si el archivo existe; los acentos, la ñ y los símbolos que la fuente no tiene salen con una fuente del sistema.
func _aplicar_fuente() -> void:
	if not ResourceLoader.exists(RUTA_FUENTE):
		return
	var t = Theme.new()
	t.default_font = Estilo.fuente(16)   # la misma Thin_Sans, con los renglones más juntos para que todo quepa
	t.default_font_size = 16   # IMPORTANTE: solo múltiplos de 8 (16, 24, 32); otros tamaños se ven borrosos
	# Contorno oscuro en todos los textos para que se lean sobre las estrellas
	t.set_color("font_outline_color", "Label", Color(0.02, 0.03, 0.08))
	t.set_constant("outline_size", "Label", 4)
	t.set_stylebox("panel", "TooltipPanel", Estilo.caja(Color(0.02, 0.03, 0.08, 0.98), Estilo.C_CIAN, 2, 8))
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
	margen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for lado in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 28)
	margen.add_theme_constant_override("margin_top", 14)
	margen.add_theme_constant_override("margin_bottom", 14)
	scroll.add_child(margen)

	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	margen.add_child(fila)

	# Columna izquierda: cabecera, presupuesto, paso 1 y paso 2
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(col)
	_construir_cabecera(col)
	_construir_presupuesto(col)
	_construir_paquetes(col)
	_construir_personalizada(col)

	# Columna derecha: paso 3 (resultado) y botón de despegue
	var der = VBoxContainer.new()
	der.add_theme_constant_override("separation", 8)
	der.custom_minimum_size = Vector2(430, 0)
	fila.add_child(der)
	_construir_resumen(der)

	etiqueta_mensaje = _texto(der, "", C_AMARILLO)
	etiqueta_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var iniciar = Button.new()
	iniciar.text = "INICIAR MISIÓN"
	iniciar.custom_minimum_size = Vector2(0, 64)
	iniciar.add_theme_font_size_override("font_size", 32)
	_estilo_boton(iniciar, Color(0.15, 0.5, 0.25), C_VERDE)
	Estilo.animar_hover(iniciar, 1.03)
	iniciar.pressed.connect(_on_iniciar)
	der.add_child(iniciar)

	actualizar()
	Estilo.aparecer(self, 0.5)

func _process(delta: float) -> void:
	# La barra del presupuesto se mueve suave hacia el valor real
	var objetivo: float = float(_gastado())
	if not is_equal_approx(_gastado_mostrado, objetivo):
		_gastado_mostrado = move_toward(_gastado_mostrado, objetivo, delta * 9000.0)
		if barra_presupuesto != null:
			barra_presupuesto.queue_redraw()

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
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
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

func _panel(padre: Control, fondo: Color = C_PANEL, borde: Color = C_BORDE, tinte: Color = Color(0, 0, 0, 0)) -> VBoxContainer:
	var p = PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var color_tinte: Color = Color(1, 1, 1) if fondo == C_PANEL else Color(1.2, 1.2, 1.2)
	if tinte.a > 0.0:
		color_tinte = tinte
	var estilo: StyleBox = _caja_tex("res://assets/ui/panel.png", color_tinte)
	if estilo == null:
		estilo = _caja(fondo, borde)
	p.add_theme_stylebox_override("panel", estilo)
	padre.add_child(p)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
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
		b.add_theme_stylebox_override("hover", _caja_tex(ruta, Color(1.0, 0.93, 0.70)))
		b.add_theme_stylebox_override("pressed", _caja_tex(ruta, Color(0.7, 0.7, 0.7)))
		b.add_theme_stylebox_override("disabled", _caja_tex(ruta, Color(0.4, 0.4, 0.4)))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
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

# Título de cada paso: número dentro de un cuadro + texto
func _titulo_paso(padre: Control, numero: String, texto: String, nota: String = "") -> void:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	padre.add_child(h)
	var cuadro = PanelContainer.new()
	cuadro.add_theme_stylebox_override("panel", Estilo.caja(C_AMARILLO, Color(0.08, 0.10, 0.16), 2, 2, 4))
	cuadro.custom_minimum_size = Vector2(36, 36)
	h.add_child(cuadro)
	var n = Label.new()
	n.text = numero
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	n.add_theme_font_size_override("font_size", 24)
	n.add_theme_color_override("font_color", Color(0.08, 0.10, 0.16))
	n.add_theme_constant_override("outline_size", 0)
	cuadro.add_child(n)
	var t = Label.new()
	t.text = texto
	t.add_theme_font_size_override("font_size", 24)
	t.add_theme_color_override("font_color", C_AMARILLO)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(t)
	if nota != "":
		var n2 = Label.new()
		n2.text = nota
		n2.add_theme_color_override("font_color", C_TEXTO_SUAVE)
		n2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		n2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(n2)

# Escena de fondo espacial (TileMapLayers + Tierra + Sol). Se prueban estas rutas en orden; cambia la lista si la guardaste en otro lado.
const RUTAS_ESCENA_FONDO: Array = [
	"res://scenes/background_shop.tscn",
	"res://background_shop.tscn",
	"res://scenes/TileMaps/background_shop.tscn",
]
const TAM_TILE_FONDO: int = 256   # tamaño de cada celda de estrellas (px)

func _poner_escena_fondo() -> bool:
	var escena: PackedScene = null
	for ruta in RUTAS_ESCENA_FONDO:
		if ResourceLoader.exists(ruta):
			escena = load(ruta)
			break
	if escena == null:
		return false
	var fondo: Node = escena.instantiate()
	add_child(fondo)
	var tam: Vector2 = get_viewport_rect().size
	# Rellena las capas de estrellas para cubrir toda la pantalla (la escena original solo cubre 512x512)
	var capas: Node = fondo.find_child("Tielmaplayers", true, false)
	if capas != null:
		var columnas: int = int(ceil(tam.x / float(TAM_TILE_FONDO))) + 4
		var filas: int = int(ceil(tam.y / float(TAM_TILE_FONDO))) + 4
		for capa in capas.get_children():
			if capa is TileMapLayer:
				for x in columnas:
					for y in filas:
						capa.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	# Tierra y Sol en posiciones que dependen del tamaño de la pantalla
	var tierra: Node = fondo.find_child("tierra", true, false)
	if tierra is Node2D:
		tierra.position = Vector2(tam.x * 0.95, tam.y * 0.95)     # abajo a la derecha: no tapa los números del paso 3
		tierra.scale = Vector2(3, 3)
	var sol: Node = fondo.find_child("sol", true, false)
	if sol is Node2D:
		sol.position = Vector2(tam.x * 0.07, tam.y * 0.16)
		sol.scale = Vector2(2, 2)
	return true

func _fondo() -> void:
	var base = ColorRect.new()
	base.color = Color(0.02, 0.03, 0.08)
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _poner_escena_fondo():
		return
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
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	var textos = VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 0)
	h.add_child(textos)
	var t1 = _texto(textos, "FASE 0: PREPARA LA ORIÓN")
	t1.add_theme_font_size_override("font_size", 32)
	_texto(textos, "Lo que cargues hoy es todo lo que tendrás durante 14 días.", C_TEXTO_SUAVE)
	# La tripulación reunida frente a la consola de carga
	for id in GameManager.TRIPULANTES:
		var retrato: PanelContainer = Estilo.nuevo_retrato(String(id), "normal", 1)
		h.add_child(retrato)

func _construir_presupuesto(col: VBoxContainer) -> void:
	var v = _panel(col, C_PANEL_CLARO)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	var t = Label.new()
	t.text = "PRESUPUESTO"
	t.add_theme_color_override("font_color", C_AMARILLO)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(t)
	barra_presupuesto = Control.new()
	barra_presupuesto.custom_minimum_size = Vector2(0, 30)
	barra_presupuesto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra_presupuesto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	barra_presupuesto.tooltip_text = "Gris: suministros básicos obligatorios (agua, comida y oxígeno mínimos de la NASA).\nNaranja: lo que llevas gastado.\nVerde: lo que te queda."
	barra_presupuesto.draw.connect(_dibujar_presupuesto)
	h.add_child(barra_presupuesto)
	etiqueta_presupuesto = Label.new()
	etiqueta_presupuesto.add_theme_font_size_override("font_size", 24)
	etiqueta_presupuesto.add_theme_color_override("font_color", C_VERDE)
	etiqueta_presupuesto.custom_minimum_size = Vector2(250, 0)
	etiqueta_presupuesto.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	etiqueta_presupuesto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(etiqueta_presupuesto)

# Barra de 3 tramos: obligatorio (gris), gastado (naranja) y disponible (verde)
func _dibujar_presupuesto() -> void:
	var c: Control = barra_presupuesto
	var total: float = float(GameManager.PRESUPUESTO_TOTAL)
	var ancho: float = c.size.x
	var alto: float = c.size.y
	var w_fijo: float = ancho * float(GameManager.COSTO_OBLIGATORIO) / total
	var w_gasto: float = ancho * _gastado_mostrado / total
	c.draw_rect(Rect2(0, 0, ancho, alto), Color(0.02, 0.03, 0.08))
	c.draw_rect(Rect2(0, 0, w_fijo, alto), Color(0.42, 0.48, 0.60))
	c.draw_rect(Rect2(w_fijo, 0, w_gasto, alto), Color(1.0, 0.62, 0.25))
	c.draw_rect(Rect2(w_fijo + w_gasto, 0, ancho - w_fijo - w_gasto, alto), Color(0.30, 0.78, 0.42))
	c.draw_rect(Rect2(0, 0, ancho, alto), Color(0.02, 0.03, 0.08), false, 2.0)
	var fuente: Font = Estilo.fuente(16)
	if fuente != null:
		c.draw_string(fuente, Vector2(8, alto - 9), "BÁSICOS %d" % GameManager.COSTO_OBLIGATORIO, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.05, 0.06, 0.10))
		if w_gasto > 110.0:
			c.draw_string(fuente, Vector2(w_fijo + 8, alto - 9), "TU PLAN %d" % roundi(_gastado_mostrado), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.05, 0.06, 0.10))

# Una fila de comparación dentro de la tarjeta de un paquete: icono + texto de color
func _fila_paquete(padre: Control, icono: String, texto: String, color: Color) -> void:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	padre.add_child(h)
	h.add_child(Estilo.nuevo_icono(icono, 24))
	var l = Label.new()
	l.text = texto
	l.add_theme_color_override("font_color", color)
	h.add_child(l)

func _color_dias(dias: float, bueno: float, justo: float) -> Color:
	if dias >= bueno:
		return C_VERDE
	if dias >= justo:
		return C_AMARILLO
	return C_ROJO

func _construir_paquetes(col: VBoxContainer) -> void:
	_titulo_paso(col, "1", "ELIGE UN PLAN", "Verde = bien   Amarillo = justo   Rojo = no alcanza")
	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	col.add_child(fila)
	for clave in GameManager.paquetes:
		var datos: Dictionary = GameManager.paquetes[clave]
		var v = _panel(fila)
		tarjetas_plan[clave] = v.get_parent()
		var partes: PackedStringArray = String(datos["nombre"]).split(": ", true, 1)
		var cabeza = HBoxContainer.new()
		cabeza.add_theme_constant_override("separation", 6)
		v.add_child(cabeza)
		for id in QUIEN_RECOMIENDA.get(clave, []):
			cabeza.add_child(Estilo.nuevo_retrato(String(id), "normal", 1))
		var b = Button.new()
		b.text = String(partes[0]).to_upper()      # botón corto: "PAQUETE A"
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 24)
		b.tooltip_text = String(datos["descripcion"])
		_estilo_boton(b, Color(0.14, 0.22, 0.34), C_BORDE)
		b.pressed.connect(_on_paquete.bind(clave))
		cabeza.add_child(b)
		if partes.size() > 1:
			_texto(v, String(partes[1]).get_slice(" (", 0).to_upper(), C_AMARILLO)
		# Las mismas 4 filas en cada paquete, para comparar de un vistazo
		var p: Dictionary = GameManager.parametros_plan(datos["niveles"])
		var dias: float = 100.0 / float(p["consumo_basico"])
		var energia: float = 100.0 / float(p["consumo_elec"])
		_fila_paquete(v, "agua", "Reservas: %d días" % int(dias), _color_dias(dias, 16.0, 14.5))
		_fila_paquete(v, "electricidad", "Energía: %d días" % int(energia), _color_dias(energia, 17.0, 15.0))
		_fila_paquete(v, "filtros", "Filtros de CO2: %d" % int(p["filtros"]), _color_dias(float(p["filtros"]), 4.0, 3.0))
		_fila_paquete(v, "ciencia", "Ciencia máx.: %d %%" % roundi(p["ciencia_max"]),
			C_VERDE if float(p["ciencia_max"]) >= GameManager.CIENCIA_FINAL_BUENO else C_ROJO)
	var v3 = _panel(fila)
	tarjetas_plan["personalizada"] = v3.get_parent()
	var b3 = Button.new()
	b3.text = "PERSONALIZADA"
	b3.add_theme_font_size_override("font_size", 24)
	b3.tooltip_text = "Pone los 4 controles en cero para que repartas tú los créditos."
	_estilo_boton(b3, Color(0.14, 0.22, 0.34), C_BORDE)
	b3.pressed.connect(_on_reiniciar)
	v3.add_child(b3)
	_texto(v3, "ARMA TU PROPIA NAVE", C_AMARILLO)
	_texto(v3, "Empieza de cero y reparte tú los 6.000 CM con los botones - y + del paso 2.", C_TEXTO_SUAVE)

func _construir_personalizada(col: VBoxContainer) -> void:
	_titulo_paso(col, "2", "AJUSTA TU NAVE (OPCIONAL)")
	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	col.add_child(fila)
	for c in GameManager.controles:
		var id: String = c["id"]
		var tarjeta = _panel(fila, C_PANEL_CLARO)
		tarjeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tarjeta.get_parent().tooltip_text = "%s\n%s" % [c["nombre"], c["efecto"]]
		var cabeza = HBoxContainer.new()
		cabeza.add_theme_constant_override("separation", 8)
		tarjeta.add_child(cabeza)
		cabeza.add_child(_ranura_icono(id))
		var nombre_c = _texto(cabeza, String(NOMBRE_CORTO.get(id, c["nombre"])))
		nombre_c.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var linea = HBoxContainer.new()
		linea.add_theme_constant_override("separation", 6)
		tarjeta.add_child(linea)
		var menos = Button.new()
		menos.text = " - "
		menos.add_theme_font_size_override("font_size", 24)
		_estilo_boton(menos, Color(0.2, 0.28, 0.4), C_BORDE)
		menos.pressed.connect(_on_cambiar.bind(id, -1))
		linea.add_child(menos)
		var nivel = Label.new()
		nivel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nivel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nivel.add_theme_font_size_override("font_size", 24)
		linea.add_child(nivel)
		var mas = Button.new()
		mas.text = " + "
		mas.add_theme_font_size_override("font_size", 24)
		_estilo_boton(mas, Color(0.2, 0.28, 0.4), C_BORDE)
		mas.pressed.connect(_on_cambiar.bind(id, 1))
		linea.add_child(mas)
		var barra = ProgressBar.new()
		barra.max_value = float(c["max"])
		barra.show_percentage = false
		barra.custom_minimum_size = Vector2(0, 12)
		_estilo_barra(barra)
		tarjeta.add_child(barra)
		_texto(tarjeta, "%d CM cada nivel" % int(c["costo"]), C_AMARILLO)
		_texto(tarjeta, String(EFECTO_CORTO.get(id, c["efecto"])), C_TEXTO_SUAVE)
		etiquetas_nivel[id] = nivel
		barras_nivel[id] = barra
		botones_nivel[id] = {"menos": menos, "mas": mas}

# Un indicador del paso 3: icono + nombre + valor grande + nota
func _indicador(padre: Control, clave: String, icono: String, nombre: String, ayuda: String) -> void:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_STOP
	h.tooltip_text = ayuda
	padre.add_child(h)
	h.add_child(Estilo.nuevo_icono(icono, 40))
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", -6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var n = Label.new()
	n.text = nombre
	n.add_theme_color_override("font_color", C_TEXTO_SUAVE)
	v.add_child(n)
	var nota = Label.new()
	nota.add_theme_color_override("font_color", Color(0.70, 0.78, 0.90))
	v.add_child(nota)
	var valor = Label.new()
	valor.add_theme_font_size_override("font_size", 24)
	valor.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(valor)
	indicadores[clave] = {"valor": valor, "nota": nota}

func _construir_resumen(col: VBoxContainer) -> void:
	_titulo_paso(col, "3", "ASÍ QUEDA TU NAVE")
	var v = _panel(col, C_PANEL, C_BORDE, Color(0.42, 0.46, 0.60))     # más oscuro: detrás está la Tierra
	v.add_theme_constant_override("separation", 6)
	etiqueta_nombre_plan = _texto(v, "", C_AMARILLO)
	etiqueta_nombre_plan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_indicador(v, "reservas", "agua", "Agua, comida, aire", "Días que duran las reservas con el consumo normal.\nLa misión dura 14 días. Referencia NASA: 2,5 L de agua y 3.035 kcal por astronauta al día.")
	_indicador(v, "energia", "electricidad", "Electricidad", "Días que dura la electricidad sin contar los instrumentos científicos.")
	_indicador(v, "filtros", "filtros", "Filtros de CO2", "Cartuchos de reserva para limpiar el aire. Sin cartuchos, el CO2 intoxica a la tripulación.")
	_indicador(v, "ciencia", "ciencia", "Ciencia máxima", "Hasta dónde puede llegar el progreso científico con los instrumentos que llevas.\nEl final bueno exige 70 %.")
	_indicador(v, "estres", "estres", "Estrés diario", "Cuánto sube el estrés de cada tripulante por día, antes de las decisiones.")
	_indicador(v, "maniobras", "combustible", "Maniobras", "Cuánto combustible gasta cada maniobra (x1,00 es lo normal).")

	caja_veredicto = PanelContainer.new()
	caja_veredicto.add_theme_stylebox_override("panel", Estilo.caja(Color(0.05, 0.12, 0.10, 0.95), C_VERDE, 2, 10))
	col.add_child(caja_veredicto)
	etiqueta_veredicto = Label.new()
	etiqueta_veredicto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta_veredicto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja_veredicto.add_child(etiqueta_veredicto)

	var modo = _panel(col, C_PANEL_CLARO)
	var sin_tiempo = CheckButton.new()
	sin_tiempo.text = "MODO APRENDIZAJE (sin reloj)"
	sin_tiempo.tooltip_text = "Sin temporizador en las decisiones: ideal para la primera partida."
	sin_tiempo.button_pressed = GameManager.modo_sin_temporizador
	sin_tiempo.toggled.connect(_on_modo_sin_tiempo)
	# Interruptor con tus imágenes: assets/ui/switch_on.png (activado) y assets/ui/switch_off.png (apagado)
	for par in [["checked", "switch_on"], ["checked_disabled", "switch_on"], ["unchecked", "switch_off"], ["unchecked_disabled", "switch_off"]]:
		var ruta_sw: String = "res://assets/ui/%s.png" % par[1]
		if ResourceLoader.exists(ruta_sw):
			sin_tiempo.add_theme_icon_override(par[0], _escalar(load(ruta_sw), ESCALA_SWITCH))
	modo.add_child(sin_tiempo)

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

# Agranda una imagen por un factor entero, sin suavizar (mantiene los píxeles duros)
func _escalar(tex: Texture2D, factor: int) -> Texture2D:
	var img: Image = tex.get_image()
	if img == null or factor <= 1:
		return tex
	img.resize(img.get_width() * factor, img.get_height() * factor, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)

func _on_modo_sin_tiempo(activado: bool):
	GameManager.modo_sin_temporizador = activado

func _pintar_indicador(clave: String, valor: String, nota: String, color: Color) -> void:
	var ind: Dictionary = indicadores[clave]
	var cambio: bool = ind["valor"].text != valor and ind["valor"].text != ""
	ind["valor"].text = valor
	ind["valor"].add_theme_color_override("font_color", color)
	ind["nota"].text = nota
	if cambio:
		# El número da un saltito cuando cambia
		var l: Label = ind["valor"]
		l.pivot_offset = l.size * 0.5
		l.scale = Vector2(1.25, 1.25)
		l.create_tween().tween_property(l, "scale", Vector2(1, 1), 0.2)

func actualizar():
	var gastado: int = _gastado()
	var disponible: int = GameManager.PRESUPUESTO_LIBRE - gastado
	etiqueta_presupuesto.text = "QUEDAN %d CM" % disponible
	etiqueta_presupuesto.add_theme_color_override("font_color", C_VERDE if disponible > 0 else C_AMARILLO)
	for c in GameManager.controles:
		var id: String = c["id"]
		etiquetas_nivel[id].text = "%d / %d" % [niveles[id], c["max"]]
		barras_nivel[id].value = float(niveles[id])
		botones_nivel[id]["menos"].disabled = int(niveles[id]) <= 0
		botones_nivel[id]["mas"].disabled = int(niveles[id]) >= int(c["max"]) or int(c["costo"]) > disponible

	# Qué significa esta configuración
	var p: Dictionary = GameManager.parametros_plan(niveles)
	var nombre: String = GameManager.nombre_plan(niveles)
	etiqueta_nombre_plan.text = "PLAN ACTUAL: " + nombre.to_upper()
	var dias: float = 100.0 / float(p["consumo_basico"])
	var energia: float = 100.0 / float(p["consumo_elec"])
	var meta: float = GameManager.CIENCIA_FINAL_BUENO
	_pintar_indicador("reservas", "%s días" % ("%.1f" % dias).replace(".", ","), "la misión dura 14", _color_dias(dias, 16.0, 14.5))
	_pintar_indicador("energia", "%s días" % ("%.1f" % energia).replace(".", ","), "sin instrumentos", _color_dias(energia, 17.0, 15.0))
	_pintar_indicador("filtros", "x %d" % int(p["filtros"]), "de reserva", _color_dias(float(p["filtros"]), 4.0, 3.0))
	_pintar_indicador("ciencia", "%d %%" % roundi(p["ciencia_max"]), "meta: %d %%" % int(meta),
		C_VERDE if float(p["ciencia_max"]) >= meta else C_ROJO)
	_pintar_indicador("estres", "+%s" % ("%.1f" % float(p["estres_base"])).replace(".", ","), "por tripulante", C_VERDE if float(p["estres_base"]) <= 2.25 else C_AMARILLO)
	_pintar_indicador("maniobras", "x%s" % ("%.2f" % float(p["mult_combustible"])).replace(".", ","), "de combustible", C_VERDE if float(p["mult_combustible"]) < 0.95 else C_AMARILLO)

	# Veredicto en una frase
	var texto: String = "Plan equilibrado: con buenas decisiones puedes lograr el final bueno."
	var color: Color = C_VERDE
	if float(p["ciencia_max"]) < meta:
		texto = "Con este plan NO se puede lograr el final bueno: la ciencia máxima no llega a %d %%. Sube los instrumentos." % int(meta)
		color = C_ROJO
	elif dias < DIAS_MISION + 0.5:
		texto = "Reservas muy justas: tendrás que racionar comida y agua para llegar al día 14."
		color = C_AMARILLO
	elif disponible >= 375:
		texto = "Te quedan %d CM sin usar. Puedes mejorar algo más en el paso 2." % disponible
		color = C_AMARILLO
	etiqueta_veredicto.text = texto
	etiqueta_veredicto.add_theme_color_override("font_color", color.lerp(Color(1, 1, 1), 0.3))
	caja_veredicto.add_theme_stylebox_override("panel", Estilo.caja(Color(color.darkened(0.75), 0.95), color, 2, 10))

	# Resalta la tarjeta del plan elegido
	var elegido: String = "personalizada"
	for clave in GameManager.paquetes:
		if GameManager.paquetes[clave]["niveles"] == niveles:
			elegido = String(clave)
	for clave in tarjetas_plan:
		tarjetas_plan[clave].self_modulate = Color(1.5, 1.35, 0.75) if String(clave) == elegido else Color(1, 1, 1)
	if barra_presupuesto != null:
		barra_presupuesto.queue_redraw()

func _on_iniciar():
	if _gastado() > GameManager.PRESUPUESTO_LIBRE:
		etiqueta_mensaje.text = "Te pasaste del presupuesto."
		return
	GameManager.nueva_partida()
	GameManager.aplicar_plan(niveles, GameManager.nombre_plan(niveles))
	# Si existe la escena del despegue se muestra primero; si no, se va directo a la misión
	var destino: String = "res://scenes/mission.tscn"
	if ResourceLoader.exists("res://scenes/despegue.tscn"):
		destino = "res://scenes/despegue.tscn"
	Estilo.cambiar_escena(self, destino)
