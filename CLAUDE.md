# Fome Branca (título provisório)

Sobrevivência e horror em 3D, primeira pessoa, PC, em **Godot 4 com GDScript**. Premissa: o monstro é o personagem que o jogador controlou no tutorial.

- Documento de design completo: `docs/GDD.md` (consulte para detalhes).
- Decisões tomadas: `docs/DECISOES.md`.
- Prompt original do projeto: `README.md`.

## Ambiente

- Godot **4.7.2 stable** (não está no PATH). Executável de console para a linha de comando:
  `C:\Users\raul.silva\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`
- Renderizador: **Forward+** (necessário para fog volumétrico).
- Validar sem abrir o editor: `<godot_console> --headless --path . --import` e depois `<godot_console> --headless --path . --quit-after 300` (roda a cena principal e mostra erros de script/cena).
- `--check-only --script` não registra autoloads: acusa falsamente "Identifier not found: Events". Prefira rodar a cena.
- Testes de fumaça: cena temporária em `res://tmp_smoke/` rodada headless e apagada depois (não comitar).
- No headless, `DisplayServer` não suporta algumas chamadas (ex.: `keyboard_get_keycode_from_physical`).

- GPU da máquina de desenvolvimento: Intel UHD integrada (D3D12). Cuidado com efeitos caros (fog volumétrico, muitas sombras).
- `_ready()` dos filhos roda antes do pai: um filho do Player que precisa de `player.inventory` etc. deve fazer `await player.ready` se `not player.is_node_ready()`.

## Estrutura atual
- Autoloads (ordem): `Events` (sinais globais), `Items` (catálogo), `WorldClock`, `SurvivalStats`, `Dialogue` (falas/legendas), `ScreenFade` (tela preta de transição). Os `.tscn` existem para os `@export` serem editáveis no Inspector.
- Cena principal: `scenes/levels/tutorial.tscn` = `scenes/world/valley.tscn` (mapa único: cabana com móveis, lago, fenda, trilha bloqueada, floresta) + colega + itens + `TutorialDirector`. `test_level.tscn` é só caixa de areia.
- Falas: `data/dialogue/*.json` (`{chave: [{speaker, text, audio?, duration?}]}`), speaker vazio = pensamento. O roteiro (`scenes/tutorial/tutorial_director.gd`) avança por etapas ouvindo o `Events`.
- Autoloads sobrevivem a `reload_current_scene()`: quem recarrega deve zerar `Engine.time_scale`, `Dialogue` e `ScreenFade` (ver `GameOver`).
- Desempenho: ~45–60 FPS na Intel UHD com 110 árvores e neve. Otimizar depois (MultiMesh nas árvores, menos sombras).
- Itens: scripts em `scenes/items/` (`ItemData`, `FoodData`, `LightFuelData`); dados em `data/items/*.tres`, registrados em `data/items/item_catalog.tres`. O inventário guarda só id + quantidade.
- O `DayNightCycle` do nível aplica o `WorldClock` no sol, lua, céu e neblina. O `Player` informa ao `SurvivalStats` abrigo/calor/esforço via `WarmthZone`s.
- Depuração (builds de debug): F3 painel, F4 nevasca, F6 +1 h, F7 −20 calor, F8 −20 fome, F9 pula etapa do tutorial.

## Camadas de física
1. `world`: terreno, cabana, árvores, rochas.
2. `player`: o jogador (máscara: `world`).
3. `interactable`: objetos com `interact()` (sem máscara). O raio de interação usa `world` + `interactable`, para paredes bloquearem.

## Resumo do jogo

- **Ato 1 (tutorial, 15–20 min):** dois amigos presos por uma nevasca numa cabana de caça. O jogador aprende a coletar lenha, acender fogo, caçar e racionar. O colega piora e morre. A comida acaba e a única interação restante é o corpo. O jogador pode recusar algumas vezes (perde calor e força a cada recusa) até ceder. O personagem vira wendigo.
- **Ato 2 (partida, 45–90 min):** "Três invernos depois", um novo personagem chega ao vale. Objetivo: sobreviver até o resgate ou destruir o coração de gelo do wendigo.
- **Ciclo:** se o personagem da partida atingir corrupção total, ele vira o wendigo da próxima partida.

### Pilares
1. O monstro é você: o que o jogador faz no tutorial volta contra ele.
2. Sobrevivência simples, decisões pesadas.
3. A fome corrompe: carne humana é sempre tentadora e sempre cobra um preço.
4. Um mapa só (~1 km²), cada vez mais conhecido e mais assustador.

### Mecânicas
- **Recursos:** Calor, Fome, Luz (+ Corrupção). Calor cai ao ar livre, à noite e na nevasca; Fome cai com o tempo; Luz é combustível do lampião (querosene, gordura animal). Zerar Calor ou Fome mata. Sem Luz, o wendigo enxerga e você não.
- **Comida:** enlatados (pouco, sem corrupção), peixe/coelho (médio), carne crua (médio, corrupção leve), carne humana (muito alto, corrupção alta, calor e visão noturna temporários).
- **Corrupção em 4 estágios:** leve → média → alta → total (vira wendigo). Ver GDD.
- **Ações:** coletar, fogueira, caçar, pescar, cozinhar, craft simples (tocha, armadilha, curativo, roupa de pele), esconder-se. Inventário limitado por peso.
- **Dia/noite e nevascas aleatórias.** À noite o wendigo caça ativamente.
- **Sem combate direto:** fogo afasta, armadilhas atrasam, só o coração de gelo mata.
- **HUD mínimo:** estado mostrado no corpo/câmera; medidores só no diário/inventário.

### Wendigo
- **Memória do tutorial (sistema central):** gravar em segredo fogueiras acesas, esconderijos usados, onde dormiu, trilhas (posição amostrada a cada poucos segundos), onde guardou itens, quantas vezes recusou o corpo. Na partida, o wendigo patrulha esses pontos com peso; esconderijos favoritos são checados primeiro.
- **Estados:** Vagando → Desconfiado → Caçando → Recuando (fogo forte) → Atraindo (imita vozes).
- Cresce e fica mais rápido/barulhento ao comer. Carrega objetos do personagem do tutorial. Se o jogador recusou muito o corpo, hesita um instante ao vê-lo.
- Não entra em construção com fogueira acesa.

## Arquitetura

- Jogador: `CharacterBody3D` + `Camera3D`; interação por `RayCast3D` + método `interact()` nos objetos.
- Autoloads: `SurvivalStats` (calor, fome, luz, corrupção, sinais por estágio), `WorldClock` (dia/noite, `DirectionalLight3D`, nevascas), `TutorialRecorder` (grava eventos do tutorial em `user://`).
- Wendigo: `CharacterBody3D` + `NavigationAgent3D` sobre `NavigationRegion3D`, máquina de estados; visão por `RayCast3D`/`Area3D`; o jogador emite eventos de ruído (posição + volume).
- Esconderijos: `Area3D` com id. Neve: `GPUParticles3D`. Neblina: `WorldEnvironment` com fog volumétrico. Áudio: `AudioStreamPlayer3D`.
- Ciclo: cada transformação grava um novo registro com as rotas daquela partida.

## Convenções

- GDScript com **tipagem estática** em tudo (variáveis, parâmetros, retornos).
- **Cenas pequenas e reaproveitáveis**; uma responsabilidade por cena/script.
- **Nomes de arquivos e nós em inglês** (`snake_case` para arquivos, `PascalCase` para nós e `class_name`).
- **Comentários em português.**
- **Placeholders** (formas CSG, materiais simples) em vez de assets elaborados por enquanto.
- Gameplay que o `TutorialRecorder` vai precisar gravar (fogueira acesa, esconderijo, item guardado etc.) deve emitir sinais/eventos desde já, mesmo antes do recorder existir.
- Quando algo depender de uma questão em aberto, deixe parametrizado (`@export`, constante ou enum) em vez de fixar uma resposta.

## Fluxo de trabalho

- Uma fase por vez. Antes de cada fase, mostrar um plano curto (arquivos, cenas, scripts). Ao terminar, explicar como testar no editor e **parar para validação**.
- Quando a fase atual depender de uma questão em aberto, **perguntar antes**, com recomendação. Nunca decidir sozinho.
- Quando uma questão for respondida, movê-la para `docs/DECISOES.md` (com data e motivo) e removê-la da lista abaixo.
- Commits pequenos e descritivos, se o projeto estiver num repositório git.

### Fases do MVP
1. **Base:** movimento em primeira pessoa, interação, cabana e terreno de teste. *Pronto quando* dá para andar, pegar lenha e acender fogo.
2. **Sobrevivência:** medidores, dia/noite, comida e frio. *Pronto quando* dá para morrer de frio ou de fome.
3. **Tutorial:** colega, eventos roteirizados, morte e canibalismo, registro do tutorial.
4. **Wendigo:** IA com patrulha baseada no registro, perseguição, medo de fogo.
5. **Ciclo e polimento.**

Fora do MVP: coração de gelo, imitação de voz, corrupção completa, ciclo, personagens sorteados, crafting expandido.

## Questões em aberto

NÃO decidir sozinho. Perguntar quando a fase atual depender de uma delas.

Numeração original mantida; as respondidas (2, 3, 6, 8) estão em `docs/DECISOES.md`.

1. Título final do jogo.
4. Existe forma de reduzir a corrupção, e quão rara ela é?
5. Quanto tempo é preciso sobreviver até o resgate?
7. Quantos wendigos do ciclo podem existir no mapa ao mesmo tempo?
9. Morte comum (frio, fome, wendigo) também alimenta o ciclo, ou só a transformação?
