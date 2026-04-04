class_name EncounterHudView
extends PanelContainer

@export var stat_chip_scene: PackedScene
@export var buff_line_scene: PackedScene

@onready var _energy_value: Label = $HudMargin/HudBody/HudEnergyValue
@onready var _buffs_container: VBoxContainer = $HudMargin/HudBody/HudBuffsContainer
@onready var _stats_container: HFlowContainer = $HudMargin/HudBody/HudStats

func render(session_service: SessionService) -> void:
	_energy_value.text = "%d / %d" % [session_service.player_state.energy, session_service.player_state.max_energy]
	UiSceneUtils.clear_children(_buffs_container)
	UiSceneUtils.clear_children(_stats_container)
	var buff_lines: Array[String] = UiTextFormatter.build_modifier_lines(session_service)
	if buff_lines.is_empty():
		var empty_label: Label = _instantiate_buff_line()
		empty_label.text = "No active buffs."
		_buffs_container.add_child(empty_label)
	else:
		for buff_line in buff_lines:
			var buff_label: Label = _instantiate_buff_line()
			buff_label.text = buff_line
			_buffs_container.add_child(buff_label)
	_add_chip("Stress", "%d/%d" % [session_service.player_state.stress, session_service.player_state.max_stress], _stress_tone(session_service))
	_add_chip("Rep", str(session_service.player_state.reputation), "accent")
	_add_chip("Tips", str(session_service.player_state.tips), "gold")
	_add_chip("Day", str(session_service.run_state.day_number), "paper")
	_add_chip("Turn", str(session_service.combat_state.turn_number), "paper")

func _add_chip(label_text: String, value_text: String, tone: String) -> void:
	var chip: StatChipView = _instantiate_stat_chip()
	chip.configure(label_text, value_text, tone)
	_stats_container.add_child(chip)

func _stress_tone(session_service: SessionService) -> String:
	# Stress gets warmer as it approaches the cap.
	if session_service.player_state.max_stress <= 0:
		return "paper"
	if session_service.player_state.stress * 3 >= session_service.player_state.max_stress * 2:
		return "danger"
	if session_service.player_state.stress * 2 >= session_service.player_state.max_stress:
		return "gold"
	return "paper"

func _instantiate_stat_chip() -> StatChipView:
	var node: Node = UiSceneUtils.instantiate_required(stat_chip_scene, "EncounterHudView.stat_chip_scene")
	var chip: StatChipView = node as StatChipView
	assert(chip != null, "EncounterHudView.stat_chip_scene must instantiate StatChipView.")
	return chip

func _instantiate_buff_line() -> Label:
	var node: Node = UiSceneUtils.instantiate_required(buff_line_scene, "EncounterHudView.buff_line_scene")
	var label: Label = node as Label
	assert(label != null, "EncounterHudView.buff_line_scene must instantiate Label.")
	return label
