class_name NPC
extends StaticBody2D

# ==============================================================================
# PROPERTI YANG BISA DIATUR DI EDITOR GODOT
# ==============================================================================
## Nama yang ditampilkan dalam kotak dialog
@export var npc_name: String = "NPC"

## Data dialog NPC (Resource DialogueData yang berisi array DialogueLine)
@export var dialogue: DialogueData = null

## Arah hadap NPC saat diam (default: menghadap ke bawah / ke arah pemain)
@export var default_facing: Vector2i = Vector2i.DOWN

## Tekstur sprite visual untuk NPC
@export var npc_sprite_texture: Texture2D = null

## Nama animasi idle yang akan diputar (contoh: "idle_down")
@export var idle_animation: String = "idle_down"

# ==============================================================================
# REFERENSI NODE
# ==============================================================================
@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_area: Area2D = $InteractionArea

# ==============================================================================
# VARIABEL INTERNAL
# ==============================================================================
## Referensi ke Player yang saat ini berada di dalam interaction area
var _player_in_range: Player = null
## Apakah NPC ini sedang dalam interaksi aktif (mencegah double-trigger)
var _is_interacting: bool = false

func _ready() -> void:
	# Terapkan tekstur sprite jika diekspor
	if npc_sprite_texture and sprite:
		sprite.texture = npc_sprite_texture

	# NPC adalah StaticBody2D: layer 1, mask 0 (tidak perlu mendeteksi collision sendiri)
	collision_layer = 1
	collision_mask = 0

	# Hubungkan sinyal interaction_area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	# Hanya proses input interaksi jika player ada dalam jangkauan
	if not _player_in_range:
		return
	# Jika player sedang bergerak, jangan izinkan interaksi
	if _player_in_range.is_moving:
		return

	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_try_interact()

## Mencoba memulai interaksi dengan NPC
func _try_interact() -> void:
	if _is_interacting:
		return
	if not _player_in_range:
		return
	if not dialogue or dialogue.lines.is_empty():
		return

	# Pastikan player menghadap NPC ini (bukan NPC di sebelah yang berbeda)
	if not _player_is_facing_this_npc():
		return

	_is_interacting = true

	# Kunci gerakan player selama dialog berlangsung
	_player_in_range.input_enabled = false

	# Temukan DialogueUI di scene tree dan buka dialog
	var dialogue_ui: DialogueUI = _find_dialogue_ui()
	if dialogue_ui:
		dialogue_ui.dialogue_closed.connect(_on_dialogue_closed, CONNECT_ONE_SHOT)
		dialogue_ui.open_dialogue(dialogue.lines)
	else:
		push_warning("[NPC] '%s': DialogueUI tidak ditemukan di scene tree!" % npc_name)
		_is_interacting = false
		if _player_in_range:
			_player_in_range.input_enabled = true

## Memeriksa apakah player menghadap ke arah NPC ini
func _player_is_facing_this_npc() -> bool:
	if not _player_in_range:
		return false

	# Hitung vektor dari player ke NPC
	var to_npc: Vector2 = global_position - _player_in_range.global_position
	var facing: Vector2i = _player_in_range.facing_direction

	# Jika jarak sangat dekat, arah hadap player ke arah NPC memiliki dot product > 0.1
	var dot: float = Vector2(facing).dot(to_npc.normalized())
	return dot > 0.1

## Mencari node DialogueUI yang aktif di scene tree
func _find_dialogue_ui() -> DialogueUI:
	# 1. Coba cari di group "DialogueUI" terlebih dahulu
	var ui_nodes = get_tree().get_nodes_in_group("DialogueUI")
	if not ui_nodes.is_empty() and ui_nodes[0] is DialogueUI:
		return ui_nodes[0] as DialogueUI

	# 2. Cari dari scene tree root
	var current: Node = self
	while current:
		for child in current.get_children():
			if child is DialogueUI:
				return child as DialogueUI
		current = current.get_parent()

	# 3. Cari dari root viewport
	return get_tree().root.find_child("DialogueUI", true, false) as DialogueUI

## Dipanggil saat dialog selesai dan ditutup
func _on_dialogue_closed() -> void:
	_is_interacting = false
	if _player_in_range:
		_player_in_range.input_enabled = true

## Dipanggil saat Player memasuki InteractionArea
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = body as Player

## Dipanggil saat Player keluar dari InteractionArea
func _on_body_exited(body: Node2D) -> void:
	if body is Player and body == _player_in_range:
		_player_in_range = null
