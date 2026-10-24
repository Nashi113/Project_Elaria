class_name DialogueData
extends Resource

## Nama ID unik untuk dialogue ini (digunakan sebagai kunci referensi)
@export var dialogue_id: String = ""

## Daftar urutan baris-baris dialog (DialogueLine)
@export var lines: Array[DialogueLine] = []
