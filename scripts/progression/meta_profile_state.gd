class_name MetaProfileState
extends Resource

@export var version: int = 1
@export var meta_currency: int = 12
@export var owned_equipment_ids: PackedStringArray = []
@export var equipped_equipment_ids: PackedStringArray = []
@export var purchased_shop_upgrade_ids: PackedStringArray = []
@export var owned_decoration_ids: PackedStringArray = []
@export var decoration_layout: Dictionary = {
	"wall": "",
	"counter": "",
	"floor": "",
	"shelf": "",
	"exterior": "",
}
@export var unlocked_dough_ids: PackedStringArray = []
@export var unlocked_card_ids: PackedStringArray = []
@export var unlocked_customer_ids: PackedStringArray = []
@export var unlocked_equipment_ids: PackedStringArray = []
@export var unlocked_decoration_ids: PackedStringArray = []
@export var unlocked_shop_upgrade_ids: PackedStringArray = []
@export var unlocked_buff_ids: PackedStringArray = []
@export var unlocked_status_ids: PackedStringArray = []
@export var run_count: int = 0
@export var best_run_day: int = 0

func ensure_defaults() -> void:
	for slot_name in ["wall", "counter", "floor", "shelf", "exterior"]:
		if not decoration_layout.has(slot_name):
			decoration_layout[slot_name] = ""
