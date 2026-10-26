class_name Pickup
extends Interactable
## Item do mundo que vai para o inventário ao ser coletado (lenha, enlatado...).

@export var item_id: StringName = &""
@export_range(1, 99) var amount: int = 1

## Texto mostrado quando o item não cabe no inventário.
@export var too_heavy_text: String = "Pesado demais"


func get_prompt(player: Player) -> String:
	if not player.inventory.can_add(item_id, amount):
		return too_heavy_text
	return prompt_text


func can_interact(player: Player) -> bool:
	return player.inventory.can_add(item_id, amount)


func interact(player: Player) -> void:
	if not player.inventory.add(item_id, amount):
		return
	Events.item_picked_up.emit(item_id, amount, global_position)
	queue_free()
