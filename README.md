# Fome Branca

> Este README é o prompt inicial para o Claude Code. Abra esta pasta no VS Code, inicie o Claude Code e peça: "Leia o README.md e siga as instruções". O documento de design completo está em `docs/GDD.md`.

---

Vamos começar o desenvolvimento do meu jogo "Fome Branca" (título provisório) em Godot 4 com GDScript. Abaixo está o resumo do documento de design. Leia tudo antes de começar. O documento completo está em `docs/GDD.md`; consulte quando precisar de detalhes.

## O jogo
Sobrevivência e horror em 3D, primeira pessoa, PC. A premissa: o monstro é o personagem que o jogador controlou no tutorial.

- **Tutorial (Ato 1):** dois amigos presos por uma nevasca numa cabana de caça num vale nevado. O jogador aprende a coletar lenha, acender fogo, caçar e racionar. O colega piora e morre. A comida acaba, e a única interação restante é o corpo. O jogador pode recusar algumas vezes (perdendo calor e força a cada recusa) até ceder. O personagem vira wendigo.
- **Partida (Ato 2):** "Três invernos depois", um novo personagem chega ao mesmo vale. Objetivo: sobreviver até o resgate ou destruir o coração de gelo do wendigo.
- **Ciclo de wendigos:** se o personagem da partida atingir corrupção total, ele vira o wendigo da próxima partida.

## Pilares
1. O monstro é você: o que o jogador faz no tutorial volta contra ele.
2. Sobrevivência simples, decisões pesadas.
3. A fome corrompe: carne humana é sempre tentadora e sempre cobra um preço.
4. Um mapa só (~1 km²), cada vez mais conhecido e mais assustador.

## Mecânicas
- **Recursos:** Calor, Fome, Luz (+ Corrupção). Calor cai ao ar livre, à noite e na nevasca; Fome cai com o tempo; Luz é o combustível de tocha/lanterna. Zerar Calor ou Fome mata. Sem Luz, o wendigo enxerga e você não.
- **Comida:** enlatados (pouco, sem corrupção), peixe/coelho (médio), carne crua (médio, corrupção leve), carne humana (muito alto, corrupção alta, dá calor e visão noturna temporários).
- **Corrupção em 4 estágios:** leve (sussurros, fome volta rápido) → média (vê no escuro, sente menos frio, wendigo às vezes ignora) → alta (comida comum quase não sacia, alucinações com a voz do colega, mãos mudam na câmera) → total (vira wendigo, fim da partida).
- **Ações:** coletar, fogueira, caçar, pescar no lago congelado, cozinhar, craft simples (tocha, armadilha, curativo, roupa de pele), esconder-se. Inventário limitado por peso.
- **Ciclo dia/noite e nevascas aleatórias.** À noite o wendigo caça ativamente.
- **Sem combate direto:** fogo afasta o wendigo, armadilhas atrasam, só o coração de gelo mata.
- **HUD mínimo:** estado mostrado no corpo/câmera (respiração, tremor, visão escurecendo); medidores só no diário/inventário.

## O Wendigo
- **Memória do tutorial (sistema central):** durante o tutorial, gravar sem o jogador saber: fogueiras acesas, esconderijos usados, onde dormiu, trilhas mais usadas (posição amostrada a cada poucos segundos), onde guardou itens, quantas vezes recusou o corpo. Na partida, o wendigo patrulha esses pontos com peso; os esconderijos favoritos são os primeiros que ele checa.
- **Estados:** Vagando → Desconfiado (ouviu ruído/viu luz) → Caçando (viu o jogador) → Recuando (fogo forte) → Atraindo (imita vozes se o jogador fica muito tempo escondido).
- Cresce, fica mais rápido e mais barulhento cada vez que come. Carrega objetos do personagem do tutorial. Se o jogador recusou muito o corpo, o wendigo hesita um instante ao vê-lo.
- Não entra em construção com fogueira acesa. O coração de gelo fica num local ligado ao tutorial e precisa de fogo intenso para ser destruído.

## Arquitetura sugerida
- Jogador: `CharacterBody3D` + `Camera3D`; interação por `RayCast3D` + método `interact()` nos objetos.
- Autoloads: `SurvivalStats` (calor, fome, luz, corrupção, com sinais ao mudar de estágio), `WorldClock` (dia/noite, `DirectionalLight3D`, nevascas), `TutorialRecorder` (grava os eventos do tutorial e salva em `user://` como Resource personalizado ou JSON).
- Wendigo: `CharacterBody3D` + `NavigationAgent3D` sobre `NavigationRegion3D`, máquina de estados; visão por `RayCast3D`/`Area3D`; o jogador emite eventos de ruído com posição e volume.
- Esconderijos: `Area3D` com id. Neve: `GPUParticles3D`. Neblina: `WorldEnvironment` com fog volumétrico (Forward+). Áudio: `AudioStreamPlayer3D`.
- No ciclo, cada transformação grava um novo registro com as rotas daquela partida, usado pelo wendigo seguinte.

## Escopo do MVP
Provar uma coisa: enfrentar um wendigo que usa suas próprias rotas do tutorial é assustador.
- Dentro: mapa pequeno (cabana, lago, floresta, um esconderijo); Calor/Fome/Luz; tutorial curto (15–20 min) terminando no canibalismo; registro do tutorial; wendigo com Vagando/Caçando/Recuando usando o registro; vitória por sobreviver até o resgate.
- Fora (depois): coração de gelo, imitação de voz, corrupção completa, ciclo, personagens sorteados, crafting expandido.

Fases:
1. **Base:** movimento em primeira pessoa, interação, cabana e terreno de teste. Pronto quando dá para andar, pegar lenha e acender fogo.
2. **Sobrevivência:** medidores, dia/noite, comida e frio. Pronto quando dá para morrer de frio ou de fome.
3. **Tutorial:** colega, eventos roteirizados, morte e canibalismo, registro do tutorial.
4. **Wendigo:** IA com patrulha baseada no registro, perseguição, medo de fogo.
5. **Ciclo e polimento.**

## Questões em aberto
Ainda não decidi isto. NÃO decida sozinho: quando a fase atual depender de uma delas, me pergunte antes, com sua recomendação. Até lá, deixe o código preparado para qualquer resposta.
1. Título final do jogo.
2. Como o colega morre: ferimento, febre ou hipotermia?
3. O canibalismo no tutorial é mostrado ou só sugerido (tela escura, som)?
4. Existe forma de reduzir a corrupção, e quão rara ela é?
5. Quanto tempo é preciso sobreviver até o resgate?
6. O jogador pode rejogar o tutorial para gerar um wendigo diferente?
7. Quantos wendigos do ciclo podem existir no mapa ao mesmo tempo?
8. Vozes: dubladores ou vozes sintéticas no protótipo?
9. Morte comum (frio, fome, wendigo) também alimenta o ciclo, ou só a transformação?

## Como quero trabalhar
- Primeiro, verifique o estado da pasta e se o Godot está disponível na linha de comando (`godot --version`). Se não estiver, me diga.
- Crie um `CLAUDE.md` na raiz com este resumo, as convenções do projeto e a lista de questões em aberto, e um `docs/DECISOES.md` onde cada decisão tomada fica registrada com data e motivo. Quando eu responder uma questão em aberto, mova ela para `DECISOES.md`.
- GDScript com tipagem estática, cenas pequenas e reaproveitáveis, nomes de arquivos e nós em inglês, comentários em português.
- Use placeholders (formas CSG, materiais simples) em vez de assets elaborados por enquanto.
- Trabalhe uma fase por vez. Antes de começar cada fase, me mostre um plano curto (arquivos, cenas, scripts). Ao terminar, diga como testar no editor e pare para eu validar.
- Commits pequenos e descritivos, se o projeto estiver num repositório git.

Comece pela Fase 1.
