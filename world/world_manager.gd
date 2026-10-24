extends Node

## Sinyal yang dipancarkan ketika transisi peta dimulai
signal map_transition_started(dest_path: String, spawn_id: String)
## Sinyal yang dipancarkan ketika transisi peta selesai
signal map_transition_completed(current_path: String)

## Status apakah transisi sedang berlangsung (mencegah trigger ganda)
var is_transitioning: bool = false

## Path map yang sedang aktif saat ini
var current_map_path: String = ""

## ID spawn yang ditargetkan untuk map berikutnya
var target_spawn_id: String = ""

## Referensi ke scene root MainGame (jika ada)
var main_game: Node = null

## Referensi ke Player yang sedang aktif
var active_player: Player = null

## Node visual untuk efek transisi layar hitam (fade in / fade out)
var fade_canvas: CanvasLayer = null
var fade_rect: ColorRect = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_fade_overlay()
	print("[WorldManager] Sistem World & Map Manager diinisialisasi.")

## Membuat overlay hitam untuk efek fade layar tanpa membutuhkan aset eksternal
func _create_fade_overlay() -> void:
	fade_canvas = CanvasLayer.new()
	fade_canvas.layer = 100 # Di atas seluruh layer game dan HUD
	add_child(fade_canvas)
	
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0.05, 0.06, 0.08, 1.0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.modulate.a = 0.0 # Transparan di awal
	fade_canvas.add_child(fade_rect)

## Memulai perpindahan antar map
func transition_to_map(destination_path: String, spawn_id: String) -> void:
	if is_transitioning:
		return
	
	is_transitioning = true
	target_spawn_id = spawn_id
	map_transition_started.emit(destination_path, spawn_id)
	
	# 1. Kunci pergerakan pemain agar tidak dapat bergerak saat layar menggelap
	if active_player:
		active_player.input_enabled = false
	
	# 2. Fade Out ke hitam
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	# 3. Muat scene map baru
	if main_game and main_game.has_method("load_world"):
		main_game.load_world(destination_path, spawn_id)
	else:
		# Fallback jika scene dijalankan langsung dari editor (F6)
		current_map_path = destination_path
		get_tree().change_scene_to_file(destination_path)
	
	# Tunggu 2 frame agar scene baru siap dan terpasang sempurna di SceneTree
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 4. Fade In dari hitam kembali ke tampilan game
	var fade_in_tween: Tween = create_tween()
	fade_in_tween.tween_property(fade_rect, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade_in_tween.finished
	
	# 5. Buka kembali kontrol pemain
	if active_player:
		active_player.input_enabled = true
	
	is_transitioning = false
	map_transition_completed.emit(destination_path)
	print("[WorldManager] Transisi selesai ke: %s (Spawn: %s)" % [destination_path, spawn_id])

## Fungsi konfigurasi yang dipanggil oleh setiap scene peta saat _ready()
func setup_map_environment(map_node: Node2D, map_pixel_bounds: Vector2i, default_spawn_id: String) -> void:
	current_map_path = map_node.scene_file_path
	
	# Cari player di dalam peta (bisa di dalam YSortActors atau root map)
	var player_node: Player = map_node.get_node_or_null("YSortActors/Player")
	if not player_node:
		player_node = map_node.get_node_or_null("Player")
	
	if player_node:
		active_player = player_node
		
		# Tentukan spawn ID yang akan dipakai
		var active_spawn: String = target_spawn_id if not target_spawn_id.is_empty() else default_spawn_id
		
		# Cari Marker2D di node SpawnPoints
		var spawn_points: Node = map_node.get_node_or_null("SpawnPoints")
		if spawn_points:
			var target_marker: Marker2D = spawn_points.get_node_or_null(active_spawn)
			if target_marker:
				player_node.teleport_to_position(target_marker.position)
				print("[WorldManager] Pemain ditempatkan di spawn point: %s (Pos: %s)" % [active_spawn, str(target_marker.position)])
			else:
				push_warning("[WorldManager] Spawn point '%s' tidak ditemukan! Menggunakan spawn default pertama." % active_spawn)
				if spawn_points.get_child_count() > 0:
					player_node.teleport_to_position(spawn_points.get_child(0).position)
		
		# Set batas kamera map
		player_node.set_camera_limits(0, 0, map_pixel_bounds.x, map_pixel_bounds.y)
	
	# Reset target spawn
	target_spawn_id = ""
