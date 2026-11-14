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

# --- COHETES (números de ejemplo: el ingeniero industrial los ajustará) ---
var cohete_elegido: String = ""

var cohetes: Array = [
	{"id": "ligero", "nombre": "Cohete Ligero", "costo": 8000, "capacidad": 8000, "fiabilidad": 85},
	{"id": "medio", "nombre": "Cohete Medio", "costo": 18000, "capacidad": 14000, "fiabilidad": 92},
	{"id": "pesado", "nombre": "Cohete Pesado", "costo": 35000, "capacidad": 20000, "fiabilidad": 97},
]

func buscar_cohete(id: String) -> Dictionary:
	for c in cohetes:
		if c["id"] == id:
			return c
	return {}

# Devuelve "" si salió bien, o el motivo del error
func elegir_cohete(id: String) -> String:
	var c = buscar_cohete(id)
	if c.is_empty():
		return "Cohete no encontrado."
	if masa_actual > c["capacidad"]:
		return "Tu nave pesa %d kg y este cohete solo carga %d kg." % [masa_actual, c["capacidad"]]
	var reembolso = 0
	if cohete_elegido != "":
		reembolso = buscar_cohete(cohete_elegido)["costo"]
	if presupuesto + reembolso < c["costo"]:
		return "No tienes presupuesto suficiente para este cohete."
	presupuesto += reembolso - c["costo"]
	cohete_elegido = id
	return ""

func quitar_cohete() -> void:
	if cohete_elegido != "":
		presupuesto += buscar_cohete(cohete_elegido)["costo"]
		cohete_elegido = ""
		
# --- ENERGÍA E INSTRUMENTOS (números de ejemplo: el ingeniero industrial los ajustará) ---
var energia_paneles: int = 1000
var consumo_sistemas: Dictionary = {"oxigeno": 300, "comunicaciones": 200}
var instrumentos_comprados: Array = []

var instrumentos: Array = [
	{"id": "telescopio", "nombre": "Telescopio", "costo": 6000, "masa": 600, "consumo": 200, "ciencia": 20},
	{"id": "espectrometro", "nombre": "Espectrómetro", "costo": 8000, "masa": 900, "consumo": 250, "ciencia": 30},
	{"id": "sensor_radiacion", "nombre": "Sensor de radiación", "costo": 4000, "masa": 300, "consumo": 100, "ciencia": 15},
	{"id": "analizador", "nombre": "Analizador atmosférico", "costo": 7000, "masa": 700, "consumo": 300, "ciencia": 25},
]

func buscar_instrumento(id: String) -> Dictionary:
	for i in instrumentos:
		if i["id"] == id:
			return i
	return {}

func energia_generada() -> int:
	if "energia" in componentes_comprados:
		return energia_paneles
	return 0

func energia_consumida() -> int:
	var total = 0
	for id in consumo_sistemas:
		if id in componentes_comprados:
			total += consumo_sistemas[id]
	for id in instrumentos_comprados:
		total += buscar_instrumento(id)["consumo"]
	return total

func ciencia_total() -> int:
	var total = 0
	for id in instrumentos_comprados:
		total += buscar_instrumento(id)["ciencia"]
	return total

# Devuelve "" si salió bien, o el motivo del error
func comprar_instrumento(id: String) -> String:
	var i = buscar_instrumento(id)
	if i.is_empty():
		return "Instrumento no encontrado."
	if presupuesto < i["costo"]:
		return "No tienes presupuesto suficiente."
	if masa_actual + i["masa"] > masa_maxima:
		return "La nave excedería la masa máxima."
	if energia_consumida() + i["consumo"] > energia_generada():
		return "Tus paneles no generan energía suficiente para este instrumento."
	presupuesto -= i["costo"]
	masa_actual += i["masa"]
	instrumentos_comprados.append(id)
	return ""

func vender_instrumento(id: String) -> void:
	var i = buscar_instrumento(id)
	if i.is_empty() or not (id in instrumentos_comprados):
		return
	presupuesto += i["costo"]
	masa_actual -= i["masa"]
	instrumentos_comprados.erase(id)
