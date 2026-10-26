class_name ItemData
extends Resource
## Definição de um tipo de item. O inventário guarda só o id e a quantidade.

const DEFAULT_PICKUP_SCENE: String = "res://scenes/interactables/item_pickup.tscn"

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
## Peso em kg.
@export var weight: float = 1.0
## Malha usada pela cena genérica de item no chão.
@export var world_mesh: Mesh
## Cena instanciada ao largar o item; vazio usa a cena genérica.
## É um caminho, e não PackedScene, para evitar referência circular com a
## cena que aponta para este recurso.
@export_file("*.tscn") var pickup_scene_path: String = ""


func get_pickup_scene_path() -> String:
	return pickup_scene_path if not pickup_scene_path.is_empty() else DEFAULT_PICKUP_SCENE
