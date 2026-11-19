# TC2K

Juego de carreras 3D con estética PSX, Godot 4.7.2, GDScript y renderer Compatibility.

El alcance propuesto, las reglas de la primera versión y las tareas pendientes
están en [el plan del juego](PLAN.md).

## Ejecutar

Importá `project.godot` desde Godot 4.7.2 y presioná **F6** para ejecutar la
escena abierta o **F5** para iniciar el proyecto. `scenes/main.tscn` muestra el
título Turismo Carretera 2K con la bandera argentina y espera **Enter**.
Después aparece `scenes/track_selection.tscn`: **← / →** recorren las pistas,
**Enter** confirma el circuito y abre la selección de auto; **Esc** regresa al
título. En `scenes/car_selection.tscn`, **← / →** eligen el modelo con una
vista previa 3D giratoria, **Enter** abre la selección de modo y **Esc** vuelve
a los circuitos. En `scenes/mode_selection.tscn`, **← / →** eligen práctica
individual o competición, **Enter** inicia la partida y **Esc** vuelve a los
autos. Las selecciones se conservan durante la sesión. Los tres circuitos
tienen escenarios 3D jugables.

Se pueden elegir seis autos: **Renault Fuego** de Traverso,
**Ford Sierra XR4** de Bessone, **Volkswagen Gol** de Maldonado,
**Peugeot 405** de Traverso, **Honda Civic Coupé** de Martínez y **Chevrolet Astra**
de Rossi. El selector muestra el auto elegido en el centro de un carrusel de
tres tarjetas, junto a los modelos anterior y siguiente. Los seis modelos
importados conservan las decoraciones originales de la carpeta Models del
usuario; su procedencia y adaptación están documentadas en
`licenses/CAR-MODELS.md`. Los seis usan la misma conducción arcade y animan
la dirección y la rodadura de las ruedas. Los rivales CPU eligen los tres modelos
siguientes al del jugador, sin repetirlo. La selección se conserva al reintentar
y al volver a los circuitos durante la sesión.

Los circuitos son Oscar y Juan Gálvez, circuito 8 (baja), Oscar Cabalén,
circuito 3 (media), y El Zonda–Eduardo Copello (alta). Las miniaturas conservan
las formas de los mapas de referencia; los detalles de terreno son ilustrativos.

**Práctica individual** permite completar una vuelta contrarreloj: cuenta
regresiva, cronómetro, seguimiento continuo del recorrido, resultado, récord
local y reintento. **Competición** enfrenta al jugador con tres rivales CPU
en una carrera de una vuelta. Los rivales aceleran, frenan para las curvas y
buscan un carril libre para pasar autos lentos con la misma física y colisiones
que el jugador. Comparten la largada y la pausa; el HUD muestra la posición
y el minimapa identifica los cuatro autos. El resultado conserva el orden de
llegada. El reloj de competición arranca con la largada; el de práctica, al
cruzar la línea por primera vez. Solo la práctica guarda récords locales.
No hay puntos de paso obligatorios: se completa el circuito y se cruza la meta
en el sentido correcto, también por la banquina o el pasto. El auto tiene
aceleración y dirección progresivas, frenado, una reducción suave de velocidad
y agarre en el pasto y colisiones con los guardarraíles. Los choques entre autos
transfieren impulso con un rebote leve; los roces laterales conservan el avance.
Los edificios son arte de prototipo. Los trazados se basan en los mapas
atribuidos; la anchura y escenografía son aproximadas. Gálvez y Cabalén son
planos; El Zonda incorpora
pendientes suaves, el rulo con puente y un entorno árido con cerros. Sus alturas
son ilustrativas. Los récords son independientes por circuito. El modo de tres
vueltas sigue pendiente.

| Acción | Teclas |
| --- | --- |
| Acelerar / frenar | W / S o ↑ / ↓ |
| Girar | A / D o ← / → |
| Reubicar en el punto más cercano de la pista | R; invalida la vuelta para récords |
| Pausar / continuar | Esc; también se pausa al perder el foco |
| Menú de pausa | ↑ / ↓ y Enter: continuar, reintentar o cambiar pista |
| Resultado | Enter reintenta; Esc vuelve a los circuitos |

La carrera conserva la proporción 4:3. El mundo se dibuja a 640×480 y se amplía
con filtro nearest; el HUD se dibuja a la resolución de la ventana.
El HUD tiene instrumentos flotantes inspirados en los arcades de los 90:
cronómetro amarillo, velocímetro con escala curva, vuelta, récord y progreso
en verde. En competición, la posición reemplaza al récord. A la derecha muestra
los mandos en vivo (dirección y pedales) y el minimapa del circuito: el jugador
es el número 1 rojo y los rivales son 2, 3 y 4 en amarillo. Cuando van juntos,
los indicadores se separan con líneas hacia sus posiciones reales para que
ninguno quede oculto. La pausa y los resultados usan bordes a cuadros.

La interfaz usa i18n nativo de Godot y toma el idioma del sistema operativo al
iniciar. Incluye español e inglés; los demás idiomas usan español como respaldo.
No se muestra un selector manual ni se leen preferencias antiguas de idioma.
Los textos están en `assets/i18n/messages.csv` y las convenciones en `AGENTS.md`.

## Estructura

- `scenes/`: escenas del proyecto.
- `scripts/`: código GDScript; conducción, pista, cámara, vueltas y HUD en `scripts/race/`.
- `scenes/cars/` y `scripts/cars/`: modelos visuales compartidos entre el selector y la carrera.
- `assets/`: recursos y traducciones.
- `tests/`: comprobaciones del proyecto.
- `tools/`: instalación del motor, verificaciones y exportación.

## Editar los circuitos

Las líneas centrales editables están en `assets/tracks/<id>/centerline.tres`,
usadas por el `Path3D` de `scenes/race/<id>.tscn`: `galvez_8`, `cabalen_3` y `el_zonda`.
Las formas se trazaron a partir de las miniaturas atribuidas en
`licenses/TRACK-MAPS.md`. No son relevamientos topográficos.
Abrí la escena de la pista, editá la curva y usá **Bake track geometry** en el
inspector del nodo raíz. Guardá la escena; la malla y las colisiones quedan
horneadas y no se regeneran al jugar. Para reconstruirla desde la curva fuente:

```bash
"$GODOT" --headless --path . --script res://tools/bake_track.gd
"$GODOT" --headless --path . --script res://tools/bake_track.gd -- cabalen_3
"$GODOT" --headless --path . --script res://tools/bake_track.gd -- el_zonda
```

El horneado modifica la escena generada; guardá primero cualquier ajuste hecho
allí. `CarTuning` concentra los parámetros de conducción. Las pruebas de carrera
conducen vueltas físicas completas y verifican controles, colisiones, reglas,
minimapas y aislamiento de los récords entre pistas. En El Zonda comprueban
ambos niveles del puente y la recuperación desde la banquina en pendiente.

## Verificaciones y exportación

Se necesita Python 3.11 o posterior y `dpkg-deb`. Estos comandos descargan el
editor oficial y las plantillas Linux/Windows, verificando sus sumas SHA-512:

```bash
python3 tools/install_godot.py
export GODOT="$HOME/.cache/godot-release/4.7.2/godot"
export GODOT_RELEASE_TEMPLATE="$HOME/.cache/godot-release/4.7.2/linux_release.x86_64"
export GODOT_WINDOWS_RELEASE_TEMPLATE="$HOME/.cache/godot-release/4.7.2/windows_release_x86_64.exe"
python3 -m unittest discover -s tools -p 'test_*.py'
python3 tools/check.py
python3 tools/build_release.py --version 0.1.0
```

La exportación deja en `build/release/` un instalador `.deb` para Linux amd64,
un ejecutable `.exe` para Windows x86_64, ZIPs portables con licencias y
`SHA256SUMS.txt`. Comprueba el arranque Linux, extrae y ejecuta el paquete Debian
y valida el formato del ejecutable Windows. CI también lo ejecuta en Windows.
Los archivos generados, las credenciales y la caché de
Godot quedan fuera del repositorio. Los archivos `.uid`, `.import` y las
traducciones `.translation` se versionan para permitir una primera importación
sin referencias faltantes.

## GitHub

Repositorio privado: <https://github.com/gstn-caruso/tc2k>.

Las pull requests verifican el juego y exportan ambos sistemas. Usá
títulos de [Conventional Commits](https://www.conventionalcommits.org/):
`feat: ...`, `fix: ...`, `docs: ...`. Cada merge a `main` genera una release:

- Primera versión: `0.1.0`.
- `!` o `BREAKING CHANGE:`: incremento major, incluso antes de `1.0.0`.
- `feat`: incremento minor.
- Los demás cambios, incluidos `fix`, `docs`, `chore` y `ci`: incremento patch.

Los tags `vMAJOR.MINOR.PATCH` determinan la versión. Los reintentos reutilizan
el tag del mismo commit y conservan las releases publicadas. El flujo encola
los merges, verifica Linux y Windows y publica los artefactos con sus checksums
después de que todas las comprobaciones pasen. Los paquetes viajan entre runners
en cachés temporales con claves exclusivas de cada intento; la comprobación de
Windows exige recuperar exactamente el ZIP generado. Las cachés de paquetes de
`main` se eliminan después de publicar, sin depender de la cuota de artefactos
de Actions.

No se ha seleccionado una licencia para el proyecto. Las licencias del motor
y sus dependencias se conservan por separado; ver `THIRD_PARTY_NOTICES.md`.
