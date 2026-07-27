extends Control

const MAX_TEAM_SIZE: int = 3
const MAX_EQUIPMENT: int = 2

const ADVENTURER_NAMES: Dictionary = {
	"MaraCard": "Mara Veln",
	"IvenCard": "Iven Dorr",
	"SelkaCard": "Selka Vale",
	"OrrenCard": "Orren Vask",
}

@onready var home_screen: VBoxContainer = %HomeScreen
@onready var contract_screen: VBoxContainer = %ContractScreen
@onready var team_selection_screen: VBoxContainer = %TeamSelectionScreen
@onready var expedition_setup_screen: VBoxContainer = %ExpeditionSetupScreen

@onready var start_contract_button: Button = %StartContractButton
@onready var back_to_home_button: Button = %BackToHomeButton
@onready var investigate_button: Button = %InvestigateButton
@onready var prepare_team_button: Button = %PrepareTeamButton

@onready var back_to_contract_button: Button = %BackToContractButton
@onready var confirm_team_button: Button = %ConfirmTeamButton
@onready var selection_status_label: Label = %SelectionStatusLabel

@onready var selected_team_label: Label = %SelectedTeamLabel
@onready var leader_option: OptionButton = %LeaderOption
@onready var successor_option: OptionButton = %SuccessorOption
@onready var setup_status_label: Label = %SetupStatusLabel
@onready var back_to_team_button: Button = %BackToTeamButton
@onready var begin_expedition_button: Button = %BeginExpeditionButton

@onready var adventurer_cards: Array[Button] = [
	%MaraCard,
	%IvenCard,
	%SelkaCard,
	%OrrenCard,
]

@onready var equipment_buttons: Array[CheckButton] = [
	%RopeEquipment,
	%LanternEquipment,
	%MedicalKitEquipment,
]

var selected_team: Array[String] = []

func _ready() -> void:
	start_contract_button.pressed.connect(show_contract_screen)
	back_to_home_button.pressed.connect(show_home_screen)
	investigate_button.pressed.connect(_on_investigate_pressed)
	prepare_team_button.pressed.connect(show_team_selection_screen)

	back_to_contract_button.pressed.connect(show_contract_screen)
	confirm_team_button.pressed.connect(_on_confirm_team_pressed)

	back_to_team_button.pressed.connect(show_team_selection_screen)
	begin_expedition_button.pressed.connect(_on_begin_expedition_pressed)

	leader_option.item_selected.connect(_on_leadership_changed)
	successor_option.item_selected.connect(_on_leadership_changed)

	for card: Button in adventurer_cards:
		card.toggled.connect(_on_adventurer_card_toggled)

	for equipment: CheckButton in equipment_buttons:
		equipment.toggled.connect(_on_equipment_toggled)

	show_home_screen()

func hide_all_screens() -> void:
	home_screen.hide()
	contract_screen.hide()
	team_selection_screen.hide()
	expedition_setup_screen.hide()

func show_home_screen() -> void:
	hide_all_screens()
	home_screen.show()

func show_contract_screen() -> void:
	hide_all_screens()
	contract_screen.show()

func show_team_selection_screen() -> void:
	hide_all_screens()
	team_selection_screen.show()
	update_team_selection()

func show_expedition_setup_screen() -> void:
	hide_all_screens()
	expedition_setup_screen.show()

	populate_leadership_options()
	update_setup_screen()

func _on_investigate_pressed() -> void:
	print("Investigação ainda não implementada.")

func _on_adventurer_card_toggled(_is_selected: bool) -> void:
	update_team_selection()

func get_selected_adventurers() -> Array[String]:
	var selected_adventurers: Array[String] = []

	for card: Button in adventurer_cards:
		if card.button_pressed:
			selected_adventurers.append(card.name)

	return selected_adventurers

func update_team_selection() -> void:
	var selected_count: int = get_selected_adventurers().size()

	selection_status_label.text = "Selecionados: %d / %d" % [
		selected_count,
		MAX_TEAM_SIZE,
	]

	confirm_team_button.disabled = selected_count != MAX_TEAM_SIZE

	for card: Button in adventurer_cards:
		card.disabled = (
			selected_count >= MAX_TEAM_SIZE
			and not card.button_pressed
		)

func _on_confirm_team_pressed() -> void:
	selected_team = get_selected_adventurers()

	if selected_team.size() != MAX_TEAM_SIZE:
		return

	show_expedition_setup_screen()

func populate_leadership_options() -> void:
	leader_option.clear()
	successor_option.clear()

	for adventurer_id: String in selected_team:
		var display_name: String = get_adventurer_display_name(adventurer_id)

		leader_option.add_item(display_name)
		successor_option.add_item(display_name)

	if selected_team.size() >= 2:
		leader_option.select(0)
		successor_option.select(1)

func get_adventurer_display_name(adventurer_id: String) -> String:
	return ADVENTURER_NAMES.get(adventurer_id, adventurer_id)

func get_selected_team_names() -> Array[String]:
	var team_names: Array[String] = []

	for adventurer_id: String in selected_team:
		team_names.append(get_adventurer_display_name(adventurer_id))

	return team_names

func update_setup_screen() -> void:
	selected_team_label.text = "Equipe: %s" % ", ".join(
		get_selected_team_names()
	)

	update_equipment_availability()
	update_setup_validation()

func _on_leadership_changed(_index: int) -> void:
	update_setup_validation()

func _on_equipment_toggled(_is_selected: bool) -> void:
	update_equipment_availability()
	update_setup_validation()

func get_selected_equipment() -> Array[String]:
	var selected_equipment: Array[String] = []

	for equipment: CheckButton in equipment_buttons:
		if equipment.button_pressed:
			selected_equipment.append(equipment.name)

	return selected_equipment

func update_equipment_availability() -> void:
	var selected_count: int = get_selected_equipment().size()

	for equipment: CheckButton in equipment_buttons:
		equipment.disabled = (
			selected_count >= MAX_EQUIPMENT
			and not equipment.button_pressed
		)

func update_setup_validation() -> void:
	var selected_equipment_count: int = get_selected_equipment().size()
	var same_leader_and_successor: bool = (
		leader_option.selected == successor_option.selected
	)

	var setup_is_valid: bool = (
		selected_team.size() == MAX_TEAM_SIZE
		and selected_equipment_count == MAX_EQUIPMENT
		and not same_leader_and_successor
	)

	begin_expedition_button.disabled = not setup_is_valid

	if same_leader_and_successor:
		setup_status_label.text = (
			"O lider e o sucessor precisam ser pessoas diferentes."
		)
	elif selected_equipment_count < MAX_EQUIPMENT:
		setup_status_label.text = (
			"Equipamentos selecionados: %d / %d"
			% [
				selected_equipment_count,
				MAX_EQUIPMENT,
			]
		)
	else:
		setup_status_label.text = (
			"Plano válido. A expedição está pronta."
		)

func _on_begin_expedition_pressed() -> void:
	if begin_expedition_button.disabled:
		return

	var leader_name: String = leader_option.get_item_text(leader_option.selected)
	var successor_name: String = successor_option.get_item_text(successor_option.selected)

	print("EXPEDIÇÂO CONFIRMADA")
	print("Equipe:")

	for adventurer_name: String in get_selected_team_names():
		print("- ", adventurer_name)

	print("Lider: ", leader_name)
	print("Sucessor: ", successor_name)
	print("Equipamentos:")

	for equipment_name: String in get_selected_equipment():
		print("- ", equipment_name)

	print("Próximo destino: A Luz Sob o Poço")
