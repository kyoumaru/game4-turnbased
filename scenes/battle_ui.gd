class_name BattleUI
extends Control

@export var battle_manager: Node 

@onready var action_bar_container: HBoxContainer = $VBoxContainer/ActionBar
@onready var sp_label: Label = $VBoxContainer/SPLabel
@onready var command_panel: Control = $CommandPanel
@onready var btn_basic: Button = $CommandPanel/BtnBasic
@onready var btn_skill: Button = $CommandPanel/BtnSkill
@onready var btn_ult: Button = $CommandPanel/BtnUlt

func _ready() -> void:
	# If battle_manager isn't exported, try finding it in the parent/root scene
	if not battle_manager:
		battle_manager = get_node_or_null("../BattleManager") # Adjust path if needed
		
	if not battle_manager:
		print("BattleUI: BattleManager not found!")
		return
	
	# Connect Button clicks to the manager's action selector
	btn_basic.pressed.connect(func(): battle_manager._select_action(Unit.Action.BASIC))
	btn_skill.pressed.connect(func(): battle_manager._select_action(Unit.Action.SKILL))
	btn_ult.pressed.connect(func(): battle_manager._select_action(Unit.Action.ULT))
	
	command_panel.hide()

func _process(_delta: float) -> void:
	if not battle_manager:
		return
	
	# Update SP label 
	sp_label.text = "SP: %d / %d" % [battle_manager.sp, battle_manager.MAX_SP]
	
	# Show command menu only when it's a player's turn to choose an action
	if battle_manager.state == battle_manager.State.CHOOSING_ACTION and battle_manager.current_actor and battle_manager.current_actor.is_player:
		command_panel.show()
		
		# Disable skill/ult buttons if conditions aren't met
		var unit = battle_manager.current_actor
		btn_skill.disabled = battle_manager.sp < unit.skill_cost
		btn_ult.disabled = not unit.can_use(Unit.Action.ULT)
		
		# Update current ULT energy of the actor
		btn_ult.text = "[R] ULTIMATE\nEnergy: %d / %d" % [unit.energy, unit.max_energy]
	else:
		command_panel.hide()
		
	# Update turn order preview bar
	_update_action_bar()

func _update_action_bar() -> void:
	for child in action_bar_container.get_children():
		child.queue_free()
		
	# Display the current active unit
	if battle_manager.current_actor:
		var current_panel = PanelContainer.new()
		var current_lbl = Label.new()
		current_lbl.text = " ▶ CURRENT: %s " % battle_manager.current_actor.unit_name
		current_lbl["theme_override_colors/font_color"] = Color.GOLD 
		current_panel.add_child(current_lbl)
		action_bar_container.add_child(current_panel)
		
		# Separator line
		var separator = VSeparator.new()
		action_bar_container.add_child(separator)
	
	# Display the upcoming queue preview
	var upcoming_names = battle_manager.preview_order(5)
	for unit_name in upcoming_names:
		var next_panel = PanelContainer.new()
		var next_lbl = Label.new()
		next_lbl.text = " %s " % unit_name
		next_panel.add_child(next_lbl)
		action_bar_container.add_child(next_panel)
