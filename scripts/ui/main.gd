extends Control

@onready var start_contract_button: Button = %StartContractButton

func _ready() -> void:
	start_contract_button.pressed.connect(_on_start_contract_pressed)
	
func _on_start_contract_pressed() -> void:
	print("Abrir contrato: A Luz Sob o Poço")
