extends Node
# Idioma del juego (Autoload "Idioma"): español (el original) o inglés.
#
# Cómo funciona:
#   - Todos los textos del juego están escritos en español dentro de los scripts.
#   - Las traducciones al inglés están en srcipts/TextosEn*.gd, como parejas "español" -> "english".
#   - Los textos fijos de etiquetas y botones se traducen SOLOS: Godot busca el texto español en la tabla.
#   - Los textos que se arman con números (por ejemplo "DÍA %d") se traducen a mano con Idioma.t():
#         etiqueta.text = Idioma.t("DÍA %d") % dia
#   - Los textos que genera GameManager (avisos, factores...) se traducen con Idioma.dinamico().
#
# Para cambiar de idioma desde cualquier script:   Idioma.cambiar("en")   o   Idioma.cambiar("es")
# El idioma elegido se guarda en el equipo y se recuerda la próxima vez.

const TextosUI = preload("res://srcipts/TextosEn.gd")
const TextosNave = preload("res://srcipts/TextosEnNave.gd")
const TextosRecursos = preload("res://srcipts/TextosEnRecursos.gd")
const RUTA_AJUSTES: String = "user://ajustes.cfg"

var idioma: String = "en"       # inglés por defecto
var _tabla: Dictionary = {}       # texto en español -> texto en inglés
var _traduccion: Translation = null   # tabla inglesa registrada en Godot
var _frases: Array = []           # trozos de frase [español, inglés] para los textos que arma GameManager

func _ready() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(RUTA_AJUSTES) == OK:
		idioma = String(cfg.get_value("juego", "idioma", "en"))
	_cargar_textos()
	_aplicar()

func _cargar_textos() -> void:
	_tabla = TextosUI.UI.duplicate()
	_frases = TextosUI.FRASES
	# Textos de las decisiones (Eventos.gd): se emparejan por id y por la posición de cada opción
	var eventos_en: Dictionary = {}
	eventos_en.merge(TextosNave.EVENTOS)
	eventos_en.merge(TextosRecursos.EVENTOS)
	for d in Eventos.banco + Eventos.hitos:
		var en: Dictionary = eventos_en.get(d["id"], {})
		if en.is_empty():
			continue
		_pareja(String(d.get("tema", "")), String(en.get("tema", "")))
		_pareja(String(d.get("texto", "")), String(en.get("texto", "")))
		var opciones_en: Array = en.get("opciones", [])
		for i in d["opciones"].size():
			if i >= opciones_en.size():
				break
			var o: Dictionary = d["opciones"][i]
			for campo in ["texto", "descripcion", "por_que"]:
				_pareja(String(o.get(campo, "")), String(opciones_en[i].get(campo, "")))
	# Se registra la tabla en Godot para que etiquetas y botones se traduzcan solos
	_traduccion = Translation.new()
	_traduccion.locale = "en"
	for clave in _tabla:
		_traduccion.add_message(clave, _tabla[clave])

func _pareja(es: String, en: String) -> void:
	if es != "" and en != "":
		_tabla[es] = en

func _aplicar() -> void:
	# Godot usa "en" como idioma de reserva, así que en español hay que QUITAR la tabla inglesa
	# (si no, seguiría traduciendo al inglés aunque el idioma sea "es").
	TranslationServer.remove_translation(_traduccion)
	if idioma == "en":
		TranslationServer.add_translation(_traduccion)
	TranslationServer.set_locale("en" if idioma == "en" else "es")

func es_ingles() -> bool:
	return idioma == "en"

func cambiar(nuevo: String) -> void:
	idioma = "en" if nuevo == "en" else "es"
	var cfg = ConfigFile.new()
	cfg.load(RUTA_AJUSTES)
	cfg.set_value("juego", "idioma", idioma)
	cfg.save(RUTA_AJUSTES)
	_aplicar()

# Traduce un texto fijo (o una plantilla con %d / %s). Si no hay traducción, devuelve el mismo texto.
func t(texto: String) -> String:
	if idioma != "en":
		return texto
	return String(_tabla.get(texto, texto))

func tiene(texto: String) -> bool:
	return _tabla.has(texto)

# Traduce un texto que GameManager armó con números y nombres: primero busca la frase completa
# y, si no está, cambia trozo por trozo.
func dinamico(texto: String) -> String:
	if idioma != "en":
		return texto
	if _tabla.has(texto):
		return String(_tabla[texto])
	var r: String = texto
	for par in _frases:
		r = r.replace(String(par[0]), String(par[1]))
	return r

# Números con decimales: coma en español (2,5) y punto en inglés (2.5). Los enteros salen sin decimales.
func num(valor: float, decimales: int = 1) -> String:
	if is_equal_approx(valor, roundf(valor)) and decimales <= 1:
		return str(int(roundf(valor)))
	var s: String = ("%." + str(decimales) + "f") % valor
	return s if idioma == "en" else s.replace(".", ",")
