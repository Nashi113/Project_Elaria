class_name MainGame
extends Node

## Referensi ke container scene dunia saat ini
@onready var world_container: Node2D = $WorldContainer

## Map pembuka saat game pertama kali dijalankan
@export_file("*.tscn") var starting_map_path: String = "res://scenes/world/elaria_village.tscn"
@export var starting_spawn_id: String = "village_start"

func _ready() -> void:
	print("========================================")
	print("      PROJECT ELARIA — GODOT 4.x        ")
	print("   Milestone 3: World & Map Exploration ")
	print("========================================")
	
	# Daftarkan diri ke WorldManager
	WorldManager.main_game = self
	
	# Bersihkan child lama jika ada di WorldContainer (seperti test scene lama)
	for child in world_container.get_children():
		child.queue_free()
	
	# Muat map awal Elaria Village
	load_world(starting_map_path, starting_spawn_id)

## Memuat map baru ke dalam WorldContainer
func load_world(map_path: String, spawn_id: String) -> void:
	# Hapus map lama yang sedang aktif
	for child in world_container.get_children():
		child.queue_free()
	
	# Muat dan instansiasi scene map baru
	var map_res: PackedScene = load(map_path)
	if not map_res:
		push_error("[MainGame] Gagal memuat map: %s" % map_path)
		return
	
	var map_instance: Node2D = map_res.instantiate()
	world_container.add_child(map_instance)
	print("[MainGame] Map aktif berhasil diganti menjadi: %s" % map_path)
