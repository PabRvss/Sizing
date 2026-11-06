class_name Moneda
extends Area3D

@export var nivel: int = 1

static var monedas_recogidas: Dictionary = {
	1: false,
	2: false,
	3: false,
	4: false,
	5: false
}

var tiempo: float = 0.0
var recogiendo: bool = false
var audio_stream: AudioStreamWAV

@onready var pivote: Node3D = $Pivote
@onready var sonido: AudioStreamPlayer = $Sonido

static func esta_recogida(n: int) -> bool:
	return monedas_recogidas.get(n, false)

static func marcar_recogida(n: int) -> void:
	monedas_recogidas[n] = true

static func total_recogidas() -> int:
	var total := 0
	for v in monedas_recogidas.values():
		if v:
			total += 1
	return total

func _ready() -> void:
	collision_layer = 0
	collision_mask = 4 # Detecta al jugador
	
	if esta_recogida(nivel):
		queue_free()
		return
		
	body_entered.connect(_on_body_entered)
	_generar_audio()

func _generar_audio() -> void:
	audio_stream = AudioStreamWAV.new()
	audio_stream.format = AudioStreamWAV.FORMAT_16_BITS
	audio_stream.mix_rate = 22050
	audio_stream.stereo = false
	
	var sample_count := int(0.25 * 22050)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / 22050.0
		var freq: float = 987.77 if t < 0.08 else 1318.51
		var env: float = exp(-t * 11.0)
		var sample: int = int(sin(t * freq * TAU) * env * 24000.0)
		data.encode_s16(i * 2, sample)
	audio_stream.data = data
	sonido.stream = audio_stream

func _process(delta: float) -> void:
	tiempo += delta
	if not recogiendo:
		pivote.rotation.y += 3.0 * delta
		pivote.position.y = sin(tiempo * 3.5) * 0.12
	else:
		pivote.rotation.y += 15.0 * delta
		pivote.position.y += 3.0 * delta
		var escala_actual = pivote.scale.x - 3.0 * delta
		if escala_actual <= 0.05:
			pivote.hide()
			if not sonido.playing:
				queue_free()
		else:
			pivote.scale = Vector3.ONE * escala_actual

func _on_body_entered(body: Node3D) -> void:
	if recogiendo:
		return
	if body.name == "Player" or body is CharacterBody3D:
		recogiendo = true
		marcar_recogida(nivel)
		sonido.play()
		if body.has_method("notificar_coleccionable"):
			body.notificar_coleccionable(nivel)
