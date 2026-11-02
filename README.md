# Sizing - Hito 2

Proyecto de videojuego desarrollado en **Godot 4**.

Avance del **Hito 2**: intercambio de tamaños, cinco niveles conectados, robot con animaciones y rifle, pantallas de victoria y derrota, metas unificadas y créditos de los modelos utilizados.

## Mecánicas
- **Movimiento y Plataformeo:** Movimiento en 3D con cámara aérea rotable usando las flechas izquierda y derecha.
- **Mecánica de Cambio de Tamaño:**
  - **Click Izquierdo (Láser):** Mantener presionado para apuntar a un objeto intercambiable y transferir tamaños.
  - **Tecla E:** Intercambio rápido con el objeto más cercano.
  - El personaje debe estar quieto sobre el suelo y sin obstáculos en la línea de visión directa.
  - Comprobación del volumen del personaje para evitar crecer dentro de techos, paredes o cajas.
- **Nivel 1 y Nivel 2:** Superación de obstáculos y plataformas con suelo de lava.
- **Nivel 3 — El paso estrecho:** Encogerse para atravesar un túnel de 1,15 unidades y crecer al otro lado para alcanzar una salida de 1,9 unidades.
- **Nivel 4 — Fabrica tu escalón:** El jugador comienza con tamaño 2. Desde el carril derecho de la entrada puede ver y agrandar la caja amarilla; después recupera tamaño 1 con la caja violeta del patio. El paso tiene 2,05 unidades de altura, por lo que solo permite cruzar pequeño o normal. Detrás se sube por un recorrido lateral: apoyo de 0,8, apoyo de 1,6, caja agrandada de 2,5 y salida de 3,4 unidades. La caja pequeña no sirve para completar ese salto, y ser pequeño no permite subir el primer apoyo.
- **Nivel 5 — El circuito de lava:** Conserva el túnel y el salto grande hasta la isla elevada. En esa isla repite el puzle del nivel 4, con la caja amarilla visible y la caja normal situada antes del paso. Desde la salida elevada se salta una separación de 2 unidades hasta una isla final ancha y a la misma altura. La meta de este nivel termina la campaña.
- **Pantalla de muerte:** Al caer al vacío o a la lava, el juego se detiene y permite elegir entre **Reaparecer** (reinicia el nivel y sus cajas) y **Volver al menú principal**. Se puede elegir con el ratón o con teclado. Escape no cierra esta pantalla.
- **Modelos 3D:** El personaje usa el robot blanco de BlendSwap y lleva una carabina del paquete Sci-fi - Low Poly - Guns. Su armadura adopta una postura de reposo y anima brazos y piernas al caminar y saltar; el rifle sigue la mano derecha. El rayo sale de la boca del rifle. Consulta los créditos y licencias en `assets/ATTRIBUTION.md`.

Los niveles se recorren en orden con el botón **Siguiente Nivel**. También puedes abrir `level_3.tscn`, `level_4.tscn` o `level_5.tscn` en Godot y ejecutar la escena actual con **F6**.

Las cinco metas usan la misma escena `goal.tscn`, una placa verde de 3 × 2 unidades. Para completar un nivel, el personaje debe estar vivo, apoyado en el suelo y con sus pies dentro de esa placa; sirve cualquier tamaño. Rozarla con la cabeza, pasar por encima en el aire o morir no activa la victoria. Una vez completado, se bloquean sus controles y aparece el mismo panel de victoria. El nivel 5 termina la campaña.

Las escenas de los niveles nuevos son editables en Godot. `tools/build_levels.py` permite regenerarlas desde sus medidas originales; al ejecutarlo se reemplazan las escenas de los niveles 3 a 5. Para regenerar solo los niveles rediseñados, ejecuta `python tools/build_levels.py 4 5`.

## Controles
- `W, A, S, D`: Movimiento
- `Espacio`: Saltar
- `Click Izquierdo`: Láser de intercambio de tamaño
- `E`: Intercambiar con objeto cercano
- `Flecha Izquierda / Derecha`: Rotar cámara
- `R`: Reiniciar nivel actual
- `Escape`: Menú de pausa
