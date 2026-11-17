# Miniaturas de circuitos

Las miniaturas SVG en `assets/tracks/` son adaptaciones de los trazados siguientes.
Se conservó la geometría de la pista, se aislaron los caminos, se cambió su color
a blanco y se omitieron las anotaciones para componer las miniaturas del juego.
Los relieves y colores de terreno de la pantalla son ilustrativos.

- `galvez_8.svg`: Gustavo Girardelli, a partir de datos de los colaboradores de
  OpenStreetMap. [Original](https://commons.wikimedia.org/wiki/File:Aut%C3%B3dromo_Oscar_y_Juan_G%C3%A1lvez_Circuito_N%C2%B0_8.svg).
  La adaptación conserva la licencia [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
- `cabalen_3.svg`: Gustavo Girardelli y colaboradores de OpenStreetMap.
  [Original](https://commons.wikimedia.org/wiki/File:Aut%C3%B3dromo_Oscar_Cabal%C3%A9n.svg).
  La adaptación conserva la licencia [CC BY-SA 2.0](https://creativecommons.org/licenses/by-sa/2.0/).
- `el_zonda.svg`: Will Pittenger.
  [Original](https://commons.wikimedia.org/wiki/File:Aut%C3%B3dromo_Eduardo_Copello_(Argentina)_track_map.svg).
  La adaptación conserva la licencia [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/).

Los datos de OpenStreetMap se ofrecen bajo [ODbL](https://www.openstreetmap.org/copyright).
Estas licencias se aplican a las miniaturas correspondientes, separadamente de
la licencia del código y de los demás recursos del proyecto.

## Trazado 3D de Gálvez 8

`assets/tracks/galvez_8/centerline.tres` es una adaptación trazada a mano de
`galvez_8.svg`, de Gustavo Girardelli y colaboradores de OpenStreetMap. La curva
y las superficies de pista derivadas en `scenes/race/galvez_8.tscn` conservan
[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). Se suavizó la
línea central, se eligió una escala y anchura de prototipo y se generaron asfalto,
banquinas y guardarraíles. Las alturas y la escenografía son ilustrativas; no
representan un levantamiento ni una reproducción exacta del autódromo.
La licencia de esta adaptación es independiente de la del código del juego.

## Trazado 3D de Cabalén 3

`assets/tracks/cabalen_3/centerline.tres` adapta a mano el recorrido del circuito
3 del mapa `cabalen_3.svg`, de Gustavo Girardelli y colaboradores de OpenStreetMap.
La curva y las superficies derivadas en `scenes/race/cabalen_3.tscn` conservan
[CC BY-SA 2.0](https://creativecommons.org/licenses/by-sa/2.0/). Se seleccionó
el recorrido largo, se suavizó la línea central y se ajustó a unos 4045 metros;
las anchuras, alturas y escenografía son de prototipo. El recorrido y la longitud
se contrastaron con el [plano de TC2000 de 2017](https://www.tc2000.com.ar/archivos/carp-prev-tc2000-cordoba-2017.pdf).
No es un relevamiento topográfico. La licencia de la adaptación es independiente
de la del código del juego.

## Trazado 3D de El Zonda

`assets/tracks/el_zonda/centerline.tres` adapta a mano `el_zonda.svg`, de
Will Pittenger. La curva y las superficies derivadas en `scenes/race/el_zonda.tscn`
conservan [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/).
Se suavizó la línea central, se eligieron escala y anchura de prototipo y se
agregaron pendientes y una separación de ocho metros en el cruce del rulo.
Las alturas, el puente y los cerros son ilustrativos; no representan un
relevamiento ni una reproducción exacta del autódromo. La licencia de la
adaptación es independiente de la del código del juego.
