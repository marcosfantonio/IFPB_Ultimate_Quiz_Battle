# Arquitetura do jogo

`main.tscn` é a cena raiz e compõe o cenário, os sistemas persistentes e as telas principais.
`battle.gd` é o **orquestrador**: obtém os nós da cena, liga os sinais e controla a fase
(`GamePhase.State`). Cada módulo faz uma coisa.

O cenário fica no canvas do mundo; as telas, HUD e projétil ficam sob uma `CanvasLayer` para
compartilhar o mesmo espaço de coordenadas e ordem de desenho. A viewport 1152×648 mantém a
proporção 16:9 com letterbox em janelas de outra proporção, preservando os layouts fixos.

Os layouts estáticos vivem em `src/scenes/` e podem ser editados no Godot. A interface de jogo
é composta por cenas reutilizáveis (`BattleHud`, `PlayerPanel`, `QuestionPanel` e `LabelPlate`).
Conteúdo que varia em quantidade — como alternativas, questões e campos do banco — continua sendo
instanciado por código a partir desses componentes.

`main.tscn` mostra o menu inicial e o fundo compartilhado. Para visualizar telas que começam
ocultas no fluxo do jogo, abra sua cena em `src/scenes/ui/`. Os scripts de preview do HUD usam
`@tool` para aplicar no editor as mesmas posições e configurações usadas durante a partida.

Regras de dependência:
- `core/` e `data/` não dependem de `systems/` nem de `ui/`.
- Os módulos de `systems/` só dependem de `core/` e `data/`; **nunca uns dos outros nem da UI**.
  Quem os conecta entre si e com a UI é o `battle.gd`, por sinais.
- Dentro de `ui/` há composição normal: `BattleHud` instancia os painéis, e os painéis
  reutilizam `LabelPlate` e `UITheme`.

```
src/scenes/
├── systems/                   # cenas-raiz dos nós de áudio, rodada, entrada, idle e projétil
├── materials/                 # materiais reutilizáveis, como o brilho da logo
└── ui/                        # HUD, painéis, telas e componentes visuais reutilizáveis

src/scripts/
├── battle.gd                  # orquestrador de main.tscn
├── core/
│   ├── game_config.gd         # constantes: HP, dano, projétil, tempos, teclas, cores dos jogadores
│   ├── game_assets.gd         # preloads de fonte, texturas e sons
│   ├── game_phase.gd          # enum de fases (START_SCREEN, QUESTION, ...)
│   └── match_state.gd         # vida dos jogadores + vencedor (sinal hp_changed)
├── data/
│   ├── question.gd            # uma pergunta validada
│   ├── question_repository.gd # carrega o JSON, sorteia sem repetir, fallback
│   └── question_style.gd      # texto/cor das tags de dificuldade e categoria
├── systems/
│   ├── round_controller.gd    # regras da rodada: trava, quem errou, próxima pergunta
│   ├── projectile.gd          # voo em arco + rastro; emite `hit`
│   ├── input_router.gd        # tecla -> sinal (start_requested / answer_requested)
│   ├── audio_manager.gd       # BGM e SFX
│   └── idle_animator.gd       # troca de pose dos alunos
└── ui/
    ├── battle_hud.gd          # agrupa a UI de gameplay
    ├── player_panel.gd        # nome, barra de vida, sprite, flash
    ├── question_panel.gd      # enunciado, tags e alternativas
    ├── controls_hint.gd       # faixa de teclas (gerada do GameConfig)
    ├── game_over_panel.gd     # vencedor + reiniciar
    ├── start_screen.gd        # logo + "Pressione Enter"
    ├── floating_text.gd       # "ACERTOU!" / "ERROU!"
    ├── label_plate.gd         # Label sobre placa preta (componente reutilizável)
    └── ui_theme.gd            # aplica a fonte do jogo
```

## Fluxo

```
InputRouter ──answer_requested──▶ Battle ──▶ RoundController.submit_answer()
RoundController ──question_started──▶ Battle ──▶ QuestionPanel + AudioManager
RoundController ──answer_resolved───▶ Battle ──▶ destaque, texto flutuante, SFX
                                              └─ acertou ▶ Projectile.launch()
RoundController ──retry_unlocked────▶ Battle ──▶ QuestionPanel.reset_highlights()
                  (errou, o outro jogador ainda pode tentar)
Projectile ──hit──▶ Battle ──▶ MatchState.apply_damage() ──hp_changed──▶ BattleHud
                          └─ fim? GameOverPanel : RoundController.start_round()
```

## Onde mexer

| Quero...                              | Arquivo                                  |
|---------------------------------------|------------------------------------------|
| Mudar vida, dano, velocidade, tempos  | `core/game_config.gd`                    |
| Trocar teclas ou cor de um jogador    | `core/game_config.gd` (`PLAYERS`)        |
| Nova categoria ou cor de dificuldade  | `data/question_style.gd`                 |
| Trocar sprite, som ou fonte           | `core/game_assets.gd`                    |
| Regra de quem pode responder          | `systems/round_controller.gd`            |
| Visual do projétil                    | `systems/projectile.gd`                  |
| Layout de uma parte da tela           | o arquivo correspondente em `ui/`        |
