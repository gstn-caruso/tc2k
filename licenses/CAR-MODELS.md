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
