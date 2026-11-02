extends Area3D

# La posición de los pies, no el volumen de la cápsula, decide la llegada.
func puede_completar(jugador) -> bool:
	if jugador.muerto or jugador.nivel_completado or not jugador.is_on_floor():
		return false
	var pies: Vector3 = to_local(jugador.global_position)
	return absf(pies.x) <= 1.5 and absf(pies.z) <= 1.0 and absf(pies.y - 0.05) <= 0.12
