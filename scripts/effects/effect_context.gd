class_name EffectContext
extends RefCounted

var run_state: RunState
var combat_state: CombatState
var player_state: PlayerState
var cafe_state: CafeState
var deck_state: DeckState
var event_bus: EventBus
var session_service: SessionService
var content_library: ContentLibrary
var meta_profile_service: MetaProfileService
var source_card: CardInstance
var source_modifier: ModifierInstance
var targets: Array = []

func duplicate_for_effect() -> EffectContext:
	var copy: EffectContext = EffectContext.new()
	copy.run_state = run_state
	copy.combat_state = combat_state
	copy.player_state = player_state
	copy.cafe_state = cafe_state
	copy.deck_state = deck_state
	copy.event_bus = event_bus
	copy.session_service = session_service
	copy.content_library = content_library
	copy.meta_profile_service = meta_profile_service
	copy.source_card = source_card
	copy.source_modifier = source_modifier
	copy.targets = targets.duplicate(true)
	return copy
