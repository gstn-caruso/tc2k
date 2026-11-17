# Plan del juego

Este documento registra la propuesta conversada para desarrollar un juego de
carreras **3D con estética PSX**, inspirado visualmente en los arcades de carreras
de los años 90 y con referencias del TC2000. Se juega con **teclado de PC**.
Las tareas pendientes no describen funcionalidades ya
implementadas; las decisiones indicadas como propuestas quedan abiertas a ajustes.

## Base del proyecto

- Godot 4.7.2 con GDScript, renderer Compatibility y una presentación arcade.
- Mundo, auto, relieve, cámara y colisiones en 3D; menús y HUD en 2D.
- Teclado como control principal, con cambios automáticos.
- Un solo auto disponible por ahora.
- Ya existen el título, el selector de circuito y la selección guardada en
  `RaceSetup`.
- Tres pistas seleccionadas: Gálvez 8, Cabalén 3 y El Zonda.
- Mantener la interfaz con i18n nativo de Godot, idioma del SO y español como
  respaldo, con catálogo adicional en inglés. Centralizar los textos en
  `assets/i18n/messages.csv`.

## Referencia e identidad

El TC2000 histórico significa Turismo Competición 2000 y es una categoría
distinta del Turismo Carretera. Nació con un torneo presentación en 1979 y tuvo
su primer campeonato argentino en 1980.

Como ambientación se propone fines de los años 80 y principios de los 90, con
la Renault Fuego de competición como referencia histórica y visual para el auto.
La Fuego ganó ocho campeonatos consecutivos entre 1986 y 1993, seis con
Juan María Traverso.

La época, el nombre definitivo del juego y el diseño concreto del auto quedan
por definir. Esta referencia histórica no presupone una licencia para usar
marcas, logos o recursos ajenos.

## Primera versión propuesta

Modo contrarreloj de tres vueltas, centrado en aprender el circuito y mejorar
los tiempos con un solo auto.

| Elemento | Comportamiento propuesto |
| --- | --- |
| Objetivo | Conseguir el mejor tiempo total y la mejor vuelta. |
| Cámara | Cámara 3D elevada y oblicua, con seguimiento del auto y perspectiva. |
| Controles | Teclado: WASD o flechas; cambios automáticos. |
| Largada | Cuenta regresiva de tres segundos. |
| Fuera del asfalto | Menor velocidad y agarre. |
| Choques | Pérdida de velocidad y una respuesta visual o sonora clara. |
| Atajos | Puntos de control obligatorios para validar cada vuelta. |
| Pantalla | Velocidad, vuelta actual, cronómetro y mejor tiempo. |
| Resultado | Tiempo total, mejor vuelta y opción de reintentar. |
| Progreso | Récord independiente para cada pista. |

## Manejo propuesto

- Frenar antes de doblar: entrar demasiado rápido debe hacer que el auto abra
  la trayectoria y pierda la curva.
- Aprovechar el ancho de la pista: entrar desde afuera, acercarse al interior
  de la curva y abrirse al salir.
- Acelerar a la salida: una buena salida debe beneficiar la velocidad en la
  recta siguiente.
- Conservar algo de inercia al soltar el acelerador y cambiar de dirección.
- Probar una tendencia moderada al subviraje como decisión de diseño: al
  exceder el agarre, el auto gira menos de lo que pide el jugador.

La prioridad es que completar una vuelta limpia resulte entretenido y que el
jugador pueda reconocer dónde gana o pierde tiempo.

## Teclado e InputMap

El recorrido completo, desde el título hasta reintentar una carrera, debe poder
hacerse sin mouse ni mando. Las siguientes asignaciones son la propuesta inicial:

| Acción | Teclas | Acción de Godot |
| --- | --- | --- |
| Acelerar | W o ↑ | `drive_accelerate` |
| Frenar | S o ↓ | `drive_brake` |
| Girar a la izquierda | A o ← | `drive_left` |
| Girar a la derecha | D o → | `drive_right` |
| Pausar / reanudar la carrera | Esc | `race_pause` |
| Reubicar el auto en el último punto seguro | R | `car_reset` |
| Avanzar desde el título / confirmar / reintentar | Enter | `menu_confirm` |
| Recorrer las opciones del selector | ← / → | `menu_left` / `menu_right` |
| Volver desde el selector o un menú | Esc | `menu_back` |

Registrar acciones en InputMap y separar los controles de conducción de los de
menú. Configurar WASD por posición física (`physical_keycode`) y ofrecer también
las flechas. [Teclas físicas](https://docs.godotengine.org/en/stable/classes/class_inputeventkey.html#class-inputeventkey-property-physical-keycode).
Leer la conducción continuamente en `_physics_process()`; usar
`Input.get_axis("drive_left", "drive_right")` para la intención de giro y
aproximar progresivamente la dirección aplicada. Soltar una tecla debe devolver
el volante gradualmente al centro. El ángulo máximo de dirección disminuye con
la velocidad; no se supone un joystick analógico.

Leer acelerador y freno por separado; al pulsar ambos, dar prioridad al freno.
S actúa como freno en el prototipo. Evitar combinar aceleración y dirección con
`Input.get_vector()`, cuya normalización cambiaría la respuesta al acelerar y
doblar juntos. Detectar pausa y reposición como pulsaciones únicas, ignorando
la repetición automática de teclas. R restaura un punto seguro, neutraliza
velocidad y dirección e invalida la vuelta actual para récords.

`RaceController` habilita la conducción únicamente en el estado de carrera.
Consumir un evento de menú no bloquea las consultas globales de `Input`, por lo
que esta condición debe existir también en el controlador del auto. La pausa
detiene física y cronómetro, pero deja operable el menú con el teclado. Pausar
también al perder el foco de la ventana para que el auto no siga acelerando.
Ver [Input](https://docs.godotengine.org/en/stable/classes/class_input.html) y
[eventos frente a lectura continua](https://docs.godotengine.org/en/stable/tutorials/inputs/input_examples.html).

## Estructura propuesta en Godot

Agregar una escena de carrera independiente y conservar las pantallas actuales:

```text
Race (Control)
├── View3D (SubViewportContainer)
│   └── WorldViewport (SubViewport)
│       └── World (Node3D)
│           ├── Track (instancia del circuito)
│           │   ├── Sectors
│           │   ├── Collisions
│           │   ├── Spawn (Marker3D)
│           │   └── Checkpoints (Area3D)
│           ├── Car (CharacterBody3D)
│           ├── CameraRig (Node3D)
│           │   └── Camera3D
│           ├── DirectionalLight3D
│           └── WorldEnvironment
├── RaceController (Node)
└── HUD (CanvasLayer)
```

- `RaceController`: largada, estados de carrera, vueltas, cronómetro y resultados.
- `Car`: movimiento, agarre, frenado y respuesta a choques.
- `Track`: geometría, superficies, largada y puntos de control.
- `HUD`: presenta datos de carrera y textos traducibles, a partir de señales.
- `RaceSetup`: conserva el identificador elegido entre pantallas, sin guardar
  referencias a nodos 3D que pueden liberarse al reiniciar.

Al conectar `RaceSetup.track_confirmed(track_id)` con la carrera, hacer una
transición diferida a la nueva escena y resolver el circuito por su ID estable:
`galvez_8`, `cabalen_3` o `el_zonda`. Un recurso `TrackDefinition` puede asociar
cada ID con su `PackedScene` y los datos de pista. Cada reinicio crea una sesión
de carrera limpia; los récords se guardan separadamente por ID.

### Auto arcade

La primera propuesta usa `CharacterBody3D` con una colisión sencilla y movimiento
propio: velocidad longitudinal, deriva lateral, aceleración, frenado y agarre.
Implementar gravedad, detección de suelo y `floor_snap_length`, y mover mediante
`move_and_slide()` en pasos de física. Los parámetros ajustables se agrupan en
un recurso `CarTuning`. La carrocería y las ruedas son hijos visuales del cuerpo.
[CharacterBody3D](https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html).

El controlador aplica las diferencias entre asfalto y pasto; el agarre no queda
delegado a la fricción de un material físico. Probar una pendiente suave antes
de desarrollar el relieve de El Zonda. Si el prototipo demuestra que hace falta
una suspensión física más compleja, revisar el uso de `RigidBody3D` y su
integración de fuerzas. `VehicleBody3D` no es una dependencia inicial, dadas sus
limitaciones documentadas. [VehicleBody3D](https://docs.godotengine.org/en/stable/classes/class_vehiclebody3d.html).

### Cámara 3D

La vista superior propuesta se concreta como una cámara elevada y oblicua con
perspectiva: debe mostrar el relieve y permitir anticipar las curvas. Exponer
altura, inclinación, distancia y anticipación por velocidad en el inspector.
Suavizar el seguimiento y conservar el horizonte estable, sin copiar cada
oscilación de la carrocería. Comparar una vista de persecución durante las
pruebas del primer circuito antes de fijar el encuadre definitivo.

Si hay obstáculos que pueden tapar la cámara, incorporar `SpringArm3D` y excluir
la colisión del propio auto de su comprobación.
[SpringArm3D](https://docs.godotengine.org/en/stable/classes/class_springarm3d.html).

## Construcción de los circuitos 3D

Diseñar una línea central continua y mantener sectores separados para editar.
Acordar una escala de trabajo de una unidad por metro. Los SVG del selector
orientan la forma en planta; la anchura y las alturas deben definirse al
construir la pista.

Para el prototipo, se propone editar la línea central mediante `Path3D` y
`Curve3D` y generar asfalto, banquinas y colisión en el editor con un script
`@tool`. `SurfaceTool` o `ArrayMesh` permiten construir esa geometría a partir
de los puntos de la curva. Se sigue diseñando el trazado, pero no hace falta
modelar cada polígono. Hornear la geometría cuando se edita, sin reconstruirla
en cada frame de carrera. La ruta es una referencia del circuito, no un riel que
controle el movimiento del auto.
[Path3D](https://docs.godotengine.org/en/stable/classes/class_path3d.html),
[SurfaceTool](https://docs.godotengine.org/en/stable/classes/class_surfacetool.html).

Blender es otra opción para la pista y sigue siendo útil para el auto, edificios
y piezas de escenografía. Si se usa, mantener el trazado completo y el relieve
en un archivo de trabajo, con sectores separados; verificar orientación y
escala al importar.

En el flujo Blender, exportar `.glb` y usar una escena `.tscn` propia como contenedor para scripts,
superficies y checkpoints. Así, reexportar la geometría conserva la lógica
agregada en Godot. Separar tres niveles de escenario:

- Pista transitable: asfalto, banquinas, curvas y pendientes con colisión continua.
- Decoración cercana: guardarraíles, carteles, árboles y tribunas reutilizables.
- Fondo: siluetas de montañas o ciudad, con geometría más simple y sin colisiones
  cuando el auto no puede alcanzarlas.

Usar `StaticBody3D` para el entorno estático y colisiones simplificadas separadas
del detalle visual. El importador admite mallas dedicadas con el sufijo
`-colonly`. Comprobar uniones entre sectores para que las ruedas no salten al
pasar por ellas. [Importación de colisiones](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/node_type_customization.html).

Comenzar con el circuito completo en memoria. Compartir materiales y usar
`MultiMeshInstance3D` por sector cuando haya muchas repeticiones de árboles o
postes; su visibilidad se decide como conjunto. Introducir carga por sectores o
LOD adicional solo si el perfilado del circuito lo justifica.
[MultiMesh](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html).

## Presentación PSX

- Mantener Compatibility como base y comprobar los efectos en ese renderer.
- Usar siluetas de pocos polígonos, texturas pequeñas y materiales compartidos.
  Empezar con `StandardMaterial3D`, colores pintados o iluminación por vértice.
- Probar filtro nearest con mipmaps, especialmente en asfalto y superficies
  vistas a distancia. [Materiales y filtros](https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html).
- Probar el mundo 3D en un `SubViewport` de 640×480 y comparar 320×240 como opción
  visual. Ampliarlo con filtrado nearest y conservar la proporción; dibujar el
  HUD aparte para que sus textos sean legibles. Configurar el tamaño del viewport
  junto con el comportamiento de su contenedor: con `stretch` activado, el
  contenedor controla ese tamaño. [SubViewport](https://docs.godotengine.org/en/stable/classes/class_subviewport.html).
- Usar una luz principal, ambientación sencilla y niebla común para integrar el
  fondo. Ajustar el alcance de cámara y niebla al tamaño de cada escenario.
  [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html).
- Dejar temblor de vértices, dithering y deformación de texturas como efectos
  opcionales posteriores. Actúan sobre la imagen y las mallas visuales; no deben
  deformar colisiones ni dificultar la lectura de curvas y distancias.

## Circuitos y progresión

Las dificultades son una propuesta para el juego, no una clasificación oficial.

| Circuito | Dificultad | Aprendizaje | Tratamiento propuesto |
| --- | --- | --- | --- |
| Oscar y Juan Gálvez, circuito 8 | Fácil | Frenar y acelerar después de curvas lentas. | Referencias visuales claras y conducción accesible. |
| Oscar Cabalén, circuito 3 | Media | Combinar sectores rápidos y lentos. | Cambios de ritmo y precisión al encadenar curvas. |
| El Zonda–Eduardo Copello | Difícil | Concentración y control cerca de los límites. | Muros próximos y menos margen para corregir errores. |

## Hitos de implementación propuestos

La primera entrega jugable debe permitir completar una vuelta en Gálvez con
geometría básica, antes de terminar el arte o construir los otros dos circuitos.

| Hito pendiente | Criterio para darlo por terminado |
| --- | --- |
| Auto y pista de pruebas | Teclado, aceleración, frenado, giro progresivo, pasto, pendiente y choques controlables. |
| Primera vuelta en Gálvez | Se entra desde el selector, se recorre un trazado cerrado, se registra una vuelta válida y se puede reintentar. |
| Contrarreloj completo | Largada, tres vueltas, HUD, resultados y récord independiente por circuito. |
| Sector visual terminado | Un sector fija materiales, resolución, iluminación y decoración que se puedan repetir. |
| Cabalén y El Zonda | Comparten controlador y reglas; sus trazados, relieves y dificultad quedan ajustados. |

## Criterios de validación

- Validar checkpoints ordenados y cruce de meta en la dirección correcta.
  Probar cruces en sentido contrario, atajos y cruces repetidos para que no
  regalen vueltas.
- Comprobar choques y paso por checkpoints a la máxima velocidad del prototipo.
- Comprobar que reiniciar o reubicar el auto no conserve velocidad incorrecta ni
  duplique un cruce de meta. La reposición no debe permitir saltar checkpoints.
- Probar WASD y flechas, W+A/D, W+S, A+D, soltar la dirección en plena curva,
  pérdida de foco, pausa y regreso a menús, sin necesitar mouse.
- Comparar el manejo a 30, 60 y 144 FPS de renderizado, manteniendo constante la
  frecuencia de física. El cronómetro no debe avanzar durante la pausa.
- Revisar cámara, texturas, sombras, relieve y legibilidad en una build exportada
  de Linux y otra de Windows, además de las pruebas headless de lógica.
- Al conectar la carrera, actualizar `tests/smoke.gd`: hoy verifica que confirmar
  deja al usuario en el selector. La nueva prueba debe comprobar la pista 3D
  cargada y conservar las verificaciones de navegación del título y selector.
- Mantener feature branches, PRs, i18n y releases SemVer con `.deb` y `.exe`
  después de cada merge a `main`.

## Posibles ampliaciones

- Rivales controlados por la computadora; pueden compartir el mismo modelo de
  auto si se mantiene un solo auto disponible.
- Clasificación para determinar posiciones de largada.
- Campeonato con puntos acumulados entre fechas.
- Boxes y carreras especiales inspiradas en los 200 Kilómetros de Buenos Aires,
  con estrategia y relevos.

## Fuentes de referencia

- [Historia oficial del TC2000](https://tc2000.com.ar/institucional.php?accion=historia):
  orígenes, evolución técnica y etapas de la categoría.
- [Estadísticas históricas oficiales](https://tc2000.com.ar/estadisticas.php?accion=historicas):
  pilotos, autos y campeonatos como referencias para futuras ampliaciones.
- [Gálvez, circuito 8](https://pilotosdeprimera.com/2024/04/09/pernia-el-circuito-n8-tiene-sus-secretos/):
  curvas lentas y relevancia de la tracción.
- [Cabalén en competición virtual](https://admin.carburando.com/notas/se-viene-el-estreno-del-oscar-cabalen-virtual):
  combinación de sectores rápidos y lentos.
- [Características de El Zonda](https://visionauto.com.ar/tecnologia-ingenieria-performance-para-el-tc2000-en-el-zonda/):
  desniveles, curvas ciegas y exigencia de precisión.
- [Historia de los 200 Kilómetros](https://campeones.com.ar/200-km-de-tc2000-datos-historicos-de-la-esperada-carrera-en-buenos-aires/):
  referencia para un futuro modo de carreras especiales.
