extends Node
## Barramento global de sinais de gameplay.
##
## Os objetos emitem aqui o que aconteceu no mundo; sistemas como o
## TutorialRecorder (Fase 3) e o wendigo (Fase 4) só precisam escutar,
## sem conhecer quem emitiu.

## Um item foi coletado do mundo para o inventário do jogador.
signal item_picked_up(item_id: StringName, amount: int, world_position: Vector3)

## O jogador largou um item no mundo (o recorder usa para "onde guardou itens").
signal item_dropped(item_id: StringName, amount: int, world_position: Vector3)

## O jogador comeu algo.
signal food_eaten(item_id: StringName, world_position: Vector3)

## Uma fogueira acendeu (estava apagada e recebeu combustível).
signal campfire_lit(campfire: Campfire)

## Uma fogueira apagou porque o combustível acabou.
signal campfire_extinguished(campfire: Campfire)

## O lampião do jogador acendeu ou apagou (luz visível de longe).
signal lantern_toggled(is_on: bool, world_position: Vector3)

## O jogador entrou ou saiu de um esconderijo.
signal hiding_spot_entered(spot_id: StringName, world_position: Vector3)
signal hiding_spot_exited(spot_id: StringName, world_position: Vector3)

## O jogador dormiu numa cama (o recorder usa para "onde dormiu").
signal slept(bed_id: StringName, world_position: Vector3, hours: float)

## O jogador entrou numa TriggerZone do roteiro.
signal trigger_entered(trigger_id: StringName)

## O jogador cuidou do colega (kind: &"treat" curativo, &"food" comida).
signal companion_cared(kind: StringName)

## A anotação atual do diário mudou (objetivo do roteiro).
signal objective_changed(text: String)
