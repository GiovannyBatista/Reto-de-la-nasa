extends Node

var presupuesto_inicial: int = 100000
var presupuesto: int = 100000
var masa_maxima: int = 20000
var masa_actual: int = 0
var componentes_comprados: Array = []

# Estos números son de ejemplo: el ingeniero industrial los ajustará después
var catalogo: Array = [
	{"id": "oxigeno", "nombre": "Sistema de oxígeno", "costo": 15000, "masa": 2500},
	{"id": "energia", "nombre": "Paneles solares", "costo": 20000, "masa": 3000},
	{"id": "comunicaciones", "nombre": "Antena de comunicaciones", "costo": 12000, "masa": 1000},
	{"id": "proteccion", "nombre": "Protección contra radiación", "costo": 25000, "masa": 4000},
	{"id": "combustible", "nombre": "Tanque de combustible grande", "costo": 22000, "masa": 8000},
	{"id": "almacen", "nombre": "Almacenamiento de suministros", "costo": 10000, "masa": 2000},
]

func buscar(id: String) -> Dictionary:
	for c in catalogo:
		if c["id"] == id:
			return c
	return {}

# Devuelve "" si la compra salió bien, o el motivo si no se pudo
func comprar(id: String) -> String:
	var c = buscar(id)
	if c.is_empty():
		return "Componente no encontrado."
	if presupuesto < c["costo"]:
		return "No tienes presupuesto suficiente."
	if masa_actual + c["masa"] > masa_maxima:
		return "La nave excedería la masa máxima."
	presupuesto -= c["costo"]
	masa_actual += c["masa"]
	componentes_comprados.append(id)
	return ""

func vender(id: String) -> void:
	var c = buscar(id)
	if c.is_empty() or not (id in componentes_comprados):
		return
	presupuesto += c["costo"]
	masa_actual -= c["masa"]
	componentes_comprados.erase(id)
