class_name DeckState
extends Resource

@export var draw_pile: Array[CardInstance] = []
@export var discard_pile: Array[CardInstance] = []
@export var hand: Array[CardInstance] = []

func reset_from_cards(cards: Array[CardInstance]) -> void:
	draw_pile = cards.duplicate(true)
	discard_pile.clear()
	hand.clear()

func draw_one() -> CardInstance:
	if draw_pile.is_empty():
		reshuffle_discard_into_draw()
	if draw_pile.is_empty():
		return null
	var card := draw_pile.pop_front()
	hand.append(card)
	return card

func discard_from_hand(card: CardInstance) -> void:
	var index := hand.find(card)
	if index >= 0:
		hand.remove_at(index)
		discard_pile.append(card)

func reshuffle_discard_into_draw() -> void:
	if discard_pile.is_empty():
		return
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
