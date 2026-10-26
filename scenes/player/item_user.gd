class_name ItemUser
extends Node
## Ações sobre itens do inventário: comer, cozinhar, usar e largar.
## O diário lista as ações disponíveis e chama perform().

const ACTION_EAT: StringName = &"eat"
const ACTION_COOK: StringName = &"cook"
const ACTION_USE: StringName = &"use"
const ACTION_DROP: StringName = &"drop"

const ACTION_LABELS: Dictionary[StringName, String] = {
	ACTION_EAT: "Comer",
	ACTION_COOK: "Cozinhar",
	ACTION_USE: "Usar",
	ACTION_DROP: "Largar",
}

@export var player: Player
## Distância à frente do jogador onde o item largado cai.
@export var drop_distance: float = 0.9


func get_available_actions(item_id: StringName) -> Array[StringName]:
	var actions: Array[StringName] = []
	if not Items.has_item(item_id) or not player.inventory.has(item_id):
		return actions
	var item: ItemData = Items.get_item(item_id)
	if item is FoodData:
		actions.append(ACTION_EAT)
		if _can_cook(item as FoodData):
			actions.append(ACTION_COOK)
	if item is LightFuelData:
		actions.append(ACTION_USE)
	actions.append(ACTION_DROP)
	return actions


func perform(item_id: StringName, action: StringName) -> bool:
	match action:
		ACTION_EAT:
			return eat(item_id)
		ACTION_COOK:
			return cook(item_id)
		ACTION_USE:
			return use(item_id)
		ACTION_DROP:
			return drop(item_id)
	return false


func eat(item_id: StringName) -> bool:
	var food: FoodData = Items.get_item(item_id) as FoodData
	if food == null or not player.inventory.remove(item_id):
		return false
	SurvivalStats.consume_food(food)
	Events.food_eaten.emit(item_id, player.global_position)
	return true


func cook(item_id: StringName) -> bool:
	var food: FoodData = Items.get_item(item_id) as FoodData
	if food == null or not _can_cook(food) or not player.inventory.remove(item_id):
		return false
	# Se o cozido não couber (mais pesado que o cru), cai no chão.
	if not player.inventory.add(food.cooks_into):
		_spawn_in_world(food.cooks_into)
	return true


func use(item_id: StringName) -> bool:
	var fuel: LightFuelData = Items.get_item(item_id) as LightFuelData
	if fuel == null or not player.inventory.remove(item_id):
		return false
	SurvivalStats.add(SurvivalStats.Stat.LIGHT, fuel.light_restore)
	return true


func drop(item_id: StringName) -> bool:
	if not player.inventory.has(item_id):
		return false
	var spot: Vector3 = _spawn_in_world(item_id)
	if spot == Vector3.INF:
		return false
	player.inventory.remove(item_id)
	Events.item_dropped.emit(item_id, 1, spot)
	return true


func _can_cook(food: FoodData) -> bool:
	return food.cooks_into != &"" and Items.has_item(food.cooks_into) and player.get_nearby_lit_campfire() != null


## Cria o item no chão à frente do jogador. Devolve a posição, ou Vector3.INF se falhar.
func _spawn_in_world(item_id: StringName) -> Vector3:
	var item: ItemData = Items.get_item(item_id)
	if item == null:
		return Vector3.INF
	var scene: PackedScene = load(item.get_pickup_scene_path()) as PackedScene
	var pickup: Pickup = scene.instantiate() as Pickup if scene else null
	if pickup == null:
		push_error("Cena de item inválida para %s" % item_id)
		return Vector3.INF
	pickup.item = item
	pickup.amount = 1
	var spot: Vector3 = _find_ground_in_front()
	player.get_tree().current_scene.add_child(pickup)
	pickup.global_position = spot
	pickup.rotation.y = randf() * TAU
	return spot


func _find_ground_in_front() -> Vector3:
	var forward: Vector3 = -player.global_basis.z
	var origin: Vector3 = player.global_position + forward * drop_distance + Vector3.UP
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * 3.0, 1)
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return player.global_position
	return hit["position"]
