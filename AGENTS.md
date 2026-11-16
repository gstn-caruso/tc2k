# Convenciones del proyecto

## Git

- Trabajar en ramas `feature/<nombre-descriptivo>`.
- Subir los cambios a la feature branch e integrarlos a `main` mediante pull requests.
- No hacer commits ni pushes directamente sobre `main`.

## Interfaz e idiomas

- Usar el sistema nativo de i18n de Godot para toda la interfaz.
- El español (`es`) es el idioma principal de autoría y de respaldo.
- Al iniciar, usar el idioma del sistema operativo: español o inglés según
  corresponda. Para idiomas sin traducción, usar español. Por ahora no hay
  selector manual ni preferencias guardadas de idioma.
- Escribir primero los textos en español; mantener también el catálogo en inglés.
- Centralizar los textos visibles en `assets/i18n/messages.csv`, incluidos botones,
  menús, mensajes de error, ayudas y textos dinámicos.
- Usar claves estables en inglés, como `WELCOME`, y `tr()` desde GDScript.
  En propiedades traducibles de escenas, usar las claves con la traducción
  automática de Godot. Los nombres propios, como TC2K, conservan su nombre.
- Mantener los identificadores de código y de datos independientes del idioma.
- Al cambiar el catálogo, reimportarlo con Godot y versionar los archivos
  `.translation` actualizados junto con el CSV.

## Flujo inicial

- El título muestra Turismo Carretera 2K con la bandera argentina y espera Enter.
- La segunda pantalla selecciona el circuito con las flechas izquierda y derecha.
- Enter confirma la pista; Esc vuelve al título. No agregar avances automáticos.
- Circuitos: Oscar y Juan Gálvez, circuito 8 (baja); Oscar Cabalén, circuito 3
  (media); El Zonda–Eduardo Copello (alta).
