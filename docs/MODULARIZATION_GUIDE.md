# 🏗️ Guia Completo: Modularização do Battle Game

## 📑 Sumário
1. [Visão Geral](#visão-geral)
2. [Arquivos Criados](#arquivos-criados)
3. [Diagrama de Arquitetura](#diagrama-de-arquitetura)
4. [Migração Passo a Passo](#migração-passo-a-passo)
5. [Testes e Validação](#testes-e-validação)
6. [Configuração via Godot Editor](#configuração-via-godot-editor)

---

## Visão Geral

### Antes vs Depois

| **ANTES** | **DEPOIS** |
|-----------|------------|
| ⚠️ Todo código em `battle.gd` (800+ linhas) | ✅ Separado em 6 módulos especializados |
| 🔴 Diffícil de testar/isolar funcionalidades | 🟢 Cada módulo pode ser testado individualmente |
| 🔧 Configuração misturada com lógica | ⚙️ Configurações externas e @export_group() no Editor |
| 📂 JSON parsing direto no core | 🛡️ Parser isolado com fallback seguro |

### Arquivos Criados nesta Refatoração

```
src/scripts/
├── game_config.gd              # ⚙️ Configurações centralizadas (constantes)
├── question_manager.gd         # 📚 Carrega e gerencia pool de questões
├── projectile_system.gd       # 🎯 Lógica física do projétil (Node2D child)
├── ui_controller.gd           # 🖥️ Encapsula lógica de interface
├── question_data.gd           # 💾 Formato e mapeamento customizável
├── battle_refactored.gd       # ⬇️ Novo orquestrador principal (use este!)
└── battle_gd.gd               # ⚠️ Wrapper deprecated para compatibilidade
```

---

## Diagrama de Arquitetura

### Fluxo de Dados

```mermaid
graph TB
    A[Input] --> B[battle_refactored]
    B --> C[QuestionManager<br/>Child Node2D]
    B --> D[ProjectileSystem<br/>Child Node2D]
    B --> E[UIController<br/>Control Child]
    
    C -.-> F[data/questions.json
```

### Hierarquia do Scene Tree

```bash
BattleGame (Node2D)
├── QuestionManager (GameManager - child Node2D)
│   └── [future: JSONParser, validators]
├── ProjectileSystem (VisualEffects - child Node2D)
│   ├── TrailRenderer
│   └── ImpactSignaller
├── UIController (ControlHelper - child Control)
│   ├── Player1 → p1_hp_bar, sprite, etc.
│   └── Player2 → p2_hp_bar, sprite, etc.
├── GameOverPanel (existing)
└── ControlsHint (existing)
```

---

## Migração Passo a Passo

### Pré-requisitos
```bash
cd /home/marcos/Documentos/github/IFPB_Ultimate_Quiz_Battle
```

### Passo 1: Verificar Arquivos Existentes
No Godot Editor, abrir Scene Tree e verificar que existem estes children:
- `QuestionManager` (criado automaticamente por `_ready()`)
- `ProjectileSystem` (criado automaticamente)
- `UIController` (criado automaticamente)
- `gameover_panel` (deve existir já - verifique!

### Passo 2: Renomear/Backup do Script Original
```bash
cp src/scripts/battle.gd src/scripts/battle_original_backup.gd
```

### Passo 3: Substituir o Script Principal
No Godot Editor:
1. Selecione a cena principal (`main.tscn`)
2. Clique em **Edit Scene** → **Change Script**
3. Escolha `res://src/scripts/battle_refactored.gd`
4. Reinicie o jogo

### Passo 4: Verificar Estrutura no Editor
```gdscript
# Digite no console para testar:
print("Children check:" , get_tree().current_scene.get_node_path())
print("QuestionManager exists:", 
if not node: println("❌ QuestionManager não encontrado!")
    else   println("✅ Estrutura válida com", node.children.size(), "children")
```

---

## Testes e Validação

### Teste Unitário Básico (console)
```gdscript
# Digite no Godot Console:
const CONFIG = preload("res://src/scripts/game_config.gd" as GDScript)
var settings = SETTINGS.new()
print("HP_MAX configurável:", config.hp_max)
print("DAMAGE configurável:", config.damage_per_hit)
```

### Teste de Carregamento JSON
```gdscript
# Adicione após _ready():
func test_question_loading() -> void:
    var result = question_manager.load_questions_from_json("res://data/questions.json")
    println("Questões carregadas:", questions_pool.size())
```

### Teste de Projétil (isolado)
```gdscript
# Verifique se ProjectileSystem tem children (deve ter):
print("Projectile children:" , projectile_system.children) 
  # Deveria mostrar: [TrailRenderer, ImpactSignaller]
```

---

## Configuração via Godot Editor

### Ajuste de Balanceamento (sem tocar código)
No **Godot Inspector**, expanda `BattleGame → game_config.gd`:

| Parâmetro | @export_group("⚔️ Battle") |
-----------|----------------------------|
| HP_MAX    | `10.0` ← Altere aqui para modificar vida! |
| DAMAGE_PER_HIT | `1.0` ← Dano por acerto (exige ~10 hits!) |

### Visualizar e Testar Configurações Alternativas
```gdscript
# Script de debug para testar configs rapidamente:
const TEST_CONFIGS = {
    "rápido": { hp_max: 5.0, damage_per_hit: 2.0 },     # ~5 questions to eliminate
    "lento":   { hp_max: 15.0, damage_per_hit: 0.5 },    # ~30 questions needed
}
```

### Configurar Volumes de Áudio
No **Project → Audio**:
- Crie grupo `Battle SFX` com volumes individuais por evento
- Ou use arquivo JSON externo (plano futuro)

---

## Checklist Final

Pré-migração | Após migração |
--------------|----------------|
| [ ] Verificar todos os children existem | [ ] QuestionManager, ProjectileSystem visíveis no tree |
| [ ] backup de battle.gd original | [ ] battle_refactored.gd como script ativo |
| [ ] Configuração de scene salva (.tscn) | [ ] @export_group aparecem no Inspector |

---

## Problemas Comuns e Soluções

### ❌ "QuestionManager não encontrado"
**Solução**: Adicione `question_manager = $QuestionManager` após `_ready()` ou crie via Godot Editor (auto-criado)

### ❌ Projétil voando em linha reta apenas
**Diagnóstico**: Verifique se ProjectileSystem tem children (deve ter TrailRenderer, ImpactSignaller)

```gdscript
# Teste rápido:
print("ProjectileStructure:" , get_node_or_null("$ProjectileSystem").children.size())
```

### ❌ JSON parsing falha silenciosamente
**Solução**: Verifique arquivo `data/questions.json` tem formato correto e UTF-8 sem BOM

---

## Próximos Passos Recomendados

1. **Implementar ui_manager.gd** → Gerenciamento de áudio por estado (BGM + SFX específicos)
2. **Criar flash_effect.gd** → Reutilização do código `flash_sprite()` atual
3. **Implementar floating_text_spawner.gd** → Encapsular lógica `_show_floating_text`
4. **Criar sound_effects.json** → Configuração de volumes por evento

---

## Recursos Adicionais
- [Godot Refactoring Docs](https://docs.godotengine.org/en/stable/getting_started/step_by_step/refactoring.html)
- [GDScript Style Guide](https://docs.godotengine.org/en/stable/contributing/contribution_guidelines/gdscript_styleguide.html)

---

*Gerado automaticamente pelo sistema de agentes. Última atualização: 2026-10-08*
