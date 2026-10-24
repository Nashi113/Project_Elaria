class_name Player
extends CharacterBody2D

## Sinyal yang dipancarkan saat pemain mulai melangkah ke tile berikutnya
signal step_started(direction: Vector2i, target_world_pos: Vector2)
## Sinyal yang dipancarkan saat langkah ke tile selesai dan posisi telah presisi
signal step_finished(new_grid_pos: Vector2i)
## Sinyal yang dipancarkan saat jalur terhalang rintangan
signal movement_blocked(blocked_grid_pos: Vector2i)
## Sinyal saat arah hadap pemain berubah
signal direction_changed(new_direction: Vector2i)

# ==============================================================================
# KONFIGURASI SISTEM GRID & KECEPATAN
# ==============================================================================
## Ukuran 1 grid cell dalam piksel (Standar RPG: 16x16)
@export var tile_size: int = 16

## Durasi yang dibutuhkan untuk melangkah 1 tile (dalam detik)
## Nilai 0.22s setara dengan kecepatan jalan klasik Pokemon
@export var step_duration: float = 0.22

# ==============================================================================
# REFERENSI NODE
# ==============================================================================
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var raycast: RayCast2D = $RayCast2D
@onready var camera: Camera2D = $Camera2D

# ==============================================================================
# STATE PEMAIN
# ==============================================================================
## Arah hadap saat ini (vektor grid integer: Vector2i.UP, DOWN, LEFT, RIGHT)
var facing_direction: Vector2i = Vector2i.DOWN

## Menandakan apakah input pergerakan pemain diaktifkan
var input_enabled: bool = true

## Menandakan apakah pemain sedang berada di tengah-tengah animasi melangkah
var is_moving: bool = false

## Progres pergerakan antar tile (0.0 = awal langkah, 1.0 = sampai tujuan)
var move_progress: float = 0.0

## Posisi awal langkah (koordinat dunia piksel)
var start_world_pos: Vector2 = Vector2.ZERO

## Posisi tujuan langkah (koordinat dunia piksel)
var target_world_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Pastikan input map terdaftar agar scene dapat diuji langsung
	_ensure_input_actions()
	
	# Konfigurasi RayCast2D
	if raycast:
		raycast.enabled = true
		raycast.target_position = Vector2(facing_direction) * float(tile_size)
		raycast.collide_with_areas = true
		raycast.collide_with_bodies = true
	
	# Lakukan snap posisi awal pemain ke pusat grid tile terdekat
	_snap_to_nearest_grid_center()
	
	# Mulai dengan animasi idle sesuai arah hadap
	_update_animation_idle()

func _physics_process(delta: float) -> void:
	if is_moving:
		# Lanjutkan interpolasi langkah yang sedang berlangsung
		_process_step(delta)
	else:
		# Jika sedang diam, baca input baru dari keyboard
		_process_idle_input()

## Menangani animasi dan pergeseran posisi selama langkah
func _process_step(delta: float) -> void:
	move_progress += delta / step_duration
	
	if move_progress >= 1.0:
		# Sisa delta jika ada (overflow) untuk disambungkan ke langkah berikutnya
		var overflow_delta: float = (move_progress - 1.0) * step_duration
		
		# Kunci posisi tepat di target (tanpa desimal melenceng)
		position = target_world_pos
		is_moving = false
		move_progress = 0.0
		
		# Pancarkan sinyal bahwa langkah selesai
		var current_grid: Vector2i = get_grid_position()
		step_finished.emit(current_grid)
		
		# Cek apakah pemain masih menahan tombol arah untuk langkah beruntun (continuous walking)
		var held_dir: Vector2i = _get_input_direction()
		if held_dir != Vector2i.ZERO:
			_attempt_step(held_dir, overflow_delta)
		else:
			_update_animation_idle()
	else:
		# Interpolasi halus (lerp) dari posisi awal ke posisi tujuan
		position = start_world_pos.lerp(target_world_pos, move_progress)

## Membaca input pemain saat tidak sedang melangkah
func _process_idle_input() -> void:
	if not input_enabled:
		_update_animation_idle()
		return
	
	var desired_direction: Vector2i = _get_input_direction()
	if desired_direction != Vector2i.ZERO:
		_attempt_step(desired_direction, 0.0)

## Mencoba melangkah ke arah yang diminta
func _attempt_step(dir: Vector2i, carryover_delta: float = 0.0) -> void:
	# Jika arah berubah, perbarui arah hadap pemain terlebih dahulu
	if facing_direction != dir:
		facing_direction = dir
		direction_changed.emit(facing_direction)
	
	# Periksa apakah tile di depan terhalang dinding atau rintangan
	if is_tile_blocked(dir):
		# Jika terhalang, tetap pada posisi sekarang dan tampilkan idle menghadap rintangan
		_update_animation_idle()
		var blocked_pos: Vector2i = get_grid_position() + dir
		movement_blocked.emit(blocked_pos)
		return
	
	# Jika jalur bersih, mulai proses melangkah 1 tile
	start_world_pos = position
	target_world_pos = position + Vector2(dir) * float(tile_size)
	is_moving = true
	move_progress = 0.0
	
	# Jalankan animasi berjalan
	_update_animation_walk()
	step_started.emit(dir, target_world_pos)
	
	# Jika ada sisa waktu dari langkah sebelumnya, terapkan langsung agar transisi mulus
	if carryover_delta > 0.0:
		move_progress = carryover_delta / step_duration
		position = start_world_pos.lerp(target_world_pos, move_progress)

## Memeriksa apakah tile tujuan terhalang oleh physics body atau trigger
func is_tile_blocked(dir: Vector2i) -> bool:
	var motion: Vector2 = Vector2(dir) * float(tile_size)
	
	# 1. Deteksi physics menggunakan test_move pada CharacterBody2D
	# Ini menguji seluruh CollisionShape2D pemain terhadap dinding dan rintangan StaticBody2D
	if test_move(global_transform, motion):
		return true
	
	# 2. Deteksi sekunder menggunakan RayCast2D
	if raycast:
		raycast.target_position = motion
		raycast.force_raycast_update()
		if raycast.is_colliding():
			return true
	
	return false

## Mendeteksi input 4 arah dengan larangan gerakan diagonal (strict cardinal)
func _get_input_direction() -> Vector2i:
	# 1. Prioritaskan tombol yang baru saja ditekan (just pressed) untuk responsivitas tinggi
	if Input.is_action_just_pressed("move_up"): return Vector2i.UP
	if Input.is_action_just_pressed("move_down"): return Vector2i.DOWN
	if Input.is_action_just_pressed("move_left"): return Vector2i.LEFT
	if Input.is_action_just_pressed("move_right"): return Vector2i.RIGHT
	
	# 2. Jika tombol yang sedang ditahan sama dengan arah hadap saat ini, lanjutkan arah tersebut
	if facing_direction == Vector2i.UP and Input.is_action_pressed("move_up"): return Vector2i.UP
	if facing_direction == Vector2i.DOWN and Input.is_action_pressed("move_down"): return Vector2i.DOWN
	if facing_direction == Vector2i.LEFT and Input.is_action_pressed("move_left"): return Vector2i.LEFT
	if facing_direction == Vector2i.RIGHT and Input.is_action_pressed("move_right"): return Vector2i.RIGHT
	
	# 3. Tangani tombol lain yang ditahan (hanya 1 sumbu cardinal)
	if Input.is_action_pressed("move_up"): return Vector2i.UP
	if Input.is_action_pressed("move_down"): return Vector2i.DOWN
	if Input.is_action_pressed("move_left"): return Vector2i.LEFT
	if Input.is_action_pressed("move_right"): return Vector2i.RIGHT
	
	return Vector2i.ZERO

## Mengatur animasi idle sesuai arah hadap
func _update_animation_idle() -> void:
	if not anim_sprite:
		return
	
	match facing_direction:
		Vector2i.UP:
			anim_sprite.play("idle_up")
		Vector2i.DOWN:
			anim_sprite.play("idle_down")
		Vector2i.LEFT:
			anim_sprite.play("idle_left")
		Vector2i.RIGHT:
			anim_sprite.play("idle_right")

## Mengatur animasi berjalan sesuai arah hadap
func _update_animation_walk() -> void:
	if not anim_sprite:
		return
	
	match facing_direction:
		Vector2i.UP:
			anim_sprite.play("walk_up")
		Vector2i.DOWN:
			anim_sprite.play("walk_down")
		Vector2i.LEFT:
			anim_sprite.play("walk_left")
		Vector2i.RIGHT:
			anim_sprite.play("walk_right")

## Mendapatkan koordinat grid integer saat ini
func get_grid_position() -> Vector2i:
	var gx: int = int(floor((position.x - float(tile_size) / 2.0) / float(tile_size) + 0.5))
	var gy: int = int(floor((position.y - float(tile_size) / 2.0) / float(tile_size) + 0.5))
	return Vector2i(gx, gy)

## Melakukan snap posisi ke pusat grid tile terdekat
func _snap_to_nearest_grid_center() -> void:
	var grid_pos: Vector2i = get_grid_position()
	position = Vector2(
		float(grid_pos.x * tile_size) + float(tile_size) / 2.0,
		float(grid_pos.y * tile_size) + float(tile_size) / 2.0
	)

## Memindahkan posisi pemain ke koordinat tertentu secara instan (digunakan saat spawn/transisi map)
func teleport_to_position(new_world_pos: Vector2) -> void:
	position = new_world_pos
	_snap_to_nearest_grid_center()
	start_world_pos = position
	target_world_pos = position
	is_moving = false
	move_progress = 0.0
	_update_animation_idle()

## Mengatur batas gerak kamera (Camera Limits) agar tidak memperlihatkan area luar peta
func set_camera_limits(left: int, top: int, right: int, bottom: int) -> void:
	if camera:
		camera.limit_left = left
		camera.limit_top = top
		camera.limit_right = right
		camera.limit_bottom = bottom

## Memastikan input actions terdaftar secara aman di runtime
func _ensure_input_actions() -> void:
	var default_actions: Dictionary = {
		"move_up": [KEY_UP, KEY_W],
		"move_down": [KEY_DOWN, KEY_S],
		"move_left": [KEY_LEFT, KEY_A],
		"move_right": [KEY_RIGHT, KEY_D],
		"interact": [KEY_E, KEY_SPACE],
		"menu": [KEY_ESCAPE]
	}
	
	for action_name in default_actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			for key_code in default_actions[action_name]:
				var event := InputEventKey.new()
				event.physical_keycode = key_code
				InputMap.action_add_event(action_name, event)
