class_name Pickup
extends Interactable
## Item do mundo que vai para o inventário ao ser coletado (lenha, enlatado...).
## Se a cena tiver um MeshInstance3D "Mesh" vazio, ele recebe a malha do item.

@export var item: ItemData
@export_range(1, 99) var amount: int = 1

## Texto mostrado quando o item não cabe no inventário.
@export var too_heavy_text: String = "Pesado demais"

@onready var _mesh: MeshInstance3D = get_node_or_null(^"Mesh") as MeshInstance3D


func _ready() -> void:
	if _mesh and _mesh.mesh == null and item and item.world_mesh:
		_mesh.mesh = item.world_mesh
		# Apoia a malha no chão, qualquer que seja a origem dela.
		_mesh.position.y = -item.world_mesh.get_aabb().position.y


## Texto padrão vazio vira "Pegar <nome do item>".
func get_prompt(player: Player) -> String:
	if item == null:
		return ""
	if not player.inventory.can_add(item.id, amount):
		return too_heavy_text
	if prompt_text.is_empty():
		return "Pegar %s" % item.display_name.to_lower()
	return prompt_text


func can_interact(player: Player) -> bool:
	return item != null and player.inventory.can_add(item.id, amount)


func interact(player: Player) -> void:
	if item == null or not player.inventory.add(item.id, amount):
		return
	Events.item_picked_up.emit(item.id, amount, global_position)
	queue_free()
