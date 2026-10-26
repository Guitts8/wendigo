class_name FoodData
extends ItemData
## Item comestível. Comer aplica os valores no SurvivalStats.

@export var hunger_restore: float = 0.0
@export var warmth_restore: float = 0.0
@export var corruption_gain: float = 0.0
## Id do item resultante ao cozinhar numa fogueira acesa; vazio = não cozinha.
@export var cooks_into: StringName = &""
