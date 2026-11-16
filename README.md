# TC2K

Proyecto inicial de Godot 4.7.2 con GDScript y renderizador Compatibility.

## Ejecutar

Importá `project.godot` desde Godot 4.7.2 y presioná **F6** para ejecutar la
escena abierta o **F5** para iniciar el proyecto. La escena principal es
`scenes/main.tscn`.

La interfaz incluye español e inglés. Los textos están en
`assets/i18n/messages.csv`; la preferencia de idioma se guarda en
`user://settings.cfg`, separada de futuras partidas.

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
