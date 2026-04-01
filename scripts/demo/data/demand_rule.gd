class_name DemoDemandRule
extends Resource

@export var required_tags: PackedStringArray = []
@export var optional_tags: PackedStringArray = []
@export var forbidden_tags: PackedStringArray = []
@export var min_quality: int = 0
@export var score_weights: Dictionary = {}
