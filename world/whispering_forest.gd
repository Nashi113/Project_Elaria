class_name WhisperingForest
extends Node2D

## Ukuran peta hutan dalam satuan grid tile (55 x 40 tile = 880 x 640 piksel)
const MAP_GRID_WIDTH: int = 55
const MAP_GRID_HEIGHT: int = 40
const TILE_SIZE: int = 16

@onready var ground_layer: TileMapLayer = $Ground
@onready var details_layer: TileMapLayer = $GroundDetails
@onready var ysort_actors: Node2D = $YSortActors
@onready var spawn_points: Node2D = $SpawnPoints
@onready var player: Player = $YSortActors/Player

func _ready() -> void:
	# 1. Bangun peta visual hutan liar menggunakan TileMapLayer Godot 4
	_build_forest_terrain()
	
	# 2. Konfigurasi spawn point, batas kamera (880x640), dan registrasi ke WorldManager
	var map_bounds := Vector2i(MAP_GRID_WIDTH * TILE_SIZE, MAP_GRID_HEIGHT * TILE_SIZE)
	WorldManager.setup_map_environment(self, map_bounds, "forest_from_village")
	
	print("[WhisperingForest] Hutan Whispering Forest berhasil dimuat. Dimensi: %dx%d px." % [map_bounds.x, map_bounds.y])

## Membangun terrain hutan, jalur berliku, dan zona rumput tinggi
func _build_forest_terrain() -> void:
	if not ground_layer:
		return
	
	# Atlas Tile Indices pada forest_tileset.tres:
	# (0,0): Rumput Hutan Lebat (Deep Forest Grass)
	# (1,0): Daun Musim Gugur (Autumn Leaves)
	# (2,0): Jamur Hutan (Mushrooms)
	# (3,0): Jalur Tanah Hutan (Forest Dirt Path)
	# (4,0): Rumput Liar Tinggi (Tall Grass / Encounter Bush)
	# (5,0): Batu Berlumut (Mossy Stone)
	# (6,0): Aliran Air (Forest Water)
	# (7,0): Semak Belukar Berduri (Brambles)
	
	# 1. Lapisi seluruh area peta dengan rumput hijau tua khas hutan rimba
	for x in range(MAP_GRID_WIDTH):
		for y in range(MAP_GRID_HEIGHT):
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	
	# 2. Jalan Masuk dari Desa Elaria (Barat ke Timur, x=0..14, y=16..18)
	for x in range(0, 15):
		for y in range(16, 19):
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(3, 0))
	
	# 3. Jalur Berliku Menuju Kliring Utara (Winding Path North-East)
	# Belok ke Utara (x=13..15, y=10..16)
	for x in range(13, 16):
		for y in range(10, 17):
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(3, 0))
	
	# Menuju Timur ke Kliring Utama (x=15..32, y=9..11)
	for x in range(15, 33):
		for y in range(9, 12):
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(3, 0))
	
	# Kliring Matahari Terbuka di Utara (x=24..34, y=8..14)
	for x in range(24, 35):
		for y in range(8, 15):
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(3, 0))
	
	# 4. Jalur Menuju Tenggara (x=33..42, y=14..24)
	for y in range(14, 25):
		for x in range(35, 38):
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(3, 0))
	
	# Jalur Selatan Melingkar Kembali ke Barat (x=18..36, y=26..28)
	for x in range(18, 37):
		for y in range(26, 29):
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(3, 0))
	
	# Sambungan Kembali ke Jalur Barat (x=13..15, y=18..27)
	for y in range(18, 28):
		for x in range(13, 16):
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(3, 0))
	
	# 5. Zona Rumput Tinggi (Tall Grass / Habitat Makhluk Liar)
	# Zona 1: Hutan Barat (x=6..11, y=11..15)
	_fill_tall_grass_zone(Rect2i(6, 11, 6, 5))
	
	# Zona 2: Hutan Tengah (x=20..28, y=17..23)
	_fill_tall_grass_zone(Rect2i(20, 17, 9, 6))
	
	# Zona 3: Hutan Timur (x=40..47, y=12..20)
	_fill_tall_grass_zone(Rect2i(40, 12, 8, 8))
	
	# Zona 4: Hutan Selatan (x=22..32, y=30..35)
	_fill_tall_grass_zone(Rect2i(22, 30, 10, 5))
	
	# 6. Detail Alam: Jamur Hutan, Daun Berguguran, dan Batu Berlumut
	if details_layer:
		# Daun berguguran di jalur
		var leaves: Array[Vector2i] = [
			Vector2i(8, 17), Vector2i(10, 16), Vector2i(14, 12), Vector2i(20, 10),
			Vector2i(28, 9), Vector2i(36, 16), Vector2i(36, 22), Vector2i(25, 27)
		]
		for pos in leaves:
			details_layer.set_cell(pos, 0, Vector2i(1, 0))
		
		# Jamur merah hutan
		var mushrooms: Array[Vector2i] = [
			Vector2i(5, 9), Vector2i(12, 8), Vector2i(18, 7), Vector2i(38, 9),
			Vector2i(48, 14), Vector2i(34, 25), Vector2i(17, 32), Vector2i(35, 32)
		]
		for pos in mushrooms:
			details_layer.set_cell(pos, 0, Vector2i(2, 0))
		
		# Batu berlumut
		var mossy_rocks: Array[Vector2i] = [
			Vector2i(18, 14), Vector2i(32, 13), Vector2i(38, 26), Vector2i(12, 22)
		]
		for pos in mossy_rocks:
			details_layer.set_cell(pos, 0, Vector2i(5, 0))

## Fungsi bantuan untuk mengisi area rumput tinggi (Tall Grass)
func _fill_tall_grass_zone(rect: Rect2i) -> void:
	if not details_layer:
		return
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			# Tempatkan rumput tinggi (atlas index: 4, 0)
			details_layer.set_cell(Vector2i(x, y), 0, Vector2i(4, 0))
