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