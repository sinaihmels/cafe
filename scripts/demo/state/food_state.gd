class_name DemoFoodState
extends Resource

@export var tags: PackedStringArray = []
@export var quality: int = 0
@export var flags: Dictionary = {}
@export var times_modified_this_turn: int = 0
@export var score_bonus: int = 0

func reset() -> void:
	tags.clear()
	quality = 0
	flags.clear()
	times_modified_this_turn = 0
	score_bonus = 0

func has_tag(tag: StringName) -> bool:
	return tags.has(tag)

func add_tag(tag: StringName) -> void:
	if tag == &"":
		return
	if not tags.has(tag):
		tags.append(tag)

func describe() -> String:
	var tag_text: String = "None"
	if not tags.is_empty():
		var output: String = ""
		for index in range(tags.size()):
			if index > 0:
				output += ", "
			output += String(tags[index])
		tag_text = output
	return "Tags: %s | Quality: %d | Bonus: %d" % [tag_text, quality, score_bonus]
