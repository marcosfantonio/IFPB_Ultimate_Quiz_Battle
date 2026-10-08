# IFPB Ultimate Quiz Battle — Agent Quick Reference

## What this is
Godot 4.7 game (Forward Plus renderer, Jolt Physics) for an educational PJ2 project. Two players compete by answering ENEM-style questions; correct answers launch projectiles that deal damage to the opponent.

---

## How to run

```bash
# From repo root:
godot --path src/src    # Opens Godot with main scene pre-loaded
```

Main scene: `src/main.tscn` → Script: `src/scripts/battle.gd`

---

## Key operational notes for agents

### Asset dependencies (must exist at runtime)
| Path | Purpose |
|------|---------|
| `assets/cenario.png` | Background texture (2560×1440) |
| `assets/player/aluno1.png` | Player 1 sprite |
| `assets/player/aluno2.png` | Alternate player sprite |
| `assets/interface/logo.png` | Start screen logo |
| `assets/interface/opcoes.png` | Options menu button texture |
| `assets/fontes/upheavtt.ttf` | Custom font (all labels) |
| `assets/sounds/*.wav` | Effect sounds |
| `assets/sounds/main_theme.mp3` | Background music |

### Question data flow
1. Game loads `data/questions.json`
2. If file invalid or empty → uses 5 fallback questions hardcoded in `_fallback_questions()`
3. Each question has: `question`, `options[5]`, `correct(index)`, `difficulty`, `category`
4. Questions are randomized but tracked via `used_indices` array

- Always use the 'read_file' tool before editing any .gd script to confirm exact indentation and spaces.
- In 'old_string', match exact tabs or spaces used in the GDScript file.
- Do not summarize functions with '# ... code ...' inside old_string.
- Keep GDScript indentation consistent (tabs vs spaces).

### Important constants for debugging/modification
| Constant | Value |
|----------|-------|
| `HP_MAX` | 10.0 |
| `DAMAGE` | 1.0 (per projectile) |
| `PROJECTILE_SPEED` | 600 units/sec |

---

## Common operations

### Adding questions
Add entries to `data/questions.json`. Format:
```json
{
  "question": "...",
  "options": ["A", "B", "C", "D", "E"],
  "correct": <0-4>,      # zero-indexed position
  "difficulty": "easy|medium|hard",
  "category": "Matemática|Física|..."
}
```

### Exporting the game
```bash
godot --path src/src --export-release "platform_name" \
  -e res://export_presets.cfg          # List platforms
  -p platform/export_index             # Build for specific platform
```

---

## No existing CI/build tooling needed to set up yet
