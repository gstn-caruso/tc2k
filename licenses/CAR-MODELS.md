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
