class_name GameEnums
extends RefCounted

enum TurnState {
	IDLE,
	PLAYER_TURN,
	RESOLVING_EFFECTS,
	CUSTOMER_TURN,
	CHECK_END,
}

enum RunPhase {
	PREP_PHASE,
	GAMEPLAY,
	REWARD,
	EVENT,
	DAY_END,
	RUN_END,
}
