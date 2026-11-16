extends RefCounted
# Decisiones de recursos (R01-R30) en inglés, por id. El orden de las opciones es el de Eventos.gd.
const EVENTOS: Dictionary = {
	"R01_condensado": {
		"tema": "Water recovery",
		"texto": "The cabin accumulates moisture on the cold walls. It is water you could recover, but you have to decide how.",
		"opciones": [
			{"texto": "Recover the condensate with the dehumidifier and recycle it", "por_que": "The water in the humidity is already on board, but the equipment uses power and the recovered water must be treated."},
			{"texto": "Collect the water from the walls by hand with cloths", "por_que": "It uses no power, but costs time and collects less."},
			{"texto": "Drink directly from the cooling circuit", "por_que": "Coolant is not drinking water. It looks like water, but it contains toxic additives."},
		],
	},
	"R02_wrs_mantenimiento": {
		"tema": "Water recycling",
		"texto": "The water recycler is running at 70 %. With maintenance it could recover more, but stopping it has a cost.",
		"opciones": [
			{"texto": "Stop the system for 4 hours to clean and recalibrate", "por_que": "It raises efficiency, but while it is stopped no water is recycled."},
			{"texto": "Do it in stages, never stopping the system", "por_que": "There is no stoppage, but it takes more time and attention."},
			{"texto": "Leave it as it is and compensate with water rations", "por_que": "Nothing is risked with the system, but the crew pays the cost."},
		],
	},
	"R03_paneles": {
		"tema": "Electrical generation",
		"texto": "If you reorient the solar panels, the ship will produce more power, but the ship has to be turned.",
		"opciones": [
			{"texto": "Reorient the ship to maximize solar input", "por_que": "Electricity goes up, but you burn fuel and the antenna may lose the link."},
			{"texto": "Keep the orientation and reduce loads", "por_que": "It burns no fuel, but you sacrifice science."},
			{"texto": "Slow rotation to spread sun and heat", "por_que": "It balances temperature and power, but maximizes neither."},
		],
	},
	"R04_raciones": {
		"tema": "Nutrition",
		"texto": "The freeze-dried rations are running out faster than expected. You can readjust the diet.",
		"opciones": [
			{"texto": "Cut portions by 20 % and reinforce protein", "por_que": "It stretches the food, but hunger and stress go up."},
			{"texto": "Keep portions and suspend dessert and caloric drinks", "por_que": "The savings are smaller, but it affects the body less."},
			{"texto": "Eat as much as they want until it runs out", "por_que": "It raises morale today, but may leave you without food at the end."},
		],
	},
	"R05_cargas_termicas": {
		"tema": "Power saving",
		"texto": "Turning off non-essential equipment reduces consumption and heat, but you have to choose what to turn off.",
		"opciones": [
			{"texto": "Turn off the secondary scientific instruments", "por_que": "It is the cut that harms safety the least, but Leo takes it as a defeat."},
			{"texto": "Turn off cabin screens and lights", "por_que": "It leaves the science alone, but the dark environment wears the crew down."},
			{"texto": "Turn off the redundant avionics", "por_que": "The savings are big, but you are left without a backup in case of a failure."},
		],
	},
	"R06_co2_cartuchos": {
		"tema": "CO₂ control",
		"texto": "The reserve CO₂ cartridges are limited. You can extend their life in several ways.",
		"opciones": [
			{"texto": "Reduce physical activity and schedule rest", "por_que": "Less movement means less CO₂, but also less work."},
			{"texto": "Use the cartridges in shorter shifts", "por_que": "It stretches the cartridges, but the air ends up with more CO₂."},
			{"texto": "Try to regenerate a cartridge by heating it", "por_que": "Lithium hydroxide cartridges cannot be regenerated this way. It is a waste of power."},
		],
	},
	"R07_trayectoria": {
		"tema": "Propulsion efficiency",
		"texto": "A trajectory correction could use less fuel if you change the method.",
		"opciones": [
			{"texto": "Low-thrust correction with a longer maneuver time", "por_que": "It optimizes fuel, but takes longer and uses power."},
			{"texto": "Do the correction at the most efficient point of the orbit", "por_que": "It saves more fuel, but forces you to wait."},
			{"texto": "Do the correction now and keep it simple", "por_que": "It is quick, but you save nothing."},
		],
	},
	"R08_celdas": {
		"tema": "Power and water management",
		"texto": "The fuel cells produce water as a by-product. You can take advantage of it if you change the operating mode.",
		"opciones": [
			{"texto": "Raise the cells' output and collect the water", "por_que": "More water and power, but it burns fuel and heats up the ship."},
			{"texto": "Keep the output and collect only the surplus", "por_que": "Little risk, little benefit."},
			{"texto": "Turn off the cells and use batteries", "por_que": "You save fuel, but drain the batteries."},
		],
	},
	"R09_orina": {
		"tema": "Water recycling",
		"texto": "The urine processor is running at its limit. With adjustments it can recover more water, but there is a cost.",
		"opciones": [
			{"texto": "Increase the distillation cycle", "por_que": "It recovers more water, but raises consumption and heat."},
			{"texto": "Add a chemical pretreatment", "por_que": "It improves performance, but the chemical is limited."},
			{"texto": "Keep the cycle and ration the water", "por_que": "It does not touch the system, but water becomes scarce."},
		],
	},
	"R10_temperatura": {
		"tema": "Power saving",
		"texto": "Lowering the cabin temperature saves heating power, but affects comfort.",
		"opciones": [
			{"texto": "Lower it 2 °C and reinforce thermal clothing", "por_que": "You save power, but the cold tires the crew."},
			{"texto": "Lower it 4 °C and sleep in thermal bags", "por_que": "The savings are bigger, but the human cost is high."},
			{"texto": "Keep the temperature and cut other consumption", "por_que": "You protect comfort, but cut science."},
		],
	},
	"R11_sueno": {
		"tema": "Metabolic savings",
		"texto": "Synchronizing the crew's sleep reduces activity and the consumption of oxygen and food.",
		"opciones": [
			{"texto": "Synchronized 9-hour sleep", "por_que": "It saves resources and lowers stress, but stops the science."},
			{"texto": "Staggered shifts to keep operations going", "por_que": "It keeps the ship active, but the rest is worse."},
			{"texto": "Reduce sleep to get more science done", "por_que": "More science today at the cost of accumulated fatigue."},
		],
	},
	"R12_modo_ahorro_instrumentos": {
		"tema": "Payload management",
		"texto": "The scientific instruments could run in power-saving mode for a few hours.",
		"opciones": [
			{"texto": "Power-saving mode on all instruments", "por_que": "You save electricity at a small cost in data."},
			{"texto": "Turn off a single high-consumption instrument", "por_que": "The savings are bigger, but the instrument is the most valuable one."},
			{"texto": "Touch nothing and trust the margin", "por_que": "You avoid touching the science, but electricity keeps dropping."},
		],
	},
	"R13_iluminacion": {
		"tema": "Power saving",
		"texto": "Reducing lighting and screens can save some power.",
		"opciones": [
			{"texto": "Reduce lights to 50 %", "por_que": "Small savings, but it affects mood."},
			{"texto": "Turn off non-essential screens", "por_que": "Little impact, but almost no cost."},
			{"texto": "Turn off everything except the vital systems and use flashlights", "por_que": "The savings are bigger, but stress skyrockets."},
		],
	},
	"R14_kit_supervivencia": {
		"tema": "Emergency reserves",
		"texto": "There is a sealed emergency ration kit for a forced return. Open it?",
		"opciones": [
			{"texto": "Open the kit now to make up the food", "por_que": "It solves the hunger now, but uses up the last-resort reserve."},
			{"texto": "Don't open it and ration what there is", "por_que": "You keep the reserve, but hunger takes its toll."},
			{"texto": "Open only half and keep the rest", "por_que": "It balances, but breaks the seal and is hard to manage."},
		],
	},
	"R15_ciencia_por_energia": {
		"tema": "Payload prioritization",
		"texto": "To save power, you could trade part of the science for electricity.",
		"opciones": [
			{"texto": "Pause the instruments for 12 hours", "por_que": "You recover power, but Leo feels the science is being sacrificed."},
			{"texto": "Turn off only the highest-consumption instrument", "por_que": "A smaller, more targeted cut."},
			{"texto": "Keep the science going and accept the consumption", "por_que": "You advance further, but electricity plummets."},
		],
	},
	"R16_condensado_sombra": {
		"tema": "Water recovery",
		"texto": "The shaded side of the capsule condenses more moisture, but reaching it means moving the cargo.",
		"opciones": [
			{"texto": "Collect the condensate from the cold wall", "por_que": "More water, but it costs time."},
			{"texto": "Increase ventilation in that area", "por_que": "More yield, but more consumption."},
			{"texto": "Leave the moisture and touch nothing", "por_que": "It costs nothing, but you lose useful water."},
		],
	},
	"R17_presion_cabina": {
		"tema": "Cabin atmosphere",
		"texto": "Lowering the total pressure and raising the oxygen percentage reduces leaks and consumption, but it has risks.",
		"opciones": [
			{"texto": "Lower the cabin pressure by 10 %", "por_que": "It reduces oxygen loss, but the crew may feel the effects."},
			{"texto": "Raise the oxygen percentage", "por_que": "It improves breathing, but increases the fire risk."},
			{"texto": "Leave the atmosphere as it is", "por_que": "No new risks, but no savings either."},
		],
	},
	"R18_baterias_carga": {
		"tema": "Electrical management",
		"texto": "The instrument batteries can be charged during the period of most sunlight.",
		"opciones": [
			{"texto": "Charge the instrument batteries with the panels at full output", "por_que": "It takes advantage of the sun, but heats up the ship."},
			{"texto": "Charge to 60 % to reduce heat", "por_que": "Less heat, less energy."},
			{"texto": "Don't charge and shut down instruments", "por_que": "You recover power, but the science stops."},
		],
	},
	"R19_enjuague_comida": {
		"tema": "Efficient water use",
		"texto": "Reusing the food rehydration water can save liters, but there are risks.",
		"opciones": [
			{"texto": "Reuse the rinse water on the next meal", "por_que": "It saves water, but may transfer bacteria."},
			{"texto": "Rehydrate with the minimum amount of water", "por_que": "It saves water, but the food tastes worse."},
			{"texto": "Eat more dry food and less hydrated food", "por_que": "It saves a lot of water, but causes dehydration."},
		],
	},
	"R20_barras_emergencia": {
		"tema": "Nutrition",
		"texto": "There are high-calorie emergency bars. They can stretch the food, but they are unappetizing.",
		"opciones": [
			{"texto": "Use the bars for one meal a day", "por_que": "They stretch the food, but lower morale."},
			{"texto": "Save the bars for the last day", "por_que": "A reserve for the end, but they go hungry now."},
			{"texto": "Eat the bars every day", "por_que": "They secure the food, but stress builds up."},
		],
	},
	"R21_modo_single": {
		"tema": "Redundancy vs. savings",
		"texto": "You could shut down redundant avionics systems to save power, at the cost of safety.",
		"opciones": [
			{"texto": "Shut down one redundant avionics channel", "por_que": "The savings are real, but you are left without a backup."},
			{"texto": "Turn off redundancy only for a few hours, during quiet moments", "por_que": "You save less, but with less risk."},
			{"texto": "Keep everything on", "por_que": "Maximum safety, but no savings."},
		],
	},
	"R22_circuito_agua": {
		"tema": "Thermal management",
		"texto": "Making the cooling circuit more efficient can save water.",
		"opciones": [
			{"texto": "Reduce the cooling flow rate", "por_que": "It saves water, but the cabin heats up."},
			{"texto": "Repair minor leaks at the joints", "por_que": "It recovers losses, but costs time."},
			{"texto": "Leave it and compensate with rations", "por_que": "It does not touch the system, but you save nothing."},
		],
	},
	"R23_priorizar_datos": {
		"tema": "Data and communications",
		"texto": "The memory is almost full. Transmitting the most valuable data frees up space and reduces the pressure.",
		"opciones": [
			{"texto": "Transmit a compressed summary of the key data", "por_que": "It frees memory at little cost, but loses detail."},
			{"texto": "Transmit the complete data when there is a link", "por_que": "It is the most complete, but uses a lot of power."},
			{"texto": "Delete the least useful data", "por_que": "It frees up space, but you lose science and frustrate Leo."},
		],
	},
	"R24_rotacion_pasiva": {
		"tema": "Thermal control",
		"texto": "A slow passive rotation spreads the Sun's heat and saves attitude-control fuel.",
		"opciones": [
			{"texto": "Start a slow passive rotation", "por_que": "It saves fuel and balances the heat, but the antenna loses the link at times."},
			{"texto": "Keep a fixed orientation and compensate with attitude control", "por_que": "It keeps the antenna pointed, but burns fuel."},
			{"texto": "Passive rotation with pauses to transmit", "por_que": "A compromise, but complex to manage."},
		],
	},
	"R25_pedir_ayuda": {
		"tema": "Operations with Houston",
		"texto": "Houston can propose a saving procedure, if there is a link and if you ask for help.",
		"opciones": [
			{"texto": "Ask Houston for a saving procedure", "por_que": "Expert help, but uses the link and time."},
			{"texto": "Solve it with the team without consulting", "por_que": "Autonomy, but without the view of the rest of the team."},
			{"texto": "Wait for Houston to propose something", "por_que": "You risk nothing, but you save nothing either."},
		],
	},
	"R26_fuga_agua": {
		"tema": "Water recovery",
		"texto": "A water connection is dripping. The loss is small but constant.",
		"opciones": [
			{"texto": "Tighten and seal the connection", "por_que": "It recovers a drip that adds up, but takes time."},
			{"texto": "Collect the drops with cloths and recycle them", "por_que": "You don't risk the connection, but you lose time."},
			{"texto": "Ignore it until it gets worse", "por_que": "You save time, but the water is lost."},
		],
	},
	"R27_litio_trampa": {
		"tema": "CO₂ control",
		"texto": "Few CO₂ cartridges remain. Someone suggests improvising with other materials from the ship.",
		"opciones": [
			{"texto": "Use the cartridges strictly and reduce activity", "por_que": "It is what the procedure says, but it has a cost."},
			{"texto": "Improvise a filter with absorbent material from the ship", "por_que": "It seems clever, but no improvised material replaces a CO₂ scrubber."},
			{"texto": "Ask Houston for a contingency procedure", "por_que": "If there is a link, it is the safest."},
		],
	},
	"R28_bateria_ciencia": {
		"tema": "Electrical management",
		"texto": "The scientific instrument batteries can power life support in an emergency.",
		"opciones": [
			{"texto": "Use the instrument batteries as a reserve", "por_que": "It is extra power, but the science is left without power."},
			{"texto": "Use only part of them", "por_que": "More balanced."},
			{"texto": "Don't touch them", "por_que": "You protect the science, but power keeps dropping."},
		],
	},
	"R29_orbita_baja": {
		"tema": "Orbital mechanics",
		"texto": "Changing the lunar orbit altitude can save fuel on the return, but costs time.",
		"opciones": [
			{"texto": "Switch to a lower orbit before the return", "por_que": "It saves fuel on the return, but the maneuver also burns some."},
			{"texto": "Keep the current orbit", "por_que": "No risk, but no savings."},
			{"texto": "Wait for the exact return window", "por_que": "It saves some, but delays the science."},
		],
	},
	"R30_mezclar_raciones": {
		"tema": "Nutrition",
		"texto": "Mixing and reorganizing the rations can avoid waste and maintain calories.",
		"opciones": [
			{"texto": "Reorganize the menus and combine leftovers", "por_que": "It reduces waste, but takes work."},
			{"texto": "Assign rations per crew member according to their activity", "por_que": "More efficient, but creates tension over inequality."},
			{"texto": "Keep the distribution equal for everyone", "por_que": "It maintains morale, but wastes food."},
		],
	},
}
