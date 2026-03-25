class_name SessionService
extends Node

const STARTER_CARD_PATHS := [
	"res://data/cards/starter_focus.tres",
	"res://data/cards/starter_second_wind.tres",
]

var run_state: RunState
var combat_state: CombatState
var player_state: PlayerState
var cafe_state: CafeState
var deck_state: DeckState

func start_new_run() -> void:
	run_state = RunState.new()
	run_state.day_number = 1
	run_state.run_phase = GameEnums.RunPhase.GAMEPLAY

	combat_state = CombatState.new()
	combat_state.turn_state = GameEnums.TurnState.PLAYER_TURN

	player_state = PlayerState.new()
	cafe_state = CafeState.new()
	deck_state = DeckState.new()

	load_starter_deck()

func load_starter_deck() -> void:
	var cards: Array[CardInstance] = []
	for path in STARTER_CARD_PATHS:
		var card_def := load(path) as CardDef
		if card_def == null:
			continue
		var instance := CardInstance.new()
		instance.card_def = card_def
		cards.append(instance)
		cards.append(instance.duplicate(true))
	deck_state.reset_from_cards(cards)

func draw_starting_hand(hand_size: int = 3) -> void:
	for _i in hand_size:
		deck_state.draw_one()

func can_play_card(card: CardInstance) -> bool:
	if card == null:
		return false
	return player_state.energy >= card.get_cost()

func spend_energy(amount: int) -> void:
	player_state.energy = max(player_state.energy - amount, 0)

func is_run_over() -> bool:
	return player_state.energy <= 0 or player_state.reputation <= 0

func build_effect_context(card: CardInstance) -> EffectContext:
	var context := EffectContext.new()
	context.run_state = run_state
	context.combat_state = combat_state
	context.player_state = player_state
	context.cafe_state = cafe_state
	context.deck_state = deck_state
	context.source_card = card
	return context
