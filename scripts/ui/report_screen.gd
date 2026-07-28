class_name ReportScreen
extends VBoxContainer

signal return_to_guild_requested

@onready var title_label: Label = %ReportTitleLabel
@onready var summary_label: RichTextLabel = %ReportSummaryLabel
@onready var discoveries_label: RichTextLabel = %ReportDiscoveriesLabel
@onready var trust_label: RichTextLabel = %ReportTrustLabel
@onready var return_button: Button = %ReturnToGuildButton

func _ready() -> void:
	return_button.pressed.connect(
		_on_return_button_pressed
	)
	
func show_report(result: Dictionary) -> void:
	show()
	
	title_label.text = "Relatório da Expedição"
	
	summary_label.text = build_summary_text(result)
	discoveries_label.text = build_discoveries_text(result)
	trust_label.text = build_trust_text(result)
	
func build_summary_text(result: Dictionary) -> String:
	var team: Array = result.get("team", [])
	var equipment: Array = result.get("equipment", [])
	
	return (
		"[b]Líder:[/b] %s\n"
		+ "[b]Sucessor:[/b] %s\n"
		+ "[b]Equipe:[/b] %s\n"
		+ "[b]Cargas restantes:[/b] %d"
	) % [
		result.get("leader_name", "Desconhecido"),
		result.get("successor_name", "Desconhecido"),
		", ".join(team),
		", ".join(equipment),
		result.get("mirror_charges", 0),
	]
	
func build_discoveries_text(result: Dictionary) -> String:
	var lines: Array[String] = []
	
	if result.get("injured_worker_found", false):
		lines.append(
			"Um trabalhador desaparecido foi encontrado."
		)
		
		if result.get("injured_worker_rescued", false):
			lines.append(
				"O trabalhador foi resgatado."
			)
		else:
			lines.append(
				"O trabalhador não retornou com a equipe."
			)
	if result.get("inspection_records_found", false):
		lines.append(
			"Os registros da inspeção foram recuperados."
		)
		
	if result.get("survival_order_active", false):
		lines.append(
			"A ordem de priorizar a sobrevivência influenciou "
			+ "as decisões da equipe."
		)
		
	if lines.is_empty():
		lines.append(
			"Nenhuma descoberta relevante foi registrada."
		)
		
	return "[b]Descobertas e consequências[/b]\n" + "\n".join(lines)
	
func build_trust_text(result: Dictionary) -> String:
	var trust: Dictionary = result.get("trust", {})

	return (
		"[b]Confiança da equipe[/b]\n"
		+ "Mara Veln: %d\n"
		+ "Iven Dorr: %d\n"
		+ "Selka Vale: %d\n"
		+ "Orren Vask: %d"
	) % [
		trust.get("MaraCard", 0),
		trust.get("IvenCard", 0),
		trust.get("SelkaCard", 0),
		trust.get("OrrenCard", 0),
	]


func _on_return_button_pressed() -> void:
	return_to_guild_requested.emit()
