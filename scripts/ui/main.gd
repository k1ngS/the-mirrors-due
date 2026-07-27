extends Control

const MAX_TEAM_SIZE: int = 3

@onready var home_screen: VBoxContainer = %HomeScreen
@onready var contract_screen: VBoxContainer = %ContractScreen
@onready var team_selection_screen: VBoxContainer = %TeamSelectionScreen

@onready var start_contract_button: Button = %StartContractButton
@onready var back_to_home_button: Button = %BackToHomeButton
@onready var investigate_button: Button = %InvestigateButton
@onready var prepare_team_button: Button = %PrepareTeamButton

@onready var back_to_contract_button: Button = %BackToContractButton
@onready var confirm_team_button: Button = %ConfirmTeamButton
@onready var selection_status_label: Label = %SelectionStatusLabel

@onready var adventurer_cards: Array[Button] = [
	%MaraCard,
	%IvenCard,
	%SelkaCard,
	%OrrenCard,
]

func _ready() -> void:
	start_contract_button.pressed.connect(show_contract_screen)
	back_to_home_button.pressed.connect(show_home_screen)
	investigate_button.pressed.connect(_on_investigate_pressed)
	prepare_team_button.pressed.connect(show_team_selection_screen)
	back_to_contract_button.pressed.connect(show_contract_screen)
	confirm_team_button.pressed.connect(_on_confirm_team_pressed)

	for card: Button in adventurer_cards:
		card.toggled.connect(_on_adventurer_card_toggled)

	show_home_screen()

func hide_all_screens() -> void:
	home_screen.hide()
	contract_screen.hide()
	team_selection_screen.hide()

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

func _on_investigate_pressed() -> void:
	print("Investigação ainda não implementada.")

func _on_adventurer_card_toggled(_is_selected: bool) -> void:
	var selected_count: int = get_selected_adventurers().size()

	if selected_count > MAX_TEAM_SIZE:
		var pressed_card: Button = get_viewport().gui.get_focus_owner() as Button

		if pressed_card != null and pressed_card in adventurer_cards:
			pressed_card.button_pressed = false

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
	var selected_adventurers: Array[String] = get_selected_adventurers()

	print("Equipe confirmada:")
	for adventurer_name: String in selected_adventurers:
		print("- ", adventurer_name)
