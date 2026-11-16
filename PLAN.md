# Plan del juego

Este documento registra la propuesta conversada para desarrollar un juego simple
inspirado en el TC2000. Las tareas pendientes no describen funcionalidades ya
implementadas; las decisiones indicadas como propuestas quedan abiertas a ajustes.

## Base del proyecto

- Godot con GDScript y una presentación arcade.
- Un solo auto disponible por ahora.
- Ya existen el título, el selector de circuito y la selección guardada en
  `RaceSetup`.
- Tres pistas seleccionadas: Gálvez 8, Cabalén 3 y El Zonda.
- Mantener la interfaz con i18n nativo de Godot, español como idioma principal
  y catálogo en inglés. Centralizar los textos en `assets/i18n/messages.csv`.

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
| Cámara | Vista desde arriba, siguiendo al auto. |
| Controles | Acelerar, frenar, izquierda y derecha; cambios automáticos. |
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

## Circuitos y progresión

Las dificultades son una propuesta para el juego, no una clasificación oficial.

| Circuito | Dificultad | Aprendizaje | Tratamiento propuesto |
| --- | --- | --- | --- |
| Oscar y Juan Gálvez, circuito 8 | Fácil | Frenar y acelerar después de curvas lentas. | Referencias visuales claras y conducción accesible. |
| Oscar Cabalén, circuito 3 | Media | Combinar sectores rápidos y lentos. | Cambios de ritmo y precisión al encadenar curvas. |
| El Zonda–Eduardo Copello | Difícil | Concentración y control cerca de los límites. | Muros próximos y menos margen para corregir errores. |

## Orden de implementación propuesto

- [ ] Crear el auto controlable y ajustar el manejo en una pista de prueba.
- [ ] Incorporar la cámara y las superficies de asfalto y fuera de pista.
- [ ] Conectar la selección existente con el circuito jugable.
- [ ] Implementar colisiones y la respuesta a los choques.
- [ ] Agregar largada, cronómetro, puntos de control y conteo de vueltas.
- [ ] Mostrar la información de carrera y los resultados con opción de reintento.
- [ ] Guardar los récords por circuito.
- [ ] Completar las tres pistas y ajustar su progresión de dificultad.

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
