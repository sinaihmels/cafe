class_name DoughSelectScreenView
extends VBoxContainer

signal start_run_requested(dough_id: StringName)

@export var choice_entry_scene: PackedScene

@onready var _intro_label: Label = $DoughIntroLabel
@onready var _list_container: VBoxContainer = $DoughList

func render(session_service: SessionService) -> void:
	UiSceneUtils.clear_children(_list_container)
	var pending_day_number: int = maxi(1, session_service.run_state.pending_day_number)
	_intro_label.text = "Choose the dough for day %d. The selected dough is automatically prepped at the start of the day." % pending_day_number
	var profile: MetaProfileState = session_service.get_profile_state()
	for dough_value in session_service.get_available_doughs():
		var dough: DoughDef = dough_value
		var unlocked: bool = profile.unlocked_dough_ids.has(dough.dough_id)
		var entry: ChoiceEntryView = _instantiate_choice_entry()
		entry.configure(
			UiTextureLibrary.dough_texture(dough),
			dough.display_name,
			dough.description,
			"Unlocked" if unlocked else "Locked",
			"Prep Day %d" % pending_day_number if unlocked else ""
		)
		if unlocked:
			var dough_id: StringName = dough.dough_id
			entry.primary_action_requested.connect(func() -> void:
				start_run_requested.emit(dough_id)
			)
		_list_container.add_child(entry)

func _instantiate_choice_entry() -> ChoiceEntryView:
	var node: Node = UiSceneUtils.instantiate_required(choice_entry_scene, "DoughSelectScreenView.choice_entry_scene")
	var entry: ChoiceEntryView = node as ChoiceEntryView
	assert(entry != null, "DoughSelectScreenView.choice_entry_scene must instantiate ChoiceEntryView.")
	return entry
