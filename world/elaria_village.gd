class_name ElariaVillage
extends Node2D

## Ukuran peta dalam satuan grid tile (50 x 35 tile = 800 x 560 piksel)
const MAP_GRID_WIDTH: int = 50
const MAP_GRID_HEIGHT: int = 35
const TILE_SIZE: int = 16

@onready var ground_layer: TileMapLayer = $Ground
@onready var details_layer: TileMapLayer = $GroundDetails
@onready var ysort_actors: Node2D = $YSortActors
@onready var spawn_points: Node2D = $SpawnPoints
@onready var player: Player = $YSortActors/Player

func _ready() -> void:
	# 1. Bangun peta visual menggunakan TileMapLayer Godot 4
	_build_village_terrain()
	
	# 2. Konfigurasi spawn point, batas kamera (800x560), dan registrasi ke WorldManager
	var map_bounds := Vector2i(MAP_GRID_WIDTH * TILE_SIZE, MAP_GRID_HEIGHT * TILE_SIZE)
	WorldManager.setup_map_environment(self, map_bounds, "village_start")
	
	print("[ElariaVillage] Desa Elaria berhasil dimuat. Dimensi: %dx%d px." % [map_bounds.x, map_bounds.y])

## Membangun tile visual tanah, jalan batu, jalan tanah, dan taman desa
func _build_village_terrain() -> void:
	if not ground_layer:
		return
	
	# Atlas Tile Indices pada village_tileset.tres:
	# (0,0): Rumput Desa
	# (1,0): Bunga Kuning
	# (2,0): Bunga Biru
	# (3,0): Jalan Tanah (Dirt Path)
	# (4,0): Jalan Batu Cobblestone
	# (5,0): Kolam Air
	# (6,0): Tanah Kebun (Tilled Soil)
	# (7,0): Tanaman Kebun
	# (4,1): Plaza Batu Pembatas
	# (7,1): Semak Hijau
	
	# 1. Lapisi seluruh dasar peta dengan rumput hijau desa
	for x in range(MAP_GRID_WIDTH):
		for y in range(MAP_GRID_HEIGHT):
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	
	# 2. Jalan Utama Cobblestone (Timur - Barat) dari Plaza (x=24) menuju Gerbang Hutan (x=49)
	for x in range(24, MAP_GRID_WIDTH):
		for y in range(16, 19): # Lebar 3 tile (Y=16, 17, 18)
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(4, 0))
	
	# 3. Plaza Tengah Desa (Cobblestone Square: x=20..27, y=14..21)
	for x in range(20, 28):
		for y in range(14, 22):
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(4, 0))
	
	# 4. Jalan Tanah (Dirt Path) Menghubungkan Rumah-Rumah Warga ke Plaza:
	# - Jalur Barat ke Rumah Pemain (x=10..20, y=17..18)
	for x in range(10, 21):
		ground_layer.set_cell(Vector2i(x, 17), 0, Vector2i(3, 0))
		ground_layer.set_cell(Vector2i(x, 18), 0, Vector2i(3, 0))
	
	# - Jalur Utara ke Rumah Tetua Desa (x=22..24, y=9..14)
	for y in range(9, 15):
		ground_layer.set_cell(Vector2i(23, y), 0, Vector2i(3, 0))
		ground_layer.set_cell(Vector2i(24, y), 0, Vector2i(3, 0))
	
	# - Jalur Selatan ke Toko / Penginapan (x=23..25, y=21..27)
	for y in range(21, 28):
		ground_layer.set_cell(Vector2i(23, y), 0, Vector2i(3, 0))
		ground_layer.set_cell(Vector2i(24, y), 0, Vector2i(3, 0))
	
	# 5. Kolam Desa (Pond) di Area Barat Laut (x=8..13, y=6..10)
	for x in range(8, 14):
		for y in range(6, 11):
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(5, 0))
	
	# 6. Kebun Desa (Garden Soil & Crops) di Dekat Rumah Pemain (x=8..13, y=22..25)
	if details_layer:
		for x in range(8, 14):
			for y in range(22, 26):
				ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(6, 0))
				# Tambahkan tanaman kecambah di layer details
				details_layer.set_cell(Vector2i(x, y), 0, Vector2i(7, 0))
		
		# 7. Taburan Bunga Hias di Taman Plaza & Sekitar Rumah
		var yellow_flowers: Array[Vector2i] = [
			Vector2i(18, 14), Vector2i(19, 14), Vector2i(18, 21), Vector2i(19, 21),
			Vector2i(28, 14), Vector2i(29, 14), Vector2i(28, 21), Vector2i(29, 21),
			Vector2i(14, 26), Vector2i(15, 26), Vector2i(32, 18), Vector2i(33, 18)
		]
		for pos in yellow_flowers:
			details_layer.set_cell(pos, 0, Vector2i(1, 0))
		
		var blue_flowers: Array[Vector2i] = [
			Vector2i(18, 15), Vector2i(19, 15), Vector2i(28, 15), Vector2i(29, 15),
			Vector2i(15, 12), Vector2i(16, 12), Vector2i(35, 15), Vector2i(36, 15),
			Vector2i(42, 15), Vector2i(43, 15), Vector2i(42, 19), Vector2i(43, 19)
		]
		for pos in blue_flowers:
			details_layer.set_cell(pos, 0, Vector2i(2, 0))
		
		# 8. Semak hias di tepi jalan
		var shrubs: Array[Vector2i] = [
			Vector2i(17, 16), Vector2i(17, 19), Vector2i(31, 15), Vector2i(31, 19),
			Vector2i(38, 15), Vector2i(38, 19), Vector2i(45, 15), Vector2i(45, 19)
		]
		for pos in shrubs:
			details_layer.set_cell(pos, 0, Vector2i(7, 1))
