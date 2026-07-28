class_name ExpeditionScreen
extends VBoxContainer

signal expedition_finished(result: Dictionary)

const MAX_MIRROR_CHARGES: int = 2
const TUNNEL_STAGE_INDEX: int = 2
const MIRROR_CHAMBER_STAGE_INDEX: int = 3

const DECISION_NONE: String = ""
const DECISION_TUNNEL_ROUTE: String = "tunnel_route"
const DECISION_INJURED_WORKER: String = "injured_worker"

const EXPEDITION_STAGES: Array[Dictionary] = [
	{
		"name": "Entrada da Cisterna",
		"event": "A equipe alcança a entrada da antiga cisterna. Marcas recentes indicam que alguém entrou depois do desaparecimento dos trabalhadores."
	},
	{
		"name": "Passagem Inundada",
		"event": "A água chega à cintura. A corrente está mais forte do que o contratante informou, e parte do equipamento precisa ser mantida acima da superfície."
	},
	{
		"name": "Túnel Dividido",
		"event": "A equipe encontra duas rotas. Uma delas apresenta pegadas recentes; a outra possui marcas de ferramentas nas paredes."
	},
	{
		"name": "Câmara do Espelho",
		"event": "Um brilho fraco surge sob a água. Fragmentos semelhantes ao vidro cobrem uma estrutura ritualística quebrada."
	},
	{
		"name": "Rota de Retorno",
		"event": "A estrutura começa a ceder. A equipe precisa retornar carregando tudo o que encontrou — e talvez alguém que já não consiga caminhar."
	},
]

@onready var decision_panel: PanelContainer = %DecisionPanel
@onready var decision_description: RichTextLabel = %DecisionDescription

@onready var footprints_route_button: Button = %FootprintsRouteButton
@onready var tool_marks_route_button: Button = %ToolMarksRouteButton

@onready var current_stage_label: Label = %CurrentStageLabel
@onready var mirror_charges_label: Label = %MirrorChargesLabel
@onready var leader_status_label: Label = %LeaderStatusLabel
@onready var expedition_status_label: Label = %ExpeditionStatusLabel
@onready var event_log: RichTextLabel = %EventLog

@onready var observe_button: Button = %ObserveButton
@onready var send_order_button: Button = %SendOrderButton
@onready var advance_stage_button: Button = %AdvanceStageButton
@onready var end_expedition_button: Button = %EndExpeditionButton

@onready var stage_buttons: Array[Button] = [
	%StageEntrance,
	%StageFloodedPassage,
	%StageSplitTunnel,
	%StageMirrorChamber,
	%StageReturnRoute,
]

var selected_team: Array[String] = []
var expedition_equipment: Array[String] = []

var expedition_leader_name: String = ""
var expedition_successor_name: String = ""

var current_expedition_stage: int = 0
var mirror_charges: int = MAX_MIRROR_CHARGES
var expedition_log_entries: Array[String] = []
var current_decision_type: String = DECISION_NONE

var injured_worker_found: bool = false
var injured_worker_rescued: bool = false
var inspection_records_found: bool = false

var survival_order_active: bool = false
var expedition_has_fragment: bool = false

var current_event_requires_decision: bool = false
var tunnel_decision_resolved: bool = false

var mara_trust: int = 0
var iven_trust: int = 0
var selka_trust: int = 0
var orren_trust: int = 0

func _ready() -> void:
	observe_button.pressed.connect(_on_observe_pressed)
	send_order_button.pressed.connect(_on_send_order_pressed)
	advance_stage_button.pressed.connect(_on_advance_stage_pressed)
	end_expedition_button.pressed.connect(_on_end_expedition_pressed)

	footprints_route_button.pressed.connect(
		_on_footprints_route_pressed
	)

	tool_marks_route_button.pressed.connect(
		_on_tool_marks_route_pressed
	)

func start_expedition(
	team: Array[String],
	leader_name: String,
	successor_name: String,
	equipment: Array[String]
) -> void:
	selected_team = team.duplicate()
	expedition_equipment = equipment.duplicate()

	expedition_leader_name = leader_name
	expedition_successor_name = successor_name

	current_expedition_stage = 0
	mirror_charges = MAX_MIRROR_CHARGES
	expedition_log_entries.clear()

	current_event_requires_decision = false
	tunnel_decision_resolved = false

	current_decision_type = DECISION_NONE

	injured_worker_found = false
	injured_worker_rescued = false
	inspection_records_found = false

	survival_order_active = false
	expedition_has_fragment = false

	mara_trust = 0
	iven_trust = 0
	selka_trust = 0
	orren_trust = 0

	decision_panel.hide()

	end_expedition_button.disabled = false
	advance_stage_button.disabled = false
	observe_button.disabled = false
	send_order_button.disabled = false

	show()

	leader_status_label.text = "Líder: %s" % expedition_leader_name

	add_expedition_log(
        "[b]A expedição começou.[/b]\n"
		+"A equipe parte em direção à antiga cisterna."
	)

	add_current_stage_event()
	update_expedition_screen()
	
func update_expedition_screen() -> void:
	var stage_data: Dictionary = EXPEDITION_STAGES[
		current_expedition_stage
	]

	current_stage_label.text = "Etapa: %s" % stage_data["name"]

	mirror_charges_label.text = "Espelho: %d carga(s)" % (
		mirror_charges
	)

	observe_button.disabled = mirror_charges <= 0
	send_order_button.disabled = mirror_charges <= 0

	for index: int in range(stage_buttons.size()):
		var stage_button: Button = stage_buttons[index]

		if index < current_expedition_stage:
			stage_button.text = "✓\n%s" % get_short_stage_name(index)
		elif index == current_expedition_stage:
			stage_button.text = "●\n%s" % get_short_stage_name(index)
		else:
			stage_button.text = "%d\n%s" % [
				index + 1,
				get_short_stage_name(index),
			]

	var is_final_stage: bool = (
		current_expedition_stage
		== EXPEDITION_STAGES.size() - 1
	)

	advance_stage_button.visible = not is_final_stage
	end_expedition_button.visible = is_final_stage

	if current_event_requires_decision:
		expedition_status_label.text = (
			"A equipe aguarda uma decisão antes de avançar."
		)
	elif is_final_stage:
		expedition_status_label.text = (
			"A equipe está retornando. A missão pode ser encerrada."
		)
	else:
		expedition_status_label.text = (
			"A equipe aguarda o próximo avanço."
		)


func get_short_stage_name(index: int) -> String:
	var short_names: Array[String] = [
		"Entrada",
		"Passagem",
		"Túnel",
		"Câmara",
		"Retorno",
	]

	return short_names[index]


func add_current_stage_event() -> void:
	var stage_data: Dictionary = EXPEDITION_STAGES[
		current_expedition_stage
	]

	add_expedition_log(
		"[b]%s[/b]\n%s"
		% [
			stage_data["name"],
			stage_data["event"],
		]
	)


func add_expedition_log(entry: String) -> void:
	expedition_log_entries.append(entry)

	event_log.text = "\n\n".join(expedition_log_entries)

	await get_tree().process_frame

	var last_line: int = max(event_log.get_line_count() - 1, 0)
	event_log.scroll_to_line(last_line)


func consume_mirror_charge() -> bool:
	if mirror_charges <= 0:
		return false

	mirror_charges -= 1
	update_expedition_screen()

	return true


func _on_observe_pressed() -> void:
	if not consume_mirror_charge():
		return

	var observations: Array[String] = [
		"O espelho mostra imagens instáveis. A equipe permanece unida, mas alguém parece observar constantemente o caminho de volta.",
		"Por alguns segundos, você vê o ambiente pelos olhos do líder. Há sinais de movimentação recente que não pertencem aos trabalhadores desaparecidos.",
		"O reflexo apresenta uma distorção. Um dos aventureiros parece segurar algo que não estava entre os equipamentos da companhia.",
	]

	var observation_index: int = (
		current_expedition_stage
		% observations.size()
	)

	add_expedition_log(
		"[color=light_blue][b]Observação pelo espelho[/b][/color]\n"
		+ observations[observation_index]
	)


func _on_send_order_pressed() -> void:
	if not consume_mirror_charge():
		return

	survival_order_active = true

	add_expedition_log(
		"[color=gold][b]Ordem transmitida[/b][/color]\n"
		+"Você ordena que a equipe permaneça unida e priorize a sobrevivência acima do objetivo."
	)

	expedition_status_label.text = (
		"A ordem foi transmitida. Cada membro poderá interpretá-la de maneira diferente."
	)

func _on_advance_stage_pressed() -> void:
	if current_event_requires_decision:
		return

	if current_expedition_stage >= EXPEDITION_STAGES.size() - 1:
		return

	current_expedition_stage += 1

	add_current_stage_event()

	if current_expedition_stage == TUNNEL_STAGE_INDEX:
		start_tunnel_decision()

	elif (
		current_expedition_stage == MIRROR_CHAMBER_STAGE_INDEX
		and injured_worker_found
		and not injured_worker_rescued
	):
		start_injured_worker_decision()

	update_expedition_screen()


func _on_end_expedition_pressed() -> void:
	add_expedition_log(
		"[b]Expedição encerrada.[/b]\n"
		+"A equipe retorna à companhia. O relatório completo ainda precisa ser analisado."
	)

	end_expedition_button.disabled = true
	observe_button.disabled = true
	send_order_button.disabled = true
	advance_stage_button.disabled = true

	expedition_status_label.text = (
		"Missão concluída. O relatório será o próximo passo."
	)
	
	var result: Dictionary = build_expedition_result()
	
	expedition_finished.emit(result)
	
func build_expedition_result() -> Dictionary:
	return {
		"team": selected_team.duplicate(),
		"leader_name": expedition_leader_name,
		"successor_name": expedition_successor_name,
		"equipment": expedition_equipment.duplicate(),
		"mirror_charges": mirror_charges,
		"injured_worker_found": injured_worker_found,
		"injured_worker_rescued": injured_worker_rescued,
		"inspection_records_found": inspection_records_found,
		"fragment_found": expedition_has_fragment,
		"survival_order_active": survival_order_active,
		"trust": {
			"MaraCard": mara_trust,
			"IvenCard": iven_trust,
			"SelkaCard": selka_trust,
			"OrrenCard": orren_trust,
		},
		"log_entries": expedition_log_entries.duplicate(),
	}

func start_tunnel_decision() -> void:
	if tunnel_decision_resolved:
		return

	current_event_requires_decision = true
	current_decision_type = DECISION_TUNNEL_ROUTE
	decision_panel.show()
	
	footprints_route_button.text = "Seguir as pegadas"
	tool_marks_route_button.text = "Seguir marcas de ferramentas"

	decision_description.text = (
		"[b]Duas rotas se abrem diante da equipe.[/b]\n\n"
		+"À esquerda, pegadas recentes seguem por um túnel estreito "
		+"e parcialmente inundado.\n\n"
		+"À direita, marcas de ferramentas levam a uma passagem antiga "
		+"que parece mais estável, mas não há sinais dos trabalhadores."
	)

	advance_stage_button.disabled = true

func team_has_adventurer(adventurer_id: String) -> bool:
	return adventurer_id in selected_team

func expedition_has_equipment(equipment_id: String) -> bool:
	return equipment_id in expedition_equipment

func _on_footprints_route_pressed() -> void:
	match current_decision_type:
		DECISION_TUNNEL_ROUTE:
			resolve_footprints_route()
		DECISION_INJURED_WORKER:
			resolve_worker_rescue()
		_:
			push_warning("Nenhuma decisão válida está ativa.")

func _on_tool_marks_route_pressed() -> void:
	match current_decision_type:
		DECISION_TUNNEL_ROUTE:
			resolve_tool_marks_route()
		DECISION_INJURED_WORKER:
			resolve_abandon_worker()
		_:
			push_warning("Nenhuma decisão válida está ativa.")

func resolve_tunnel_decision(result_lines: Array[String]) -> void:
	tunnel_decision_resolved = true
	current_event_requires_decision = false
	current_decision_type = DECISION_NONE

	decision_panel.hide()
	advance_stage_button.disabled = false

	add_expedition_log(
		"\n".join(result_lines)
	)

	expedition_status_label.text = (
		"A rota foi escolhida. A equipe pode continuar."
	)

	print_relationship_debug()

func print_relationship_debug() -> void:
	print("CONFIANÇA ATUAL")
	print("Mara: ", mara_trust)
	print("Iven: ", iven_trust)
	print("Selka: ", selka_trust)
	print("Orren: ", orren_trust)

func start_injured_worker_decision() -> void:
	current_event_requires_decision = true
	current_decision_type = DECISION_INJURED_WORKER

	decision_panel.show()

	decision_description.text = (
		"[b]O trabalhador não consegue continuar andando.[/b]\n\n"
		+"Ao mesmo tempo, a estrutura ritualística aparece logo adiante. "
		+"Levá-lo de volta agora pode impedir que a equipe examine "
		+"a câmara.\n\n"
		+"Selka exige que o grupo inicie a retirada. Orren afirma que "
		+"o homem pode esperar alguns minutos."
	)

	footprints_route_button.text = "Resgatar o trabalhador"
	tool_marks_route_button.text = "Priorizar a câmara"

	expedition_status_label.text = (
		"A equipe aguarda sua decisão sobre o trabalhador."
	)

	advance_stage_button.disabled = true

func resolve_footprints_route() -> void:
	var result_lines: Array[String] = []

	result_lines.append(
		"[color=gold][b]A equipe segue as pegadas.[/b][/color]"
	)

	var success_score: int = 0

	if team_has_adventurer("OrrenCard"):
		success_score += 2
		orren_trust += 1

		result_lines.append(
			"Orren reconhece sinais de movimentação recente "
			+"e impede que o grupo siga uma trilha falsa."
		)

	if team_has_adventurer("SelkaCard"):
		success_score += 1

		result_lines.append(
			"Selka identifica manchas de sangue diluídas pela água."
		)

	if expedition_has_equipment("LanternEquipment"):
		success_score += 1

		result_lines.append(
			"A lanterna revela pegadas parcialmente submersas."
		)

	if expedition_leader_name == "Mara Veln":
		success_score += 1
		mara_trust += 1

		result_lines.append(
			"Mara mantém a formação e impede que o grupo se separe."
		)

	if success_score >= 3:
		injured_worker_found = true

		result_lines.append(
			"\n[b]Resultado:[/b] a equipe encontra um trabalhador "
			+"ferido, mas ainda vivo."
		)

		selka_trust += 1
	else:
		result_lines.append(
			"\n[b]Resultado:[/b] a rota termina em uma área instável. "
			+"A equipe perde tempo e retorna sob forte tensão."
		)

		mara_trust -= 1

	resolve_tunnel_decision(result_lines)

func resolve_tool_marks_route() -> void:
	var result_lines: Array[String] = []

	result_lines.append(
		"[color=light_blue][b]"
		+"A equipe segue as marcas de ferramentas."
		+"[/b][/color]"
	)

	var success_score: int = 0

	if team_has_adventurer("IvenCard"):
		success_score += 3
		iven_trust += 1

		result_lines.append(
			"Iven reconhece técnicas antigas de escavação "
			+"e identifica uma parede recentemente alterada."
		)

	if expedition_has_equipment("LanternEquipment"):
		success_score += 1

		result_lines.append(
			"A lanterna permite examinar as rachaduras com segurança."
		)

	if expedition_has_equipment("RopeEquipment"):
		success_score += 1

		result_lines.append(
			"A corda permite atravessar uma seção parcialmente desabada."
		)

	if expedition_leader_name == "Iven Dorr":
		success_score += 1
		iven_trust += 1

		result_lines.append(
			"Sob a liderança de Iven, a equipe avança com cuidado."
		)

	if success_score >= 3:
		inspection_records_found = true

		result_lines.append(
			"\n[b]Resultado:[/b] a equipe encontra os registros "
			+"da inspeção e provas de que o contratante omitiu riscos."
		)
	else:
		result_lines.append(
			"\n[b]Resultado:[/b] a equipe encontra uma passagem bloqueada "
			+"e precisa retornar sem os registros."
		)

	resolve_tunnel_decision(result_lines)

func resolve_worker_rescue() -> void:
	var result_lines: Array[String] = []

	result_lines.append(
		"[color=light_blue][b]"
		+"Você ordena o resgate imediato do trabalhador."
		+"[/b][/color]"
	)

	injured_worker_rescued = true

	if team_has_adventurer("SelkaCard"):
		selka_trust += 2

		result_lines.append(
			"Selka estabiliza o trabalhador e aprova sua decisão."
		)

	if team_has_adventurer("MaraCard"):
		mara_trust += 1

		result_lines.append(
			"Mara reorganiza a formação para proteger a retirada."
		)

	if team_has_adventurer("OrrenCard"):
		orren_trust -= 1

		result_lines.append(
			"Orren protesta que a companhia está abandonando "
			+"uma oportunidade valiosa."
		)

	if expedition_has_equipment("MedicalKitEquipment"):
		result_lines.append(
			"O kit médico reduz o risco de o trabalhador morrer "
			+"durante o retorno."
		)
	else:
		result_lines.append(
			"Sem um kit médico, o trabalhador permanece em estado grave."
		)

	result_lines.append(
		"\n[b]Consequência:[/b] a equipe salva o trabalhador, "
		+"mas terá menos tempo para investigar a câmara."
	)

	resolve_worker_decision(result_lines)

func resolve_abandon_worker() -> void:
	var result_lines: Array[String] = []

	result_lines.append(
		"[color=gold][b]"
		+"Você ordena que a equipe priorize a câmara."
		+"[/b][/color]"
	)

	var order_obeyed: bool = true

	if team_has_adventurer("SelkaCard"):
		var selka_resistance: int = 3

		if survival_order_active:
			selka_resistance += 2

		if expedition_leader_name == "Mara Veln":
			selka_resistance += 1

		if selka_trust < 0:
			selka_resistance += 1

		if selka_resistance >= 5:
			order_obeyed = false

			result_lines.append(
				"Selka se recusa a abandonar o trabalhador. Ela afirma "
				+"que sua ordem anterior para priorizar sobrevivência "
				+"também se aplica a ele."
			)

	if not order_obeyed:
		injured_worker_rescued = true
		selka_trust -= 1
		orren_trust -= 1

		result_lines.append(
			"Mara hesita, mas permite que Selka organize a retirada. "
			+"Sua ordem não é cumprida."
		)

		result_lines.append(
			"\n[b]Consequência:[/b] o trabalhador é resgatado, "
			+"mas sua autoridade sobre a equipe é enfraquecida."
		)
	else:
		expedition_has_fragment = true
		selka_trust -= 2
		orren_trust += 1

		result_lines.append(
			"A equipe deixa o trabalhador para trás temporariamente "
			+"e examina a estrutura."
		)

		result_lines.append(
			"Orren recupera um fragmento ritualístico antes que "
			+"a câmara comece a desabar."
		)

		result_lines.append(
			"\n[b]Consequência:[/b] a companhia obtém um fragmento, "
			+"mas o estado do trabalhador se agrava."
		)

	resolve_worker_decision(result_lines)

func resolve_worker_decision(result_lines: Array[String]) -> void:
	current_event_requires_decision = false
	current_decision_type = DECISION_NONE

	decision_panel.hide()
	advance_stage_button.disabled = false

	add_expedition_log("\n".join(result_lines))

	expedition_status_label.text = (
		"A situação foi resolvida. A equipe pode continuar."
	)

	print_relationship_debug()
