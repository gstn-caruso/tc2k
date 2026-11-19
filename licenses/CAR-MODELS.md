# Renault Fuego

Modelo aportado por el usuario desde
`Models/autos/tc2000/renault_fuego/Fuego_Traverso_TC2000_Game.glb`,
copiado sin modificar como `assets/cars/renault_fuego/fuego.glb`. El proyecto
editable y los generadores permanecen en la carpeta Models de origen.

Incluye la decoración blanca y amarilla de Traverso, con los logotipos adaptados
al atlas original de 1024 × 1024 incorporado en el GLB. Son cinco mallas
(carrocería y cuatro ruedas), un material y 2316 triángulos, en metros.

El frente del GLB apunta a +Z. `scenes/cars/renault_fuego.tscn` gira el modelo
180° para que el frente apunte a -Z, como el controlador del juego. El origen
queda al nivel del suelo. Las ruedas conservan sus pivotes originales, con
radio de 0,31 m; la dirección y la rodadura se animan por separado.

# Ford Sierra XR4

Modelo de Tito Bessone, TC2000 1987 n.º 5, creado para el usuario en
`Models/autos/tc2000/ford_sierra_xr4/Sierra_Bessone_TC2000_Game.glb`,
copiado sin modificar como `assets/cars/ford_sierra_xr4/sierra.glb`.
El Blender editable, los generadores y las referencias permanecen en Models.

Cinco mallas, un material, atlas incrustado de 1024 × 1024 y 2300 triángulos,
en metros. La decoración blanca y roja incluye Eveready, Energizer y Grupo
Juncal, con letras adaptadas a la textura de baja resolución. Las imágenes de
referencia no se utilizan como texturas del modelo.

Las medidas base proceden de [Ford Sierra Net](https://fordsierranet.com.ar/Medidas.htm)
y la decoración, de la [foto de Revista Corsa publicada por F1-Web](https://www.f1-web.com.ar/postersierrabessone.htm).
La altura de carrera y los detalles sin vistas completas son aproximados.

El GLB apunta a +Z; `scenes/cars/ford_sierra_xr4.tscn` lo gira 180° para apuntar
a -Z como el resto del juego. Conserva el tamaño real, el origen al suelo y
los cuatro pivotes de rueda, con radio de 0,30 m. Usa la animación de ruedas
compartida por los otros autos y los mismos controles y parámetros de conducción.

# Volkswagen Gol, Peugeot 405, Honda Civic Coupé y Chevrolet Astra

Modelos aportados por el usuario desde `Models/autos/tc2000/`, copiados sin
modificar con su atlas de decoración original incrustado:

| Auto / decoración | GLB de origen | Destino en `assets/cars/` | Triángulos | Radio de rueda |
| --- | --- | --- | --- | --- |
| Volkswagen Gol / Guillermo Maldonado, 1994 n.º 3 | `volkswagen_gol/Gol_Maldonado_TC2000_Game.glb` | `volkswagen_gol/gol.glb` | 2004 | 0,30 m |
| Peugeot 405 / Juan María Traverso, 1995 n.º 8 | `peugeot_405/405_Traverso_TC2000_Game.glb` | `peugeot_405/405.glb` | 2048 | 0,31 m |
| Honda Civic Coupé / Omar Martínez, 1998 n.º 7 | `honda_civic/Civic_Martinez_TC2000_Game.glb` | `honda_civic/civic.glb` | 2024 | 0,31 m |
| Chevrolet Astra / Matías Rossi, 2006 n.º 8 | `chevrolet_astra/Astra_Rossi_TC2000_Game.glb` | `chevrolet_astra/astra.glb` | 2048 | 0,325 m |

Cada GLB contiene cinco mallas (`Body` y `Wheel_FL/FR/RL/RR`), un material y un
atlas de 1024 × 1024 sin dependencias externas. Los `.blend`, generadores,
referencias y validaciones permanecen en la carpeta Models de origen. Son
interpretaciones arcade: dimensiones de carrera, logotipos y calcos secundarios
están simplificados. Las referencias no se incorporan como texturas.

Las escenas contenedoras giran el modelo 180° para que el frente apunte a -Z.
Se conserva la escala en metros, el origen al suelo y los pivotes de los bujes.
El Gol conserva su largo de aproximadamente 3,98 m. Los seis autos importados
comparten `scripts/cars/imported_visual.gd` para registrar y animar sus ruedas,
con el radio propio de cada modelo y la misma conducción arcade del juego.

Referencias registradas en los `asset_info.json` originales:

- Gol: [Carburando](https://www.carburando.com/notas/una-historia-llena-de-grandes-campeones)
  y [Autocosmos](https://noticias.autocosmos.cl/2021/03/12/comienza-el-super-tc2000-en-argentina-la-gran-competencia-de-marcas).
- 405: [Automundo](https://automundo.com.ar/flaco-traverso-1995-turismo-carretera-tc2000/)
  y [TyC Sports](https://www.tycsports.com/al-angulo/juan-maria-traverso-doble-corona-turismo-carretera-tc2000-1995-id583952.html).
- Civic: [Carburando](https://www.carburando.com/notas/honda-regresa-para-seguir-sumando-logros-su-historial)
  y [referencia visual](https://leivag1991vehicles.blogspot.com/2018/07/honda-civic-vi-versiones-de-competicion.html).
- Astra: [Carburando](https://www.carburando.com/notas/uno-por-uno-los-autos-con-los-que-rossi-se-consagro-campeon-del-tc2000)
  y [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:TC2000_Chevrolet_Elaion_2006_Chevrolet_Astra.jpg).
