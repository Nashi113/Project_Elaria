class_name TestWorld
extends Node2D

@onready var player: Player = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var grid_pos_label: Label = $HUD/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/GridPosLabel
@onready var facing_label: Label = $HUD/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/FacingLabel
@onready var status_label: Label = $HUD/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/StatusLabel

func _ready() -> void:
	if spawn_point and player:
		player.position = spawn_point.position
	
	if player:
		player.step_started.connect(_on_player_step_started)
		player.step_finished.connect(_on_player_step_finished)
		player.movement_blocked.connect(_on_player_movement_blocked)
		player.direction_changed.connect(_on_player_direction_changed)
		_update_hud(player.get_grid_position(), player.facing_direction, "Diam (Idle)")
	
	print("[TestWorld] Milestone 2 siap diuji. Gerakan grid 16px aktif.")

func _on_player_step_started(dir: Vector2i, _target_pos: Vector2) -> void:
	_update_hud(player.get_grid_position(), dir, "Melangkah...")

func _on_player_step_finished(new_grid_pos: Vector2i) -> void:
	_update_hud(new_grid_pos, player.facing_direction, "Selesai Melangkah (Snapped)")

func _on_player_movement_blocked(blocked_pos: Vector2i) -> void:
	_update_hud(player.get_grid_position(), player.facing_direction, "Terhalang di (%d, %d)!" % [blocked_pos.x, blocked_pos.y])

func _on_player_direction_changed(new_dir: Vector2i) -> void:
	_update_hud(player.get_grid_position(), new_dir, "Ubah Arah")

func _update_hud(grid_pos: Vector2i, facing: Vector2i, state_str: String) -> void:
	if grid_pos_label:
		grid_pos_label.text = "Grid: (%d, %d)" % [grid_pos.x, grid_pos.y]
	if facing_label:
		var dir_name: String = "Bawah"
		match facing:
			Vector2i.UP: dir_name = "Atas"
			Vector2i.DOWN: dir_name = "Bawah"
			Vector2i.LEFT: dir_name = "Kiri"
			Vector2i.RIGHT: dir_name = "Kanan"
		facing_label.text = "Arah: %s" % dir_name
	if status_label:
		status_label.text = "Status: %s" % state_str
