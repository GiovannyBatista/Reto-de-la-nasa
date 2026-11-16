extends RefCounted
# Generado/modificado con ayuda de IA (Claude, Anthropic) y revisado por el equipo.
# Decisiones de nave (N01-N30) y hitos de la historia (H01-H14) en inglés, por id. El orden de las opciones es el de Eventos.gd.
const EVENTOS: Dictionary = {
	"N01_fuga_o2": {
		"tema": "Depressurization",
		"texto": "A sharp whistle cuts through the hum of the fans. The partial pressure of oxygen keeps dropping and you don't know how much time there is.",
		"opciones": [
			{"texto": "Emergency helmets, isolate the module and apply sealant", "por_que": "It isolates the problem and protects breathing, but it burns reserve oxygen while sealing and leaves the module inaccessible."},
			{"texto": "Deliberately lower the cabin pressure to slow the leak and repair without a helmet", "por_que": "Less pressure reduces the loss, but hypoxia arrives fast if the repair drags on."},
			{"texto": "Permanently close the service module and live with what is left", "por_que": "It cuts the leak at the root, but you lose the electricity and water that pass through that module."},
		],
	},
	"N02_bus_electrico": {
		"tema": "Electrical architecture",
		"texto": "A short circuit knocks out the main bus. The lights flicker and the cabin panels shut down one by one.",
		"opciones": [
			{"texto": "Isolate the bus and restart module by module", "por_que": "It prevents cascading failures in life support, but each restart costs power and time."},
			{"texto": "Switch to backup batteries and shut down everything except life support", "por_que": "It protects the essentials instantly, but sacrifices data and science and leaves little margin if anything else fails."},
			{"texto": "Bypass the damaged circuit with a reduced load", "por_que": "If it works, you recover everything quickly. If not, a short circuit in microgravity can cause smoke or fire."},
		],
	},
	"N03_radiador": {
		"tema": "Thermal control",
		"texto": "An external radiator stops dissipating heat. The avionics are heating up and the cabin climbs to 33 °C.",
		"opciones": [
			{"texto": "Shut down secondary computers and increase the coolant water flow", "por_que": "It lowers the thermal load quickly, but uses water and you lose computing capacity."},
			{"texto": "Rotate the ship to shade the radiator", "por_que": "It uses orientation as a passive fix, but burns fuel and may misalign the antenna."},
			{"texto": "Reduce crew activity and let the cabin cool on its own", "por_que": "It uses no resources, but sustained heat reduces crew performance and health."},
		],
	},
	"N04_micrometeorito": {
		"tema": "Structural integrity",
		"texto": "A micrometeoroid strikes near the heat shield ring. The structural integrity alarms go off.",
		"opciones": [
			{"texto": "Ultrasound inspection and resin sealing", "por_que": "Checking the shield before reentry is mandatory, but the inspection costs power and time."},
			{"texto": "Visual inspection from inside and monitor with sensors", "por_que": "It saves power, but hidden damage to the shield may show up during reentry."},
			{"texto": "Reorient the ship to expose the reinforced side", "por_que": "It protects against new impacts, but does not repair the damage and burns fuel."},
		],
	},
	"N05_antena": {
		"tema": "Communications",
		"texto": "The high-gain antenna is knocked out of alignment by vibration. The voice and telemetry link with Houston is cut.",
		"opciones": [
			{"texto": "Autonomous navigation and omnidirectional antenna with basic pulses", "por_que": "The ship is designed to operate without continuous contact, but the data memory fills up without a link."},
			{"texto": "Reorient the ship to recover the signal", "por_que": "It recovers data and the link if it goes well, but attitude control without confirmed vectors can disorient the sensors."},
			{"texto": "Restart the entire communications system", "por_que": "It fixes software faults, but if the problem is physical you waste power for nothing."},
		],
	},
	"N06_wrs": {
		"tema": "Water management",
		"texto": "A blockage halves the water recovery of the recycling system.",
		"opciones": [
			{"texto": "Suspend hygiene and clean the filter", "por_que": "It protects drinking water and fixes the cause, but stress rises from isolation and lack of hygiene."},
			{"texto": "Disassemble and purge the system with reserve water", "por_que": "It repairs thoroughly, but costs water when you need it most."},
			{"texto": "Operate at 50 % and compensate with shorter water rations", "por_que": "It requires no repair, but mild dehydration builds up and complicates reentry."},
		],
	},
	"N07_co2": {
		"tema": "CO₂ control",
		"texto": "The lithium hydroxide filters are saturating. The air turns heavy and headaches begin.",
		"opciones": [
			{"texto": "Rotate to a reserve cartridge", "por_que": "It is the standard solution, but each cartridge is irreplaceable."},
			{"texto": "Metabolic rest: everyone stays still to extend the filter", "por_que": "Less activity produces less CO₂, but it paralyzes work and the air keeps getting worse."},
			{"texto": "Mix the air with fresh oxygen to dilute the CO₂", "por_que": "It lowers the CO₂ concentration immediately, but consumes vital oxygen."},
		],
	},
	"N08_tormenta_solar": {
		"tema": "Space radiation",
		"texto": "Houston warns of a coronal mass ejection. Twelve minutes remain before the radiation arrives.",
		"opciones": [
			{"texto": "Shelter behind the water tanks and partial blackout", "por_que": "Water is a good shield against solar protons, but you lose data and the confinement stresses everyone."},
			{"texto": "Partial shelter: Leo keeps working on one key instrument", "por_que": "You save part of the science, but Leo receives a higher dose and the risk is real."},
			{"texto": "Point the service module toward the Sun and shelter behind it", "por_que": "It uses the ship's mass as shielding, but burns fuel and limits movement."},
		],
	},
	"N09_giroscopio": {
		"tema": "Attitude control",
		"texto": "A gyroscope fails and the ship starts to drift slowly. The solar panels lose their orientation.",
		"opciones": [
			{"texto": "Compensate with attitude control thrusters", "por_que": "It recovers orientation immediately, but each correction burns fuel."},
			{"texto": "Recalibrate with the stars and pause the science", "por_que": "It saves fuel, but stops the instruments for several hours."},
			{"texto": "Let it drift for a few hours and correct later", "por_que": "It seems to cost nothing, but the drift reduces solar input and heats up the cabin."},
		],
	},
	"N10_panel_atascado": {
		"tema": "Electrical generation",
		"texto": "One of the solar panels is stuck half-deployed and produces only part of the power.",
		"opciones": [
			{"texto": "Shake it loose with gentle ship maneuvers", "por_que": "It may free it, but the vibrations fatigue the structure."},
			{"texto": "Operate with a single panel and reduce loads", "por_que": "It is safe and burns no fuel, but electricity becomes the scarcest resource."},
			{"texto": "Reorient the ship to make better use of the remaining panel", "por_que": "It makes up for part of the loss, but compromises the antenna's orientation."},
		],
	},
	"N11_humo": {
		"tema": "Fire safety",
		"texto": "It smells of burnt plastic. Smoke is coming from a panel behind Leo's console.",
		"opciones": [
			{"texto": "Cut the panel's power and use the extinguisher", "por_que": "It puts out the source in seconds, but the extinguisher fouls the air and the loss of power costs you."},
			{"texto": "Isolate the module and partially depressurize to smother the fire", "por_que": "Without oxygen the fire goes out, but you spend air and expose the crew."},
			{"texto": "Ventilate and filter the air without cutting the panel's power", "por_que": "You risk the fire reigniting, and the smoke saturates the filters."},
		],
	},
	"N12_sensor_o2": {
		"tema": "Environmental monitoring",
		"texto": "The two oxygen sensors give contradictory readings: one reads normal and the other reads a drop.",
		"opciones": [
			{"texto": "Trust the primary sensor", "por_que": "It is fast, but if the primary is wrong, you miss a real leak."},
			{"texto": "Verify with the physician's manual kit", "por_que": "It costs time, but settles the doubt with a third data point."},
			{"texto": "Recalibrate both sensors from the console", "por_que": "It can fix a calibration error, but cannot tell whether the leak is real."},
		],
	},
	"N13_refrigerante": {
		"tema": "Thermal control",
		"texto": "A coolant leak releases a sweet smell and floating droplets. The liquid is toxic.",
		"opciones": [
			{"texto": "Isolate the loop and switch to the backup circuit", "por_que": "It stops the contamination, but the backup circuit has less capacity."},
			{"texto": "Put on helmets and repair the leak on the fly", "por_que": "It solves the problem at the root if it goes well, but every second of exposure affects health."},
			{"texto": "Ventilate and filter the air with activated carbon", "por_que": "It cleans the air, but neither stops the leak nor protects against direct contact."},
		],
	},
	"N14_computadora": {
		"tema": "Flight computer",
		"texto": "The main flight computer restarts by itself and loses synchronization with the backup.",
		"opciones": [
			{"texto": "Full restart and reload of the configuration", "por_que": "It is clean, but erases recent data and leaves the ship without control for a few hours."},
			{"texto": "Switch to the backup computer", "por_que": "It is immediate, but you have no redundancy for the rest of the trip."},
			{"texto": "Manual guidance with support from Houston", "por_que": "It saves power, but depends on the link and overloads Elena."},
		],
	},
	"N15_ventana": {
		"tema": "Structural integrity",
		"texto": "A particle hits a cabin window and leaves a visible mark on the outer glass.",
		"opciones": [
			{"texto": "Inspect with light and camera, and cover the window", "por_que": "It costs science time and stress, but removes the doubt."},
			{"texto": "Leave it and monitor the pressure with an alarm", "por_que": "It saves time, but if the crack grows the reaction will come too late."},
			{"texto": "Reorient the ship to protect the window", "por_que": "It reduces exposure, but you burn fuel over a surface mark."},
		],
	},
	"N16_propelente": {
		"tema": "Propulsion",
		"texto": "A valve on the main propellant line shows an unexplained pressure drop.",
		"opciones": [
			{"texto": "Close the line and use the redundant line", "por_que": "It protects the fuel, but the secondary line has less capacity."},
			{"texto": "Repair the valve with the maintenance kit", "por_que": "It restores full redundancy, but a mistake could lose more propellant."},
			{"texto": "Use the remaining propellant in a useful maneuver right away", "por_que": "It avoids losing it to the leak, but you spend a margin you might need on the way back."},
		],
	},
	"N17_humedad": {
		"tema": "Thermal control and humidity",
		"texto": "Humidity is building up behind the avionics panels. There is a risk of small short circuits.",
		"opciones": [
			{"texto": "Increase ventilation in the area", "por_que": "It dries the area, but consumes power continuously."},
			{"texto": "Place desiccant in the panels", "por_que": "It is passive and cheap, but the desiccant saturates and cannot be replaced."},
			{"texto": "Lower the cabin temperature to reduce condensation", "por_que": "You attack the cause, but the cold stresses the crew and reduces performance."},
		],
	},
	"N18_motor_vibracion": {
		"tema": "Propulsion",
		"texto": "Before a maneuver, the main engine shows abnormal vibration in the diagnostics.",
		"opciones": [
			{"texto": "Postpone the maneuver and run diagnostics", "por_que": "It avoids a serious failure, but delaying the orbital window costs propellant."},
			{"texto": "Execute with reduced thrust and a longer burn", "por_que": "It reduces the risk of damage, but lengthens the burn and uses power."},
			{"texto": "Execute according to the original plan", "por_que": "If it's nothing serious, you save time. If it's real, the damage to the engine can be catastrophic."},
		],
	},
	"N19_ventiladores": {
		"tema": "Air quality",
		"texto": "A fan fails and pockets of CO₂ form in areas without circulation, where people sleep.",
		"opciones": [
			{"texto": "Restart the fan and move the crew members around", "por_que": "It is cheap, but disturbs rest and does not repair the fault."},
			{"texto": "Place portable fans at the dead spots", "por_que": "It solves the problem directly, but the extra power weighs on you if it is already scarce."},
			{"texto": "Sleep in short shifts in the center of the cabin", "por_que": "It costs nothing, but builds up fatigue and lowers performance."},
		],
	},
	"N20_agua_contaminada": {
		"tema": "Water quality",
		"texto": "An analysis detects a bacterial film in a drinking water tank.",
		"opciones": [
			{"texto": "Treat the tank with biocide", "por_que": "It saves the water, but the biocide must be dosed exactly."},
			{"texto": "Discard the contaminated tank", "por_que": "It is the safest for health, but you lose a significant part of the reserve."},
			{"texto": "Filter and boil before drinking", "por_que": "It reduces the risk, but consumes power and does not remove toxins."},
		],
	},
	"N21_bateria": {
		"tema": "Energy storage",
		"texto": "A battery cell shows abnormal temperature and is losing capacity.",
		"opciones": [
			{"texto": "Isolate the cell and accept less capacity", "por_que": "It avoids the thermal risk, but you lose part of the electrical reserve."},
			{"texto": "Balance the load between cells", "por_que": "It saves the cell if it goes well, but costs science time and may overheat it."},
			{"texto": "Keep using it at full power until it fails", "por_que": "It seems to cost nothing until it fails: then it costs a lot."},
		],
	},
	"N22_inodoro": {
		"tema": "Hygiene systems",
		"texto": "The waste elimination system fails. Nobody wants to talk about the smell, but the air is starting to show it.",
		"opciones": [
			{"texto": "Repair it in pairs, at the expense of other tasks", "por_que": "It restores the system, but the repair takes time away from other priorities."},
			{"texto": "Use the contingency bags", "por_que": "It is immediate, but stress rises and the air gets heavier."},
			{"texto": "Cannibalize a part from another system", "por_que": "It solves the problem, but removes redundancy from something that could fail later."},
		],
	},
	"N23_falsa_alarma": {
		"tema": "Emergency response",
		"texto": "The depressurization alarm sounds, but the sensors show no drop in pressure. A false alarm?",
		"opciones": [
			{"texto": "React as if it were real: helmets and isolate", "por_que": "You are never wrong for being cautious, but you stress everyone out over nothing."},
			{"texto": "Verify manually with the kit while everyone gets ready", "por_que": "It balances speed and accuracy, but takes a few key minutes."},
			{"texto": "Silence the alarm and watch the data", "por_que": "If it was false, nothing happened. If not, you lost critical minutes."},
		],
	},
	"N24_star_tracker": {
		"tema": "Navigation",
		"texto": "The star tracker is blinded by sunlight glare and navigation loses accuracy.",
		"opciones": [
			{"texto": "Reorient to recover the star view", "por_que": "It keeps navigation accurate, but burns fuel."},
			{"texto": "Navigate on the inertial unit alone for a few hours", "por_que": "It saves fuel, but drift accumulates and forces a larger correction."},
			{"texto": "Ask Houston for an adjustment", "por_que": "It is quick and reassuring, but depends on the link and uses bandwidth."},
		],
	},
	"N25_rcs": {
		"tema": "Propulsion",
		"texto": "A slow leak in a group of attitude thrusters loses propellant at a steady rate.",
		"opciones": [
			{"texto": "Shut down the affected group", "por_que": "It stops the loss, but you will have less maneuvering capacity."},
			{"texto": "Patch the line with sealant", "por_que": "It keeps the thrusters, but the patch may not withstand the maneuvers."},
			{"texto": "Spend the remaining propellant on a useful correction", "por_que": "It makes use of what would be lost, but reduces the reserve for the return."},
		],
	},
	"N26_dosis": {
		"tema": "Space radiation",
		"texto": "Leo's dosimeter shows a high accumulated dose after many hours in the least shielded area.",
		"opciones": [
			{"texto": "Reduce his time in that area and reorganize tasks", "por_que": "It protects his long-term health, but delays his work and frustrates him."},
			{"texto": "Temporarily move him to the shielded center of the cabin", "por_que": "It is simple, but takes up space that others need."},
			{"texto": "Accept the risk to finish the collection", "por_que": "More science now, but his health may degrade before reentry."},
		],
	},
	"N27_escotilla": {
		"tema": "Structural integrity",
		"texto": "The cargo module hatch does not seal completely and whistles slightly when pressurizing.",
		"opciones": [
			{"texto": "Repair the seal and pressurize again", "por_que": "It restores the seal, but costs time and some oxygen."},
			{"texto": "Apply sealant and partially pressurize", "por_que": "It is quick, but the improvised seal may give way."},
			{"texto": "Close the hatch and do not use the cargo module", "por_que": "It removes the risk, but you lose access to part of the scientific equipment."},
		],
	},
	"N28_ruido_instrumento": {
		"tema": "Scientific instrumentation",
		"texto": "The spectrometer starts producing data with electrical noise that could invalidate the measurements.",
		"opciones": [
			{"texto": "Recalibrate with the full sequence", "por_que": "It recovers clean data, but costs time and memory."},
			{"texto": "Turn the instrument off and resume later", "por_que": "It saves power, but delays the science and frustrates Leo."},
			{"texto": "Filter the noise in software and keep measuring", "por_que": "You keep the mission going, but a badly tuned filter can hide real data."},
		],
	},
	"N29_carga_suelta": {
		"tema": "Flight dynamics",
		"texto": "The sample containers come loose and the center of mass shifts, affecting attitude control.",
		"opciones": [
			{"texto": "Restow the cargo calmly", "por_que": "It sorts out the problem at the root, but takes up working time."},
			{"texto": "Compensate with the thrusters and leave it as is", "por_que": "It is quick, but burns fuel for the rest of the trip."},
			{"texto": "Jettison part of the less valuable cargo", "por_que": "It lowers the mass, but you lose science and anger Leo."},
		],
	},
	"N30_hielo_linea": {
		"tema": "Thermal control",
		"texto": "A water line freezes near the radiator. The flow drops and the system locks up.",
		"opciones": [
			{"texto": "Heat the line with resistors", "por_que": "It works if there is power, but spends electricity in the middle of the cold."},
			{"texto": "Drain the line and store the water in bags", "por_que": "It avoids pipe rupture, but you lose water and complicate logistics."},
			{"texto": "Wait for it to thaw with the cabin's heat", "por_que": "It costs nothing, but a frozen line can burst as it expands."},
		],
	},
	"H01_insercion": {
		"tema": "Orbital insertion (liftoff)",
		"texto": "The Orion capsule reaches low Earth orbit. Leo Okafor wants to turn on the spectrometers right away to calibrate data before the translunar injection; Marcus Chen warns that the initial battery drain is risky.",
		"opciones": [
			{"texto": "Prioritize life support and navigation systems", "descripcion": "Wait to stabilize the solar panels before turning on scientific instruments.", "por_que": "Thermal and power stabilization after launch is critical before activating payloads (NASA Artemis Flight Rules)."},
			{"texto": "Turn on all sensors at maximum power", "descripcion": "Humor Leo to start the science from the very first minute.", "por_que": "The power demand peak overloads the fuel cells before the panels are fully deployed."},
		],
	},
	"H04_cruce_lunar": {
		"tema": "Trajectory correction (lunar crossing)",
		"texto": "The ship enters the Moon's gravitational sphere of influence. Elena Marín must perform an engine burn to align the orbit.",
		"opciones": [
			{"texto": "Computer-calculated burn", "descripcion": "Trust the automated telemetry even if it takes 2 more hours of adjustment.", "por_que": "Automated low-acceleration maneuvers optimize propellant and reduce structural fatigue on the hull."},
			{"texto": "Aggressive manual maneuver", "descripcion": "Force the main thrusters to save time.", "por_que": "Excessive manual thrust causes unnecessary vibrations and wastes critical return reserves."},
		],
	},
	"H08_muestreo": {
		"tema": "Sampling in low orbit (scientific dilemma)",
		"texto": "They fly over the lunar south pole. Leo asks to extend the spectral and regolith collection by 3 hours; the cabin oxygen is right at the margin.",
		"opciones": [
			{"texto": "Collection within a safe window", "descripcion": "Take only the priority samples and close the hatches on time.", "por_que": "Meeting the activity time limits guarantees the reserve margin for the return burn."},
			{"texto": "Extend the operation to the limit", "descripcion": "Stay until the sensor batteries are drained.", "por_que": "Exceeding the operating windows leaves the crew with no margin for emergencies on the way back."},
		],
	},
	"H10_retorno": {
		"tema": "Return burn (point of no return)",
		"texto": "It is time to leave lunar orbit. Elena checks the ship's four bars. If water, food or oxygen are below 25 % (or Marcus is critical), the computer warns: excessive mass for the return trajectory with the current reserves.",
		"opciones": [
			{"texto": "Perform the nominal return burn", "descripcion": "Fire the main engine following the exact orbital window.", "por_que": "The free-return trajectory uses Earth's gravity to minimize the use of resources."},
			{"texto": "Speed up consumption to arrive sooner", "descripcion": "Push life support systems to the maximum to shorten check times.", "por_que": "It is not possible to mechanically shorten the translunar transit without compromising the integrity of the heat shield."},
			{"texto": "Abort the science payload", "descripcion": "Drop the sample module to lighten the load and prioritize the crew's survival. Leads to the Middle Ending.", "por_que": "With reserves in the red, lightening the ship is the only way to complete the return with the crew alive."},
		],
	},
	"H14_reentrada": {
		"tema": "The heavy air and reentry",
		"texto": "Hours before entering Earth's atmosphere, the lithium hydroxide filters (scrubbers) that clean the carbon dioxide are completely saturated. The air turns heavy; everyone suffers headaches and blurred vision.",
		"opciones": [
			{"texto": "Rotate backup cartridges and absolute rest", "descripcion": "Install the last emergency filters and order calm breathing with no physical activity.", "por_que": "Reducing the metabolic rate lowers CO2 exhalation while the reserve filters stabilize the cabin."},
			{"texto": "Keep up physical activity and intense maneuvers without changing filters", "descripcion": "Keep operating at maximum breathing rate.", "por_que": "CO2 buildup causes acute poisoning, loss of vision and death by asphyxia."},
		],
	},
}
