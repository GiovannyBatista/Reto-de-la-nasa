extends Control
# Generado/modificado con ayuda de IA (Claude, Anthropic) y revisado por el equipo.
# Fondo espacial animado: nebulosa + estrellas en 3 capas que se mueven a distinta velocidad (parallax)
# + planetas que giran (Tierra y Luna).
#
# Cómo usarlo:
#     const FondoEspacio = preload("res://srcipts/FondoEspacio.gd")
#     var fondo = FondoEspacio.new()
#     add_child(fondo)
#     fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
#     fondo.colocar("luna", Vector2(0.8, 0.6), 6.0)      # posición relativa (0 a 1) y tamaño (1 = 96 px)

const Estilo = preload("res://srcipts/Estilo.gd")

const RUTAS_PLANETA: Dictionary = {
	"tierra": "res://assets/space/planet-terran-spin-24f.png",
	"luna": "res://scenes/TileMaps/2x/planet-moon-spin-24f.png",
}

var velocidad: Vector2 = Vector2(8.0, 0.0)   # píxeles por segundo de la capa más cercana
var con_nebulosa: bool = true

var _capas: Array = []
var _planetas: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var base = ColorRect.new()
	base.color = Estilo.C_FONDO
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	if con_nebulosa:
		_agregar_capa("res://scenes/TileMaps/2x/nebula-violet-tile.png", 0.08, 512.0, 0.5)
	_agregar_capa("res://assets/space/stars-far-tile.png", 0.2, 256.0, 1.0)
	_agregar_capa("res://assets/space/stars-mid-tile.png", 0.5, 256.0, 1.0)
	_agregar_capa("res://assets/space/stars-near-tile.png", 1.0, 256.0, 1.0)
	resized.connect(_ajustar)
	_ajustar()

func _agregar_capa(ruta: String, factor: float, tam_tile: float, alfa: float) -> void:
	if not ResourceLoader.exists(ruta):
		return
	var t = TextureRect.new()
	t.texture = load(ruta)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_TILE
	t.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.modulate.a = alfa
	add_child(t)
	_capas.append({"nodo": t, "factor": factor, "tile": tam_tile, "pos": Vector2.ZERO})

func _ajustar() -> void:
	for c in _capas:
		c["nodo"].size = size + Vector2(c["tile"], c["tile"])
	for nombre in _planetas:
		var s: AnimatedSprite2D = _planetas[nombre]
		if s.has_meta("pos_rel") and not s.has_meta("animando"):
			s.position = Vector2(s.get_meta("pos_rel")) * size

func _process(delta: float) -> void:
	for c in _capas:
		var pos: Vector2 = c["pos"] + velocidad * float(c["factor"]) * delta
		c["pos"] = pos
		var tile: float = c["tile"]
		c["nodo"].position = -Vector2(fposmod(pos.x, tile), fposmod(pos.y, tile))

func planeta(nombre: String) -> AnimatedSprite2D:
	if _planetas.has(nombre):
		return _planetas[nombre]
	var ruta: String = RUTAS_PLANETA.get(nombre, "")
	if ruta == "" or not ResourceLoader.exists(ruta):
		return null
	var s = AnimatedSprite2D.new()
	s.sprite_frames = Estilo.cuadros_giro(ruta)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.play("default")
	add_child(s)
	_planetas[nombre] = s
	return s

# Pone (o mueve con animación) un planeta. pos_rel va de (0,0) arriba-izquierda a (1,1) abajo-derecha.
func colocar(nombre: String, pos_rel: Vector2, escala: float, duracion: float = 0.0) -> void:
	var s: AnimatedSprite2D = planeta(nombre)
	if s == null:
		return
	s.set_meta("pos_rel", pos_rel)
	var destino: Vector2 = pos_rel * size
	if duracion <= 0.0 or size == Vector2.ZERO:
		s.position = destino
		s.scale = Vector2(escala, escala)
		return
	s.set_meta("animando", true)
	var tw: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(s, "position", destino, duracion)
	tw.tween_property(s, "scale", Vector2(escala, escala), duracion)
	tw.chain().tween_callback(func(): s.remove_meta("animando"))
