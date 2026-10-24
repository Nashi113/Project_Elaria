class_name DialogueUI
extends CanvasLayer

# ==============================================================================
# SINYAL
# ==============================================================================
## Dipancarkan ketika kotak dialog sepenuhnya ditutup
signal dialogue_closed()

# ==============================================================================
# REFERENSI NODE (harus sesuai dengan hierarki scene dialogue_ui.tscn)
# ==============================================================================
@onready var panel: PanelContainer = $DialoguePanel
@onready var speaker_label: Label = $DialoguePanel/MarginContainer/VBoxContainer/SpeakerName
@onready var text_label: RichTextLabel = $DialoguePanel/MarginContainer/VBoxContainer/DialogueText
@onready var continue_hint: Label = $DialoguePanel/MarginContainer/VBoxContainer/ContinueHint
@onready var typewriter_timer: Timer = $TypewriterTimer

# ==============================================================================
# STATE DIALOGUE
# ==============================================================================
## Semua baris dialog yang sedang aktif
var _lines: Array[DialogueLine] = []
## Indeks baris yang sedang ditampilkan
var _current_line_index: int = 0
## Apakah efek typewriter masih berjalan (karakter belum semua muncul)
var _is_typing: bool = false
## Teks lengkap dari baris saat ini
var _full_text: String = ""
## Berapa karakter sudah ditampilkan saat ini
var _visible_chars: int = 0

## Kecepatan efek pengetikan: setiap X detik, 1 karakter baru muncul
const TYPEWRITER_SPEED: float = 0.035

func _ready() -> void:
	# Masukkan ke dalam grup agar mudah ditemukan oleh NPC
	add_to_group("DialogueUI")
	layer = 10
	panel.visible = false
	if typewriter_timer and not typewriter_timer.timeout.is_connected(_on_typewriter_timer_timeout):
		typewriter_timer.timeout.connect(_on_typewriter_timer_timeout)

func _unhandled_input(event: InputEvent) -> void:
	# Hanya proses input jika dialog sedang terbuka
	if not panel.visible:
		return

	if event.is_action_pressed("interact") or event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		_on_advance_pressed()

## Membuka dialog dengan daftar baris dialog dari sebuah NPC
func open_dialogue(lines: Array[DialogueLine]) -> void:
	if lines.is_empty():
		return

	_lines = lines
	_current_line_index = 0
	panel.visible = true
	_show_line(_current_line_index)

## Menutup dialog dan memancarkan sinyal agar sistem lain (Player) tahu dialog sudah selesai
func close_dialogue() -> void:
	if typewriter_timer and not typewriter_timer.is_stopped():
		typewriter_timer.stop()
	panel.visible = false
	_lines = []
	_current_line_index = 0
	_is_typing = false
	dialogue_closed.emit()

## Menampilkan baris dialog pada indeks tertentu dengan efek pengetikan
func _show_line(index: int) -> void:
	if index >= _lines.size():
		close_dialogue()
		return

	var line: DialogueLine = _lines[index]
	speaker_label.text = line.speaker_name
	_full_text = line.text
	_visible_chars = 0
	_is_typing = true
	text_label.text = ""
	text_label.visible_ratio = 1.0
	continue_hint.visible = false

	# Mulai timer typewriter
	if typewriter_timer:
		typewriter_timer.wait_time = TYPEWRITER_SPEED
		typewriter_timer.start()

## Dipanggil setiap kali tombol interaksi (E/Space) ditekan saat dialog terbuka
func _on_advance_pressed() -> void:
	if _is_typing:
		# Jika typewriter masih berjalan: langsung tampilkan seluruh teks sekarang
		_skip_typewriter()
	else:
		# Jika teks sudah sepenuhnya muncul: lanjut ke baris berikutnya
		_current_line_index += 1
		_show_line(_current_line_index)

## Menyelesaikan efek typewriter secara instan (skip)
func _skip_typewriter() -> void:
	if typewriter_timer:
		typewriter_timer.stop()
	text_label.text = _full_text
	_is_typing = false
	continue_hint.visible = true

## Dipanggil oleh TypewriterTimer setiap tick untuk menampilkan 1 karakter baru
func _on_typewriter_timer_timeout() -> void:
	if _visible_chars < _full_text.length():
		_visible_chars += 1
		text_label.text = _full_text.substr(0, _visible_chars)
	else:
		# Semua karakter sudah ditampilkan
		typewriter_timer.stop()
		_is_typing = false
		continue_hint.visible = true
