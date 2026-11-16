# TC2K

Proyecto inicial de Godot 4.7.2 con GDScript y renderizador Compatibility.

## Ejecutar

Importá `project.godot` desde Godot 4.7.2 y presioná **F6** para ejecutar la
escena abierta o **F5** para iniciar el proyecto. `scenes/main.tscn` muestra el
título Turismo Carretera 2K con la bandera argentina y espera **Enter**.
Después aparece `scenes/track_selection.tscn`: **← / →** recorren las pistas,
**Enter** confirma la elección y **Esc** regresa al título. El circuito elegido
queda en `RaceSetup`, con un identificador estable y una señal de confirmación.

Los circuitos son Oscar y Juan Gálvez, circuito 8 (baja), Oscar Cabalén,
circuito 3 (media), y El Zonda–Eduardo Copello (alta). Las miniaturas conservan
las formas de los mapas de referencia; los detalles de terreno son ilustrativos.

La composición conserva la proporción 4:3 al redimensionar la ventana. Se puede
recorrer las opciones también después de confirmar para cambiar la elección.

La interfaz usa i18n nativo de Godot y toma el idioma del sistema operativo al
iniciar. Incluye español e inglés; los demás idiomas usan español como respaldo.
No se muestra un selector manual ni se leen preferencias antiguas de idioma.
Los textos están en `assets/i18n/messages.csv` y las convenciones en `AGENTS.md`.

## Estructura

- `scenes/`: escenas del proyecto.
- `scripts/`: código GDScript.
- `assets/`: recursos y traducciones.
- `tests/`: comprobaciones del proyecto.
- `tools/`: instalación del motor, verificaciones y exportación.

## Verificaciones y exportación

Se necesita Python 3.10 o posterior. Estos comandos descargan el editor oficial
y la plantilla Linux, verificando sus sumas SHA-512:

```bash
python3 tools/install_godot.py
export GODOT="$HOME/.cache/godot-release/4.7.2/godot"
export GODOT_RELEASE_TEMPLATE="$HOME/.cache/godot-release/4.7.2/linux_release.x86_64"
python3 -m unittest discover -s tools -p 'test_*.py'
python3 tools/check.py
python3 tools/build_release.py --version 0.1.0
```

La exportación crea un ZIP para Linux x86_64 en `build/` y comprueba que el
ejecutable arranque. Los archivos generados, las credenciales y la caché de
Godot quedan fuera del repositorio. Los archivos `.uid`, `.import` y las
traducciones `.translation` se versionan para permitir una primera importación
sin referencias faltantes.

## GitHub

Repositorio privado: <https://github.com/gstn-caruso/tc2k>.

Las pull requests ejecutan las verificaciones y una exportación Linux. Usá
títulos de [Conventional Commits](https://www.conventionalcommits.org/):
`feat: ...`, `fix: ...`, `docs: ...`. Los cambios `feat`, `fix`, `perf`, `revert`
y los cambios incompatibles que llegan a `main` generan versiones SemVer y una
release con el ZIP y sus checksums. `chore`, `docs` y `ci` no generan releases.

No se ha seleccionado una licencia para el proyecto. Las licencias del motor
y sus dependencias se conservan por separado; ver `THIRD_PARTY_NOTICES.md`.
