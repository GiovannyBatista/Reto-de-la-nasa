extends RefCounted
# Estilo visual compartido por las pantallas gráficas (menú, prólogo, misión y finales).
# Aquí viven los colores, la fuente y las funciones que crean paneles, botones, barras, iconos y retratos,
# para que todas las pantallas se vean iguales.
#
# Cómo usarlo desde otro script:
#     const Estilo = preload("res://srcipts/Estilo.gd")
#     theme = Estilo.tema()
#     var boton = Estilo.nuevo_boton("JUGAR")

const RUTA_FUENTE: String = "res://assets/Thin_Sans.ttf"

# --- Colores (cámbialos aquí y cambian en todo el juego) ---
const C_FONDO: Color = Color(0.02, 0.03, 0.08)
const C_PANEL: Color = Color(0.03, 0.05, 0.11, 0.90)
const C_PANEL_CLARO: Color = Color(0.07, 0.11, 0.20, 0.94)
const C_BORDE: Color = Color(0.28, 0.48, 0.80)
const C_CIAN: Color = Color(0.45, 0.85, 1.0)
const C_VERDE: Color = Color(0.42, 0.90, 0.52)
const C_AMARILLO: Color = Color(1.0, 0.86, 0.36)
const C_NARANJA: Color = Color(1.0, 0.62, 0.25)
const C_ROJO: Color = Color(1.0, 0.36, 0.36)
const C_VIOLETA: Color = Color(0.70, 0.52, 1.0)
const C_TEXTO: Color = Color(0.93, 0.96, 1.0)
const C_TEXTO_SUAVE: Color = Color(0.66, 0.75, 0.88)
const C_OSCURO: Color = Color(0.08, 0.10, 0.16)

# Color que identifica a cada tripulante (borde de su tarjeta, nombre, etc.)
const ACENTO: Dictionary = {
	"elena": Color(0.88, 0.34, 0.29),
	"marcus": Color(0.29, 0.56, 0.88),
	"sofia": Color(0.31, 0.79, 0.63),
	"leo": Color(0.94, 0.63, 0.19),
}

# Iconos que ya había hecho el equipo para la tienda y que se reutilizan aquí
const ICONOS_EXTERNOS: Dictionary = {
	"agua": "res://assets/ui/icono_soporte.png",
	"filtros": "res://assets/ui/icono_filtros.png",
}

const COLOR_RESULTADO: Dictionary = {
	"bueno": Color(0.42, 0.90, 0.52),
	"intermedio": Color(1.0, 0.72, 0.28),
	"malo": Color(1.0, 0.36, 0.36),
}

static var _tema: Theme = null
static var _fuentes: Dictionary = {}

# ---------------------------------------------------------------
# Fuente pixel-art
# ---------------------------------------------------------------
# La fuente Thin_Sans deja mucho espacio vacío arriba de cada renglón. Esta función devuelve la misma
# fuente pero con los renglones más juntos, calculado para el tamaño que se va a usar.
static func fuente(tam: int) -> Font:
	if _fuentes.has(tam):
		return _fuentes[tam]
	if not ResourceLoader.exists(RUTA_FUENTE):
		return null
	var base: FontFile = load(RUTA_FUENTE)
	base.antialiasing = TextServer.FONT_ANTIALIASING_NONE     # sin suavizado: píxeles duros
	base.hinting = TextServer.HINTING_NONE
	base.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	base.fallbacks = [SystemFont.new()]                       # símbolos que la fuente no tiene
	var v = FontVariation.new()
	v.base_font = base
	v.spacing_top = -int(tam * 0.5)
	v.spacing_bottom = -int(tam * 0.125)
	_fuentes[tam] = v
	return v

# ---------------------------------------------------------------
# Tema general (fuente pixel-art + botones + barras de desplazamiento)
# ---------------------------------------------------------------
static func tema() -> Theme:
	if _tema != null:
		return _tema
	var t = Theme.new()
	var f: Font = fuente(16)
	if f != null:
		t.default_font = f
	t.default_font_size = 16     # con esta fuente usa múltiplos de 8 (16, 24, 32, 48...) para que no se vea borrosa
	t.set_color("font_color", "Label", C_TEXTO)

	# Botón principal: la imagen crema con borde naranja de la tienda (assets/ui/boton.png)
	var ruta_boton: String = "res://assets/ui/boton.png"
	if ResourceLoader.exists(ruta_boton):
		t.set_stylebox("normal", "Button", caja_tex(ruta_boton))
		t.set_stylebox("hover", "Button", caja_tex(ruta_boton, Color(1.0, 0.93, 0.70)))
		t.set_stylebox("pressed", "Button", caja_tex(ruta_boton, Color(0.75, 0.75, 0.78)))
		t.set_stylebox("disabled", "Button", caja_tex(ruta_boton, Color(0.42, 0.42, 0.48)))
	else:
		t.set_stylebox("normal", "Button", caja(Color(0.95, 0.93, 0.86), C_NARANJA))
		t.set_stylebox("hover", "Button", caja(Color(1.0, 0.95, 0.75), C_NARANJA))
		t.set_stylebox("pressed", "Button", caja(Color(0.75, 0.75, 0.78), C_NARANJA))
		t.set_stylebox("disabled", "Button", caja(Color(0.42, 0.42, 0.48), C_BORDE))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(estado, "Button", C_OSCURO)
	t.set_color("font_disabled_color", "Button", Color(0.25, 0.27, 0.33))

	# Paneles y separadores
	t.set_stylebox("panel", "PanelContainer", caja(C_PANEL, C_BORDE))
	var linea = StyleBoxLine.new()
	linea.color = Color(C_BORDE, 0.6)
	linea.thickness = 2
	t.set_stylebox("separator", "HSeparator", linea)
	t.set_constant("separation", "HSeparator", 10)

	# Barra de desplazamiento delgada
	var riel = StyleBoxFlat.new()
	riel.bg_color = Color(0.02, 0.03, 0.07, 0.6)
	riel.content_margin_left = 4
	riel.content_margin_right = 4
	var agarre = StyleBoxFlat.new()
	agarre.bg_color = C_BORDE
	t.set_stylebox("scroll", "VScrollBar", riel)
	t.set_stylebox("grabber", "VScrollBar", agarre)
	t.set_stylebox("grabber_highlight", "VScrollBar", agarre)
	t.set_stylebox("grabber_pressed", "VScrollBar", agarre)

	# Globos de ayuda (tooltips)
	t.set_stylebox("panel", "TooltipPanel", caja(Color(0.02, 0.03, 0.08, 0.98), C_CIAN, 2, 8))
	t.set_color("font_color", "TooltipLabel", C_TEXTO)
	_tema = t
	return t

# ---------------------------------------------------------------
# Cajas (fondos de paneles y botones)
# ---------------------------------------------------------------
# Caja de color liso con borde. Las esquinas van "cortadas" en diagonal para que parezca una consola.
static func caja(fondo: Color, borde: Color, grosor: int = 2, margen: int = 12, radio: int = 6) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = fondo
	s.border_color = borde
	s.set_border_width_all(grosor)
	s.set_corner_radius_all(radio)
	s.corner_detail = 1
	s.anti_aliasing = false
	s.set_content_margin_all(margen)
	return s

# Caja hecha con una imagen pixel-art que se estira por el centro y conserva las esquinas (9 parches).
static func caja_tex(ruta: String, tinte: Color = Color(1, 1, 1), borde: int = 8) -> StyleBoxTexture:
	var s = StyleBoxTexture.new()
	s.texture = load(ruta)
	s.set_texture_margin_all(borde)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 8
	s.content_margin_bottom = 12
	s.modulate_color = tinte
	return s

# ---------------------------------------------------------------
# Controles ya configurados
# ---------------------------------------------------------------
static func nuevo_texto(texto: String, tam: int = 16, color: Color = C_TEXTO, ajustar: bool = true) -> Label:
	var l = Label.new()
	l.text = texto
	var f: Font = fuente(tam)
	if f != null:
		l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	if ajustar:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

# Texto con borde oscuro: se lee bien encima de imágenes (estrellas, cabina, mar...)
static func con_borde(l: Label, grosor: int = 6) -> Label:
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08))
	l.add_theme_constant_override("outline_size", grosor)
	return l

static func nuevo_boton(texto: String, tam: int = 24, ancho: int = 0, alto: int = 52) -> Button:
	var b = Button.new()
	b.text = texto
	b.add_theme_font_size_override("font_size", tam)
	b.custom_minimum_size = Vector2(ancho, alto)
	b.focus_mode = Control.FOCUS_ALL
	animar_hover(b)
	return b

# ---------------------------------------------------------------
# Animaciones pequeñas (dan vida a la interfaz)
# ---------------------------------------------------------------
# El control crece un poquito cuando el ratón pasa por encima
static func animar_hover(c: Control, factor: float = 1.04) -> void:
	c.resized.connect(func(): c.pivot_offset = c.size * 0.5)
	c.mouse_entered.connect(func():
		c.pivot_offset = c.size * 0.5
		c.create_tween().tween_property(c, "scale", Vector2(factor, factor), 0.08))
	c.mouse_exited.connect(func():
		c.create_tween().tween_property(c, "scale", Vector2(1, 1), 0.10))

# Aparece con un "salto": empieza pequeño y transparente y crece hasta su tamaño
static func saltar(c: Control, retraso: float = 0.0, desde: float = 0.6) -> void:
	c.modulate.a = 0.0
	var tw: Tween = c.create_tween()
	tw.tween_interval(maxf(retraso, 0.001))
	tw.tween_callback(func():
		c.pivot_offset = c.size * 0.5
		c.scale = Vector2(desde, desde))
	tw.set_parallel(true)
	tw.tween_property(c, "modulate:a", 1.0, 0.12)
	tw.tween_property(c, "scale", Vector2(1, 1), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Tiembla hacia los lados (golpe, daño, error)
static func sacudir(c: CanvasItem, fuerza: float = 8.0, duracion: float = 0.35) -> void:
	var origen: Vector2 = c.position
	var tw: Tween = c.create_tween()
	var pasos: int = 6
	for i in pasos:
		var lado: float = fuerza * (1.0 - float(i) / float(pasos)) * (1.0 if i % 2 == 0 else -1.0)
		tw.tween_property(c, "position:x", origen.x + lado, duracion / float(pasos))
	tw.tween_property(c, "position:x", origen.x, 0.03)

# Botón oscuro tipo pantalla de consola (para opciones que se encienden y apagan)
static func estilo_holo(b: Button, color: Color = C_CIAN) -> void:
	b.add_theme_stylebox_override("normal", caja(Color(0.05, 0.08, 0.16, 0.95), Color(C_BORDE, 0.8), 2, 8))
	b.add_theme_stylebox_override("hover", caja(Color(0.09, 0.14, 0.26, 0.98), color, 2, 8))
	b.add_theme_stylebox_override("pressed", caja(Color(0.14, 0.22, 0.38, 1.0), C_AMARILLO, 3, 7))
	b.add_theme_stylebox_override("disabled", caja(Color(0.05, 0.06, 0.10, 0.8), Color(0.25, 0.28, 0.36), 2, 8))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", C_TEXTO)
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_pressed_color", C_AMARILLO)
	b.add_theme_color_override("font_hover_pressed_color", C_AMARILLO)
	b.add_theme_color_override("font_focus_color", C_TEXTO)
	b.add_theme_color_override("font_disabled_color", Color(0.45, 0.48, 0.56))

static func nuevo_panel(fondo: Color = C_PANEL, borde: Color = C_BORDE, margen: int = 12) -> PanelContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", caja(fondo, borde, 2, margen))
	return p

static func icono(nombre: String) -> Texture2D:
	var ruta: String = ICONOS_EXTERNOS.get(nombre, "res://assets/iconos/%s.png" % nombre)
	if ResourceLoader.exists(ruta):
		return load(ruta)
	return null

static func nuevo_icono(nombre: String, tam: int = 32) -> TextureRect:
	var t = TextureRect.new()
	t.texture = icono(nombre)
	t.custom_minimum_size = Vector2(tam, tam)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return t

# Barra de progreso de color (0 a 100)
static func nueva_barra(color: Color, alto: int = 14) -> ProgressBar:
	var pb = ProgressBar.new()
	pb.max_value = 100.0
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, alto)
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fondo = StyleBoxFlat.new()
	fondo.bg_color = Color(0.01, 0.02, 0.05, 0.95)
	fondo.border_color = Color(0.22, 0.30, 0.44)
	fondo.set_border_width_all(2)
	fondo.anti_aliasing = false
	pb.add_theme_stylebox_override("background", fondo)
	var relleno = StyleBoxFlat.new()
	relleno.anti_aliasing = false
	relleno.set_border_width_all(2)
	relleno.border_color = Color(0, 0, 0, 0)
	pb.add_theme_stylebox_override("fill", relleno)
	color_barra(pb, color)
	return pb

static func color_barra(pb: ProgressBar, color: Color) -> void:
	var relleno: StyleBoxFlat = pb.get_theme_stylebox("fill")
	relleno.bg_color = color

# Verde si está bien, amarillo si baja de 50 y rojo si baja de 25
static func color_nivel(valor: float) -> Color:
	if valor < 25.0:
		return C_ROJO
	if valor < 50.0:
		return C_AMARILLO
	return C_VERDE

# ---------------------------------------------------------------
# Retratos de la tripulación
# ---------------------------------------------------------------
# Qué dibujo le toca a un tripulante según su salud y su estrés
static func expresion(salud: float, estres: float) -> String:
	if salud <= 0.0:
		return "perdido"
	if salud < 25.0:
		return "critico"
	if salud < 50.0:
		return "herido"
	if estres >= 40.0:
		return "estresado"
	return "normal"

static func textura_retrato(id: String, estado: String) -> Texture2D:
	var ruta: String = "res://assets/retratos/%s_%s.png" % [id, estado]
	if ResourceLoader.exists(ruta):
		return load(ruta)
	return null

# Marco tipo "pantalla de comunicaciones" con el retrato adentro. escala 2 = 96 px, 4 = 192 px.
static func nuevo_retrato(id: String, estado: String = "normal", escala: int = 2) -> PanelContainer:
	var marco = PanelContainer.new()
	var color: Color = ACENTO.get(id, C_BORDE)
	marco.add_theme_stylebox_override("panel", caja(Color(0.04, 0.09, 0.17), color, 2, 2, 4))
	marco.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	marco.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# "hueco" es una ventana fija; la imagen se puede mover dentro (para que el astronauta flote)
	var hueco = Control.new()
	hueco.custom_minimum_size = Vector2(48 * escala, 48 * escala)
	hueco.clip_contents = true
	hueco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marco.add_child(hueco)
	var img = TextureRect.new()
	img.texture = textura_retrato(id, estado)
	img.size = Vector2(48 * escala, 48 * escala)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_SCALE
	img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hueco.add_child(img)
	marco.set_meta("imagen", img)
	marco.set_meta("id", id)
	marco.set_meta("estado", estado)
	return marco

static func cambiar_retrato(marco: PanelContainer, estado: String) -> void:
	if String(marco.get_meta("estado", "")) == estado:
		return
	marco.set_meta("estado", estado)
	var img: TextureRect = marco.get_meta("imagen")
	img.texture = textura_retrato(String(marco.get_meta("id")), estado)

# Mueve la imagen dentro del marco (en microgravedad todos flotan un poco)
static func flotar_retrato(marco: PanelContainer, tiempo: float, desfase: float = 0.0) -> void:
	var img: TextureRect = marco.get_meta("imagen")
	if String(marco.get_meta("estado", "")) == "perdido":
		img.position = Vector2.ZERO
		return
	img.position = Vector2(roundf(sin(tiempo * 0.7 + desfase) * 2.0), roundf(sin(tiempo * 1.3 + desfase * 2.0) * 3.0))

# ---------------------------------------------------------------
# Animaciones de planetas (hoja de 24 cuadros de 96x96)
# ---------------------------------------------------------------
static func cuadros_giro(ruta: String, cuadros: int = 24, tam: int = 96, velocidad: float = 6.0) -> SpriteFrames:
	var tex: Texture2D = load(ruta)
	var sf = SpriteFrames.new()
	sf.set_animation_speed("default", velocidad)
	sf.set_animation_loop("default", true)
	for i in cuadros:
		var at = AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * tam, 0, tam, tam)
		sf.add_frame("default", at)
	return sf

# ---------------------------------------------------------------
# Transiciones entre pantallas (fundido a negro)
# ---------------------------------------------------------------
static func aparecer(raiz: Control, duracion: float = 0.5) -> void:
	var velo = ColorRect.new()
	velo.color = Color(0, 0, 0, 1)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(velo)
	var tw: Tween = raiz.create_tween()
	tw.tween_property(velo, "color:a", 0.0, duracion)
	tw.tween_callback(velo.queue_free)

static func cambiar_escena(raiz: Control, ruta: String, duracion: float = 0.4) -> void:
	var velo = ColorRect.new()
	velo.color = Color(0, 0, 0, 0)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	raiz.add_child(velo)
	var tw: Tween = raiz.create_tween()
	tw.tween_property(velo, "color:a", 1.0, duracion)
	tw.tween_callback(func(): raiz.get_tree().change_scene_to_file(ruta))
