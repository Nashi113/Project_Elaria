class_name DialogueLine
extends Resource

## Nama pembicara yang ditampilkan di atas kotak dialog
@export var speaker_name: String = ""

## Teks percakapan yang ditampilkan dalam kotak dialog
@export_multiline var text: String = ""

## (Opsional) ID quest yang terpicu setelah baris dialog ini selesai
## Disiapkan untuk integrasi sistem quest di Milestone 9
@export var trigger_quest_id: String = ""
