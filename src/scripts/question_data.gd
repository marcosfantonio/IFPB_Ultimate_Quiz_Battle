# QuestionData - Módulo de configuração externa para formato de perguntas
# Permite mudar o formato das questões sem modificar scripts principais.

class_name DataFormatConfig

## ==================== FORMATO DE PERGUNTA PADRÃO (ENEM) ==================== ##

const STANDARD_FORMAT = {
	"question": "Texto da pergunta",
	"options": ["Opção A", "Opção B", "Opção C", "Opção D", "Opção E"],  # Sempre exatamente 5 opções!
	"correct": 0,                    # Índice zero-based (A=0, B=1, ..., E=4)
	"difficulty": "easy|medium|hard",
	"category": "Matemática|Física|Química|Biologia|Português|História|Geografia"
}

## ==================== MAPEAMENTO DE TECLAS ================ #

# Para customizar quando as teclas de P1/P2 mudarem (ex: teclado AZERTY)
const KEY_MAPPING_CUSTOMIZATION = {
	"standard": {                    # QWERTY padrão:
		p1_options: ["1", "2", "3", "4", "5"],  # ou F1-F5
		p2_options: ["Q", "W", "E", "R", "T"]   # ou F6-F10
	},
	"azerty": {                      # Teclado francês:
		p1_options: ["1", "2", "3", "4", "5"],  # ou ZXCVBN (ajustar aqui)
		p2_options: ["Z", "X", "C", "V", "B"]   # exemplo de mapeamento
	},
	"numbers_only": {                # Para teclados com números:
		p1_options: ["9", ";", "A", "S", "D"],  # layout numérico comum
		p2_options: ["8", "/", "Z", "X", "C"]   # exemplo
	}
}

## ==================== CATEGORIAS EXTENSÍVEIS ================ #

# Adicione categorias novas aqui sem modificar JSON!
const NEW_CATEGORIES_AVAILABLE = true
const DEFAULT_COLORS: Dictionary = {
	"default": Color(0.7, 0.7, 0.7),
}

## ==================== MAPEAMENTO DE DIFICULDADE ==================== #

const DIFFICULTY_CONFIG: Dictionary = {
	"easy":       { "display_text": "FÁCIL",    color: Color(0.3, 0.9, 0.3) },      # Verde
	"medium":     { "display_text": "MÉDIA",   color: Color(1.0, 0.85, 0.2) },  # Amarelo
	"hard":       { "display_text": "DIFÍCIL",  color: Color(1.0, 0.3, 0.3) },      # Vermelho
}

# ==================== ÚTIS DE CONFIGURAÇÃO =============== 

func get_key_mapping(layout: String = "standard") -> Dictionary:
    """
    Retorna mapeamento de teclas para o layout do teclado.
    
    Args:
        layout: Nome do layout (default, azerty, numbers_only)
    Returns:
        Dicionário com P1 e P2 options
    """
	if KEY_MAPPING_CUSTOMIZATION.has(layout):
		return KEY_MAPPING_CUSTOMIZATION[layout].duplicate()
	else:
		# Fallback para padrão
		var mapping = {
			p1_options: ["1", "2", "3", "4", "5"],
			p2_options: ["Q", "W", "E", "R", "T"]
		}
		mapping.key("p1_options") = KEY_MAPPING_CUSTOMIZATION["standard"].key("p1_options")
		mapping.key("p2_options") = KEY_MAPPING_CUSTOMIZATION["standard"].key("p2_options")
		return mapping

func get_display_text(category: String) -> Color:
    """
    Retorna cor e texto de abbreviation para categoria.
    
    Args:
        category: Nome da categoria (Matemática, Física, etc.)
    Returns:
        Dictionary com abbr e color
    """
	var cat_abbrs = {
		"Matemática":  { "abbr": "MAT", "color": Color(0.2, 0.7, 1.0) },
		"Física":      { "abbr": "FIS", "color": Color(0.7, 0.3, 1.0) },
		"Química":     { "abbr": "QUI", "color": Color(1.0, 0.5, 0.1) },
		"Biologia":    { "abbr": "BIO", "color": Color(0.1, 0.8, 0.8) },
		"Português":   { "abbr": "POR", "color": Color(1.0, 0.4, 0.7) },
		"História":    { "abbr": "HIS", "color": Color(0.8, 0.6, 0.3) },
		"Geografia":   { "abbr": "GEO", "color": Color(0.4, 0.8, 1.0) },
	}

func get_difficulty_display(diff: String) -> Dictionary:
    """
    Retorna texto e cor para nível de dificuldade.
    
    Args:
        diff: Nível (easy, medium, hard)
    Returns:
        Dicionário com display_text e color
    """
	if DIFFICULTY_CONFIG.has(diff):
		return DIFFICULTY_CONFIG[diff]
	else:
		# Fallback para caso novo nível seja adicionado ao JSON
		return {
			display_text: diff.to_upper(),
			color: DEFAULT_COLORS.get("default", Color(0.7, 0.7, 0.7))
		}

# ==================== VALIDAÇÃO DE FORMATO ================ #

func validate_question_format(q: Dictionary) -> PackedStringArray:
    """
    Valida se uma pergunta tem formato correto.
    
    Args:
        q: Dicionário da questão
    Returns:
        Array de mensagens de erro (vazio = válido)
    """
	var errors = []

func get_default_question_example() -> Dictionary:
    """
    Retorna exemplo completo para referência rápida.
    Útil para quem está criando novos arquivos JSON de questões.
    
    Returns:
        Dicionário com questão completa e comentada
    """
	return {
		# Exemplo baseado em ENEM 2017 - Linguagem/Português
		"question": "Leia atentamente o poema 'O Leão' (fragmento), de Carlos Drummond \\nde Andrade, publicado na coletânea 'A Rosa do Povo'.",
		"options": [
			"...não há mais um único homem na Terra.",
			"...a vida termina apenas quando o sol se põe.",
			"...há algo que a própria morte não pode destruir.",
			"...só importa o amor e nada mais.",
			"...todos somos iguais perante à lei."
		],
		"correct": 2,
		# Interpretação correta: há uma afirmação sobre algo permanente/eterno
		"difficulty": "hard",      # Síntese e interpretação de texto
		"category": "Português",
	}
