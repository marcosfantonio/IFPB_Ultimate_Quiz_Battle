# AGENTS.md — Ultimate Quiz Battle (Godot 3.7)

## Visão Geral do Projeto

**Ultimate Quiz Battle** é um jogo multiplayer local desenvolvido em Godot 3.7, onde dois jogadores competem respondendo questões de provas ENEM vestibular.

### Mecânicas Principais:
- 📚 **Banco de perguntas**: Questões reais de ENEM (2017-2023) + matemática/física
- 💥 **Sistema de combate**: Cada resposta correta lança um projétil que causa 1 HP de dano ao oponente
- ⏱️ **Duração da partida**: Aproximadamente 8 minutos com ~45 questões (todo pool consumido)
- 🎯 **Feedback visual**: Efeitos de partículas, texto flutuante "ACERTOU!"/"ERROU!", flash no alvo
- 💀 **Game Over quando um jogador chega a 0 HP**

---

## Estrutura Técnica & Arquivos

### Scripts Principais
| Arquivo | Descrição |
|---------|------------|
| `src/scripts/battle.gd` | Script principal (Node2D) - lógica completa do jogo |
| `src/program.gd` | Programa Godot (GDScript, 1.5 KB) - config global/mostrador de FPS |
| `src/character_body_2d.gd` | PhysicsMaterial para colisão dos personagens |

### Recursos Importados
- **Cenário**: `res://assets/cenario.png` (1152×648)
- **Fontes**: TTFF (Upheav), WOFF2 para UI estilizada
- **Sprites**: Aluno1/aluno2, logo/interface assets

### Assets de Áudio
| Arquivo | Uso |
|---------|-----|
| `acerto.wav` | Som de acerto (+projétil) |
| `erro.wav` | Som de erro (resposta incorreta) |
| `novaquestao.wav` | Transição entre questões |
| `select.wav` | Seleção UI |

---

## Dados do Jogo

### Perguntas Importadas (`data/questions.json`)
```jsonl
{
  "question": "Questão ENEM ou acadêmica",
  "options": ["Opção A", "Opção B", "Opção C", "Opção D", "Opção E"],
  "correct": 2,        # Índice da resposta correta (0-4)
  "difficulty": "easy|medium|hard",
  "category": "Matemática/Física/Química/Biologia/Português/História/Geografia"
}
```

**Formato de Opções:**
```text
[1/Q] Opção A     ← Player 1 usa [1], Player 2 usa [Q]
[2/W] Opção B     ← Key mappings diferentes por jogador
[3/E] ...
[4/R] ...
[5/T] ...         ← Garante compatibilidade entre layouts de teclado |
```

---

## Fluxo do Jogo (Máquina de Estados)

```mermaid
graph LR
    START -->|Enter| WAITING
    WAITING -->|Start Q | QUESTION
    QUESTION -->|Answer 1/2| PROJECTILE
    PROJECTILE -->|Hit Target| GAME_OVER
    GAME_OVER -->|Restart| WAITING
    
    QUESTION -- Erro P1 --> LOCKED_P2
    QUESTION -- Erro P2 --> LOCKED_P1
    LOCKED_PX -- Tempo esgotado | Next Question|
```

### Estados Detalhados:
- **`GameState.START_SCREEN`** - Tela inicial com logo e instruções
- **`GameState.WAITING`** - Preparando próxima questão
- **`GameState.QUESTION`** - Apresentando pergunta (input ativo)
- **`GameState.PROJECTILE`** - Projétil em voo entre jogadores
- **`GameState.GAME_OVER`** - Tela de resultados

---

## Configurações & Constantes Importantes

| Variável | Valor | Significado |
|----------|-------|-------------|
| `HP_MAX` | 10.0 | Vida máxima por jogador |
| `DAMAGE` | 1.0 | Dano por acerto (exige ~10 questões para eliminar) |
| `PROJECTILE_SPEED` | 600 px/frame | Velocidade do projétil |
| `TRAIL_WIDTH` | 4.0 | Largura da estilhaça do projétil |
| **Tempo por pergunta** | 35 segundos | Configuração padrão (`WAIT_TIME`) |

---

## Controles dos Jogadores

### Player 1 (Vermelho/🔴) - Digita: 1,2,3,4,5 ou F1-F5
| Ação | Tecla(s) |
|------|----------|
| Opção A/B/C/D/E | `1` `2` `3` `4` `5` |
| Atalhos de teclas | `F1`, `F2`, `F3`, `F4`, `F5` |

### Player 2 (Azul/🔵) - Digita: Q,W,E,R,T ou F6-F10
| Ação | Tecla(s) |
|------|----------|
| Opção A/B/C/D/E | `Q` `W` `E` `R` `T` |
| Atalhos de teclas | `F6`, `F7`, `F8`, `F9`, `F10` |

### Controles Globais:
- **Enter** (Start Screen) - Iniciar jogo

---

## Arquivos-Chave para Análise/Modificação

| Caminho | Finalidade Típica |
|---------|-------------------|
| `src/scripts/battle.gd` | Adicionar mecânicas, balanceamento de HP/dano |
| `data/questions.json` | Expandir banco de questões |
| `res://assets/` | Substituir sprites, sons ou cenário |
| `scripts/ui_manager.gd` (se existir) | Personalizar feedback visual |

---

## Perguntas Comuns dos Desenvolvedores

### 📊 Balanceamento e Design
- **"Como ajustar o HP/DANO para partidas mais curtas?"** → Reduzir ambos proporcionalmente, mas manter mesma razão
- **"Adicionar timer de resposta?"** → Implementar no `_process()` com timeout antes do próximo turno
- **"Criar modo time attack (infinito)?"** → Modificar `_load_questions()` para não usar pool completo

### 🎨 Personalização Visual
- **"Trocar cores dos jogadores?"** → Editar no `_build_ui()`, procurar por `Color(1, 0.35, 0.35)` (P1 vermelho) e similar P2 azul
- **"Mudar velocidade do projétil para mais dramático?"** → Aumentar `PROJECTILE_SPEED` em `battle.gd`

### 📚 Expansão de Conteúdo
- **Adicionar novas categorias?** → Atualizar mapeamento no `_start_question()`, atualizar `cat_colors` e `cat_abbr`
- **Diferentes níveis de dificuldade para o projétil?** → Modificar `_launch_projectile()` baseado em `current_question["difficulty"]`:
  ```gdscript
  var projectile_speed = PROJECTILE_SPEED
  if current_question.get("difficulty") == "hard":
      projectile_speed *= 1.5
  ```

---

## Arquitetura de Design (GDD)

### Princípios Fundamentais:
1. **Foco na jogabilidade →** Resposta rápida = acerto visual imediato
2. **Feedback loop rápido →** Projétil em voo conecta ação à consequência
3. **Balanceamento acessível →** 10 hits para eliminar (garante todas as perguntas sejam usadas)
4. **Tensão crescente →** Cada jogador sente os efeitos de cada erro do oponente
5. **Repetibilidade →** Pool infinito permite partidas longas sem repetir questões

---

## Comandos Úteis para Análise/Debug

### No Editor Godot:
```gdscript
# Verificar estado atual (no console):
print("Estado: ", state)
print("HP - P1: " , p1_hp, " |  P2: ", p2_hp)

# Forçar debug de input:
func _debug_input(event):
    if event.is_action_pressed("ui_select"):
        print("Debug Input at", get_scene_tree().current_scene.get_path())
```

### Verificar Performance:
```gdscript
# Adicionar no _process() para monitorar:
print("Frame: ", str(roundf(time_since_start, 0)), "| Projectile active: ", projectile_active)
```

---

## Roadmap Típico de Desenvolvimento

### Fase 1 (Jogabilidade Core) - ✅ COMPLETO
- [x] Sistema de perguntas JSON
- [x] Input dual-player
- [x] Projétil com física parabólica
- [x] UI de HP e feedback visual

### Fase 2 (Polimento) - EM ANDAMENTO
- [ ] Timer de resposta configurável
- [ ] Efeitos sonoros por categoria/pergunta
- [ ] Sistema de recompensa/streaks para acertos consecutivos

### Fase 3 (Expansão)
- [ ] Modos: "Team Battle", "Deathmatch infinito"
- [ ] Perguntas dinâmicas que mudam baseadas em estado do jogo
- [ ] Análise estatística pós-partida

---

## Exemplos de Implementação Rápida

### Adicionar Power-Up (Exemplo)
```gdscript
enum PowerUpType { SPEED, MULTIPLIER, SHIELD }

var current_powerup: PowerUpType = PowerUpType.NONE

# Ativar power-up ao acertar 3 perguntas seguidas:
func on_streak_achieven(level: int) -> void:
    if level >= 3 and randf() < 0.5:  # 50% chance
        current_powerup = PowerUpType.SPEED
        PROJECTILE_SPEED *= (2 + level / 10)
        print("POWER UP: Velocidade aumentada!")
```

### Adicionar Análise de Performance
```gdscript
# No _process(), monitorar tempo médio por pergunta:
func record_question_time() -> void:
    if last_question_start_time != 0:
        var duration = time - last_question_start_time
        avg_duration += duration
        count += 1
    
last_question_start_time = time
```

---

## Recursos Externos Úteis

- **Godot Documentation**: https://docs.godotengine.org/en/stable/
- **GDScript Reference**: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html
- **ENEM Questões Oficiais**: INEP — Portal do Educando |

---

## Notas de Manutenção

### Balanceamento:
- ⚠️ Se o jogo termina muito rápido → Aumente `DAMAGE` ou reduza `HP_MAX`
- ⚠️ Se jogadores estão hesitantes → Reduza tempo por pergunta
- ⚠️ Projétil travando? Verifique z-index e posições de `_launch_projectile()`

### Troubleshooting Comum:
| Problema | Solução |
|----------|---------|
| Input não registrado | Check se `locked` está true ou `failed_players.has(player)` |
| Projétil voa demais rápido | Ajustar `PROJECTILE_SPEED` e `TRAIL_WIDTH` |
| Texto flutuante sai da tela | Aumentar offset no `_show_floating_text()` |

---

*Gerado automaticamente pelo sistema de agentes. Última atualização: 2026-10-08*
