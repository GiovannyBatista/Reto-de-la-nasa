extends RefCounted
# Memos NASA que aparecen después de cada decisión y en los finales.
# Los textos y enlaces salen del documento "Storytelling" del equipo (secciones [MEMO NASA EN PANTALLA]).
#
# Uso:  const Memos = preload("res://srcipts/Memos.gd")
#       var memo: Dictionary = Memos.para_decision(decision)   # {titulo, texto, fuente, url}

# --- Referencias oficiales (las del reto y las del Storytelling) ---
const REF_CREW: Dictionary = {"nombre": "NASA Crew Systems Reference", "url": "https://www.nasa.gov/reference/crew-systems/"}
const REF_HABIT: Dictionary = {"nombre": "NASA Habitability Functions Vol. 2", "url": "https://www.nasa.gov/reference/7-0-habit-ability-functions-vol-2/"}
const REF_SALUD: Dictionary = {"nombre": "NASA Health and Medical Care Standards", "url": "https://www.nasa.gov/reference/3-0-health-and-medical-care/"}
const REF_ECLSS: Dictionary = {"nombre": "NASA ECLSS Technical Brief", "url": "https://www.nasa.gov/wp-content/uploads/2023/07/eclss-technical-brief-ochmo.pdf"}
const REF_AGUA: Dictionary = {"nombre": "NASA Water Management Technical Brief (OCHMO-TB-027)", "url": "https://www.nasa.gov/wp-content/uploads/2023/12/ochmo-tb-027-water.pdf"}
const REF_DESPRES: Dictionary = {"nombre": "SpaceOps Depressurization Review (NTRS)", "url": "https://ntrs.nasa.gov/api/citations/20200011599/downloads/20200011599.pdf"}

const REFERENCIAS: Array = [REF_CREW, REF_HABIT, REF_SALUD, REF_ECLSS, REF_AGUA, REF_DESPRES]

# --- Memos del Storytelling ---
const MEMO_ENERGIA: Dictionary = {
	"titulo": "REGLAS DE VUELO ARTEMIS",
	"texto": "Tras la inserción orbital, la prioridad absoluta es la estabilización térmica y energética de los paneles solares antes de activar cargas útiles científicas.",
	"ref": REF_CREW,
}
const MEMO_NUTRICION: Dictionary = {
	"titulo": "NUTRICIÓN Y METABOLISMO (ECLSS)",
	"texto": "La NASA recomienda ajustar la ingesta calórica de forma controlada y modificar la dieta para bajar el cociente respiratorio, estabilizando el consumo metabólico sin comprometer funciones vitales.",
	"ref": REF_HABIT,
}
const MEMO_DESPRESURIZACION: Dictionary = {
	"titulo": "RESPUESTA A DESPRESURIZACIÓN",
	"texto": "Ante cualquier caída de la presión parcial de oxígeno (ppO2), el protocolo obligatorio exige colocarse máscaras o cascos de respiración de emergencia de inmediato y aislar el módulo comprometido para preservar el tiempo de reserva.",
	"ref": REF_DESPRES,
}
const MEMO_RADIACION: Dictionary = {
	"titulo": "PROTECCIÓN CONTRA RADIACIÓN ESPACIAL",
	"texto": "Durante tormentas solares en espacio profundo, la tripulación debe reubicarse en el área con mayor densidad de masa rica en hidrógeno (como los tanques de agua potable) y reducir cargas eléctricas para minimizar fallos por partículas energéticas.",
	"ref": REF_SALUD,
}
const MEMO_MEDICO: Dictionary = {
	"titulo": "CONTINGENCIA MÉDICA A BORDO",
	"texto": "Ante traumatismos en microgravedad, se debe aplicar inmovilización inmediata y aislamiento de tareas físicas pesadas para evitar complicaciones cardiorrespiratorias que pongan en riesgo la misión.",
	"ref": REF_SALUD,
}
const MEMO_RETORNO: Dictionary = {
	"titulo": "MECÁNICA ORBITAL Y RETORNO LIBRE",
	"texto": "La trayectoria de retorno libre utiliza el campo gravitatorio terrestre para minimizar el gasto de propelente y soporte vital. Intentar acortar el tránsito forzando motores compromete el ángulo de reentrada y el escudo térmico.",
	"ref": REF_CREW,
}
const MEMO_AGUA: Dictionary = {
	"titulo": "GESTIÓN DE AGUA EN CONTINGENCIA",
	"texto": "Ante fallos en el sistema de recuperación de agua (WRS), el mínimo vital obligatorio es de 2,5 litros diarios por astronauta para hidratación; todo uso higiénico debe suspenderse de inmediato.",
	"ref": REF_AGUA,
}
const MEMO_CO2: Dictionary = {
	"titulo": "CONTROL DE DIÓXIDO DE CARBONO (ECLSS)",
	"texto": "La producción de CO2 es directamente proporcional a la actividad física. Ante la saturación de los filtros, el reposo metabólico absoluto combinado con cartuchos de reserva evita la intoxicación por hipercapnia.",
	"ref": REF_ECLSS,
}
const MEMO_REDUNDANCIA: Dictionary = {
	"titulo": "ARCHIVO DE PRE-LANZAMIENTO",
	"texto": "En misiones tripuladas fuera de la órbita terrestre baja, la NASA exige márgenes de redundancia en soporte vital (ECLSS) antes de asignar masa a cargas útiles secundarias.",
	"ref": REF_CREW,
}

# Memo fijo de una decisión concreta (por su id en Eventos.gd)
const POR_ID: Dictionary = {
	"H01_insercion": MEMO_ENERGIA,
	"H04_cruce_lunar": MEMO_RETORNO,
	"H10_retorno": MEMO_RETORNO,
	"H14_reentrada": MEMO_CO2,
	"N01_fuga_o2": MEMO_DESPRESURIZACION,
	"N08_tormenta_solar": MEMO_RADIACION,
	"N06_wrs": MEMO_AGUA,
	"N07_co2": MEMO_CO2,
}

# Memo según el tema de la decisión (palabra que aparece en "tema")
const POR_TEMA: Array = [
	["Despresurización", MEMO_DESPRESURIZACION],
	["Respuesta a emergencias", MEMO_DESPRESURIZACION],
	["Radiación", MEMO_RADIACION],
	["agua", MEMO_AGUA],
	["CO", MEMO_CO2],
	["Calidad del aire", MEMO_CO2],
	["Nutrición", MEMO_NUTRICION],
	["metabólico", MEMO_NUTRICION],
	["Mecánica orbital", MEMO_RETORNO],
	["Eficiencia de propulsión", MEMO_RETORNO],
]

# Si no hay memo, al menos un enlace de la NASA relacionado con el tema
const ENLACE_POR_TEMA: Array = [
	["higiene", REF_HABIT],
	["térmic", REF_HABIT],
	["Ahorro", REF_HABIT],
	["Atmósfera", REF_ECLSS],
	["Monitoreo ambiental", REF_ECLSS],
	["incendios", REF_ECLSS],
	["Reservas", REF_HABIT],
]

# Devuelve {titulo, texto, fuente, url}. "texto" puede venir vacío (solo hay enlace).
static func para_decision(decision: Dictionary) -> Dictionary:
	var id: String = String(decision.get("id", ""))
	var tema: String = String(decision.get("tema", ""))
	var memo: Dictionary = {}
	if POR_ID.has(id):
		memo = POR_ID[id]
	else:
		for par in POR_TEMA:
			if tema.findn(String(par[0])) != -1:
				memo = par[1]
				break
	if not memo.is_empty():
		return {"titulo": memo["titulo"], "texto": memo["texto"], "fuente": memo["ref"]["nombre"], "url": memo["ref"]["url"]}
	var ref: Dictionary = REF_CREW
	for par in ENLACE_POR_TEMA:
		if tema.findn(String(par[0])) != -1:
			ref = par[1]
			break
	return {"titulo": tema, "texto": "", "fuente": ref["nombre"], "url": ref["url"]}

# Memo que cierra cada final
static func para_final(tipo: String) -> Dictionary:
	var memo: Dictionary = MEMO_RETORNO
	if tipo == "intermedio":
		memo = MEMO_REDUNDANCIA
	elif tipo == "malo":
		memo = MEMO_CO2 if GameManager.forzar_final != "" else MEMO_REDUNDANCIA
	return {"titulo": memo["titulo"], "texto": memo["texto"], "fuente": memo["ref"]["nombre"], "url": memo["ref"]["url"]}
