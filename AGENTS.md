# AGENTS.md — IFPB Ultimate Quiz Battle

Leia este arquivo antes de mexer no projeto. Detalhes da arquitetura: `docs/ARCHITECTURE.md`.

## O que é o jogo

Jogo local para 2 jogadores em **Godot 4.x** (GDScript). Os dois veem a mesma pergunta
(estilo ENEM, 5 alternativas) e disputam quem responde primeiro.

- Acertou: lança um projétil no oponente (-1 HP). Cada jogador começa com 10 HP.
- Errou: fica travado naquela pergunta; o outro jogador ainda pode responder.
- Os dois erraram: passa sozinho para a próxima pergunta.
- Alguém chega a 0 HP: tela de fim de jogo com botão de reiniciar.
- Não há timer por pergunta.

Controles: **Enter** inicia · **P1** teclas `1 2 3 4 5` · **P2** teclas `Q W E R T`.

## Estrutura do repositório

```
/                      # raiz do repo
├── src/               # PROJETO GODOT (res:// aponta para cá)
│   ├── project.godot  # cena principal: res://main.tscn, tela 1152x648
│   ├── main.tscn      # Node2D "Main" (script battle.gd) + Background
│   ├── data/questions.json   # banco de perguntas USADO pelo jogo
│   ├── assets/        # background/ fontes/ interface/ musics/ player/ sounds/
│   └── scripts/       # todo o código (ver abaixo)
├── docs/              # ARCHITECTURE.md, GDD.docx
├── data/questions.json       # cópia antiga, JSON INVÁLIDO, ignorada pelo jogo
└── AGENTS.md
```

## Onde está cada coisa (`src/scripts/`)

| Arquivo | Responsabilidade |
|---|---|
| `battle.gd` | **Orquestrador.** Cria módulos, liga sinais, controla `GamePhase`. Sem lógica de regra nem layout. |
| `core/game_config.gd` | Todas as constantes: HP, dano, velocidade/arco do projétil, tempos, teclas, cores e posições dos jogadores (`PLAYERS`). |
| `core/game_assets.gd` | `preload` de fonte, texturas e sons; enum `Sfx`. |
| `core/game_phase.gd` | Enum `State`: START_SCREEN, WAITING, QUESTION, PROJECTILE, GAME_OVER. |
| `core/match_state.gd` | HP dos jogadores, vencedor. Sinal `hp_changed`. |
| `data/question.gd` | Uma pergunta validada (`Question.from_dict`). |
| `data/question_repository.gd` | Lê o JSON, sorteia sem repetir até esgotar, fallback de 5 perguntas. |
| `data/question_style.gd` | Texto/cor das tags de dificuldade e categoria. |
| `systems/round_controller.gd` | Regras da rodada: trava, quem errou, próxima pergunta. |
| `systems/projectile.gd` | Voo em arco + rastro. Emite `hit(attacker)`. |
| `systems/input_router.gd` | Tecla → sinal (`start_requested`, `answer_requested`). |
| `systems/audio_manager.gd` | BGM e SFX (`play_sfx(GameAssets.Sfx.X)`). |
| `systems/idle_animator.gd` | Troca aleatória de pose dos alunos (`pose_changed`). |
| `ui/battle_hud.gd` | Agrupa UI de gameplay; `get_panel(player)`. |
| `ui/player_panel.gd` | Nome, barra de HP, sprite, flash, pontos de origem/alvo do projétil. |
| `ui/question_panel.gd` | Enunciado, tags, 5 alternativas, destaque certo/errado. |
| `ui/game_over_panel.gd` | Vencedor + botão "Jogar Novamente" (`restart_requested`). |
| `ui/start_screen.gd` | Logo, botão de opções, "Pressione Enter". |
| `ui/floating_text.gd` | "ACERTOU!"/"ERROU!" que sobe e some. |
| `ui/controls_hint.gd` | Faixa inferior de teclas, gerada do `GameConfig`. |
| `ui/label_plate.gd` | Componente: Label sobre placa preta translúcida. |
| `ui/ui_theme.gd` | Aplica a fonte `upheavtt.ttf` (raiz é Node2D, Theme não propaga). |

## Tarefas comuns

| Quero... | Faça em... |
|---|---|
| Mudar HP, dano, velocidade, tempos | `core/game_config.gd` |
| Trocar teclas / cor / posição de um jogador | `core/game_config.gd` → `PLAYERS` |
| Adicionar perguntas | `src/data/questions.json` (formato abaixo) |
| Nova categoria ou cor de dificuldade | `data/question_style.gd` |
| Trocar sprite, som, fonte | arquivo em `src/assets/` + `core/game_assets.gd` |
| Mudar regra de quem pode responder | `systems/round_controller.gd` |
| Mudar visual do projétil | `systems/projectile.gd` |
| Mexer em layout de uma parte da tela | o arquivo correspondente em `ui/` |
| Nova mecânica que envolve vários módulos | ligar os sinais em `battle.gd` |

### Formato de `questions.json`

```json
{ "questions": [
  { "question": "Texto", "options": ["A","B","C","D","E"], "correct": 1,
    "difficulty": "easy|medium|hard", "category": "Física" }
] }
```
`options` precisa ter de 2 a 5 itens e `correct` é o índice (0-based). Entradas inválidas são
ignoradas com `push_warning`. Categorias com estilo próprio: Matemática, Física, Química,
Biologia, Português, História, Geografia (outras funcionam, com cor cinza).

## Convenções do código

- **Indentação com TAB** (padrão do GDScript/Godot). Texto de UI em **português**.
- **Sinais sobem, chamadas descem:** módulos emitem sinais; só `battle.gd` conecta módulos entre si.
  Os módulos de `systems/` dependem apenas de `core/` e `data/`, nunca uns dos outros nem da UI.
  Dentro de `ui/` composição é normal (o `BattleHud` instancia os painéis, que usam `LabelPlate`).
- **Constantes só em `GameConfig`**; caminhos de assets só em `GameAssets`. Sem números mágicos espalhados.
- **UI construída por código** (a cena só tem o Background). Reaproveite `LabelPlate` em vez de
  recriar MarginContainer + ColorRect + Label.
- Novo módulo = novo arquivo com `class_name` na pasta certa (`core/ data/ systems/ ui/`).
- Prefira tipagem explícita. `:=` não infere tipo de valor que vem de Dictionary/Variant; use `var x: Tipo = ...`.
- Commite os arquivos `.gd.uid` gerados pelo Godot.

## Rodar e testar

- Abra `src/` no editor Godot 4 e rode (F5). Na primeira abertura o editor registra os `class_name`;
  sem isso, rodar por linha de comando pode falhar com "identifier not declared".
- Não há testes automatizados. Valide jogando uma partida completa: iniciar, acertar, errar,
  os dois errarem, chegar a 0 HP, reiniciar.

## Armadilhas e pendências conhecidas

- `data/questions.json` na **raiz** é inválido e não é usado; o válido é `src/data/questions.json`.
- `src/program.gd` e os `.import` soltos em `src/assets/` (aluno1/2, cenario, logo, upheavtt) são restos sem uso.
- Arquivos `.af` são fontes do Affinity; não são assets do jogo.
- O botão de opções da tela inicial só toca um som e imprime no console.
- O código não configura loop da música de fundo.
- Ideias do roadmap **ainda não implementadas**: timer de resposta, streaks/power-ups, modos extras, estatísticas pós-partida.
