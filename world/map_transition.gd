class_name MapTransition
extends Area2D

## Jalur berkas scene tujuan (misal: "res://scenes/world/whispering_forest.tscn")
@export_file("*.tscn") var destination_map_path: String = ""

## ID titik spawn di map tujuan (misal: "forest_from_village" atau "village_from_forest")
@export var destination_spawn_id: String = ""

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 # Mendeteksi player (Layer 1)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if destination_map_path.is_empty():
			push_warning("[MapTransition] destination_map_path belum dikonfigurasi pada: %s" % name)
			return
		
		# Panggil WorldManager untuk memulai proses transisi
		WorldManager.transition_to_map(destination_map_path, destination_spawn_id)
