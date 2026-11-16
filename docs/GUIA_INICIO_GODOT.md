# Guía del proyecto — MYG-351: Last Signal

Guía para entender cómo está armado el juego, abrirlo en Godot y cambiar cosas sin romper nada.

---

## 1. Cómo se juega (el recorrido de pantallas)

```
Menú  →  Prólogo  →  Fase 0 (suministros)  →  Despegue  →  Misión (14 días)  →  Final
```

Cada día de la misión sigue este ciclo:

```
Órdenes del día → Consumo → Aviso → Decisión 1 → (Minijuego) → Resultado
						  → Aviso → Decisión 2 → Resultado → Fin del día
```

- **Decisión 1**: un momento clave de la historia (días 1, 4, 8, 10 y 14) o una emergencia de la nave.
- **Minijuego**: solo en las emergencias, cuando eliges un procedimiento válido. Tú haces la reparación y eso cambia el resultado.
- **Decisión 2**: una decisión de recursos (no hay en el día 1).

## 2. Mapa de archivos

| Pantalla | Escena | Script | Quién lo hizo |
|---|---|---|---|
| Menú principal | `scenes/main_menu.tscn` | `srcipts/MainMenu.gd` | Camilo |
| Prólogo (4 páginas) | `scenes/intro.tscn` | `srcipts/Intro.gd` | Camilo |
| Fase 0: suministros | `scenes/shop.tscn` | `srcipts/Shop.gd` | Giovanny (rediseñada en 3 pasos) |
| Despegue | `scenes/despegue.tscn` | `srcipts/Despegue.gd` | Camilo |
| Misión | `scenes/mission.tscn` | `srcipts/MisionVisual.gd` | Camilo (pantalla) |
| Minijuegos | (dentro de la misión) | `srcipts/Minijuego.gd` | Camilo |
| Finales | `scenes/final.tscn` | `srcipts/Final.gd` | Camilo |

Scripts que no son pantallas:

| Script | Qué hace |
|---|---|
| `srcipts/GameManager.gd` | **Las reglas del juego** (Giovanny): recursos, tripulación, días, finales y puntaje. Es un Autoload: se usa como `GameManager.algo` desde cualquier parte. |
| `srcipts/Eventos.gd` | **Las 60 decisiones y los 5 momentos clave** (Giovanny). También Autoload. |
| `srcipts/Estilo.gd` | Colores, fuente, paneles, botones, iconos, retratos y animaciones que comparten todas las pantallas. |
| `srcipts/FondoEspacio.gd` | Estrellas que se mueven y planetas que giran. |
| `srcipts/Memos.gd` | Los Memos NASA y sus enlaces (salen del Storytelling). |
| `srcipts/Sonido.gd` | Música y efectos. Autoload: `Sonido.efecto("alarma")`. |
| `srcipts/Mission.gd` | La versión antigua de la misión, solo texto. **Ya no se usa**, queda de referencia. |

> ⚠️ La carpeta se llama `srcipts` (con la letra cambiada). **No la renombres**: Godot guarda las rutas y se romperían las escenas.

> ℹ️ Casi todas las escenas `.tscn` están casi vacías: el script arma la pantalla por código al arrancar. Por eso en el editor se ven en blanco y solo se llenan al ejecutar.

## 3. Abrir y ejecutar el proyecto

1. Usa **la misma versión de Godot que el equipo**: 4.7.2 (la normal, no la ".NET").
2. Administrador de proyectos → **Importar** → carpeta del proyecto → `project.godot`.
3. **F5** ejecuta el juego desde el menú. **F6** ejecuta solo la escena que tengas abierta.
4. Los errores salen en rojo en la pestaña **Salida** (abajo).

Las escenas de misión y final necesitan que exista una partida, así que para verlas bien usa F5 y juega hasta llegar.

## 4. Trabajar con git

```bash
git pull origin main
```
```bash
git status
```
```bash
git add srcipts/MainMenu.gd
```
```bash
git commit -m "Lo que cambiaste"
```
```bash
git push
```

- Antes de cambiar de rama, haz commit de lo tuyo.
- Godot toca solo algunos archivos `.import` y `project.godot` al abrir el proyecto (saltos de línea). Si no los cambiaste tú, no los subas.

## 5. Recetas: cómo cambiar cada cosa

**Un texto de una pantalla.** Abre el script de esa pantalla (tabla de arriba), busca el texto con Ctrl+F y cámbialo.

**Un color o el tamaño de la letra.** Están todos juntos al inicio de `srcipts/Estilo.gd` (`C_CIAN`, `C_VERDE`...). La fuente pixel-art se ve nítida solo en tamaños múltiplos de 8 (16, 24, 32, 48).

**Un dibujo (sprite).** Guarda tu PNG con el **mismo nombre y tamaño** encima del que quieres cambiar:

| Carpeta | Qué hay | Tamaño |
|---|---|---|
| `assets/retratos/` | `elena_normal.png`, `elena_estresado.png`, `elena_herido.png`, `elena_critico.png`, `elena_perdido.png` (y lo mismo para marcus, sofia y leo) | 48×48 |
| `assets/iconos/` | iconos de recursos, estados y órdenes | 32×32 |
| `assets/nave/` | Orión, cápsula, paracaídas, cohete y torre | varios |
| `assets/finales/` | fondos de los finales y del despegue | 320×180 |
| `assets/ui/`, `assets/space/`, `scenes/TileMaps/2x/` | arte del equipo (botones, paneles, planetas, cabina) | — |

**Un sonido.** Reemplaza el `.wav` de `assets/audio/` por otro con el mismo nombre. Los actuales están hechos por síntesis: si consiguen sonidos reales, se notará la mejora.

**Un Memo NASA.** En `srcipts/Memos.gd`. `POR_ID` asigna un memo a una decisión concreta y `POR_TEMA` lo asigna por palabra del tema.

**Una decisión o sus efectos.** En `srcipts/Eventos.gd` (es de Giovanny: avísale).

**Los minijuegos.** En `srcipts/Minijuego.gd`:
- `DURACION` → cuántos segundos dura cada uno.
- `tipo_para(tema)` → qué minijuego le toca a cada tipo de emergencia.
- Cada minijuego tiene su función de dibujo (`_dibujar_sellar`, `_dibujar_alinear`, `_dibujar_secuencia`, `_dibujar_valvula`).

Cómo afecta al resultado: el minijuego devuelve una nota de −1 (falló) a 1 (perfecto). `GameManager` usa esa nota **en lugar del azar** al calcular el resultado de la decisión (variable `habilidad_manual`).

**La pantalla de la misión.** En `srcipts/MisionVisual.gd`. Las funciones `_construir_...` arman cada zona (barra de arriba, rieles, tripulación, centro) y las funciones `_mostrar_...` son las fases del día.

## 6. Regenerar el arte y el audio (opcional)

Los sprites y sonidos nuevos se generan con dos programas de Python que están en `tools/`:

```bash
python tools/generar_arte.py
```
```bash
python tools/generar_audio.py
```

Necesitan `pip install pillow numpy`. **Ojo:** al correrlos se vuelven a escribir todos los PNG y WAV generados. Si reemplazaste alguno a mano, guárdalo aparte antes.

## 7. Probar el juego automáticamente (opcional)

`tools/probar_juego.gd` juega una partida solo y guarda capturas. Sirve para comprobar que nada se rompió después de un cambio. Las instrucciones están al inicio de ese archivo.

## 8. Datos de la NASA que usa el juego

- Agua: 2,5 L para beber + 0,4 L de higiene por astronauta al día → 162,4 L para 4 personas y 14 días.
- Comida: 3.035 kcal por astronauta al día → 169.960 kcal.
- Referencias: [Crew Systems](https://www.nasa.gov/reference/crew-systems/) y [Habitability Functions Vol. 2](https://www.nasa.gov/reference/7-0-habit-ability-functions-vol-2/). Los demás enlaces están en `srcipts/Memos.gd` y en el botón "Referencias NASA" del menú.

## 9. Pendientes sugeridos

- [ ] Escuchar todos los sonidos y cambiar los que no gusten.
- [ ] Revisar el equilibrio: con el Paquete B la electricidad queda muy justa.
- [ ] Decidir qué hacer con `srcipts/sala_mando.tscn` y `scenes/ship_designer.tscn`, que hoy no se usan.
- [ ] Unir las ramas del equipo en `main` con un Pull Request.
