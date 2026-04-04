class_name RewardScreenView
extends VBoxContainer

signal reward_requested(reward_id: StringName)

@export var choice_entry_scene: PackedScene

@onready var _list_container: VBoxContainer = $RewardList

func render(session_service: SessionService) -> void:
	UiSceneUtils.clear_children(_list_container)
	for reward_value in session_service.get_pending_rewards():
		var reward: RewardDef = reward_value
		var entry: ChoiceEntryView = _instantiate_choice_entry()
		entry.configure(
			UiTextureLibrary.reward_texture(session_service.content_library, reward),
			reward.display_name,
			reward.description,
			"",
			"Choose"
		)
		var reward_id: StringName = reward.reward_id
		entry.primary_action_requested.connect(func() -> void:
			reward_requested.emit(reward_id)
			)
		_list_container.add_child(entry)

func _instantiate_choice_entry() -> ChoiceEntryView:
	var node: Node = UiSceneUtils.instantiate_required(choice_entry_scene, "RewardScreenView.choice_entry_scene")
	var entry: ChoiceEntryView = node as ChoiceEntryView
	assert(entry != null, "RewardScreenView.choice_entry_scene must instantiate ChoiceEntryView.")
	return entry
