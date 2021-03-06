extends PawnActor
class_name InteractivePawn

onready var raycasts : = $Raycasts as Node2D
onready var dialogue_balloon : = $DialogueBalloon as Sprite

export var vanish_on_interaction : = false
export var AUTO_START_INTERACTION : = false
export var sight_distance = 50
export var facing = {
	"up": true,
	"left": true,
	"right": true,
	"down": true
}

var active_raycasts := []

func _ready() -> void:
	# Initializes raycast nodes, deactivates the area if using raycasts
	# for player detection
	var use_area = true
	for raycast in raycasts.get_children():
		if not facing[raycast.name.to_lower()]:
			continue
		raycast.enabled = true
		raycast.cast_to = raycast.cast_to.normalized() * sight_distance
		active_raycasts.append(raycast)
		use_area = false
	
	if use_area:
		connect('body_entered', self, '_on_body_entered')
		connect('body_exited', self, '_on_body_exited')
		set_physics_process(false)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and dialogue_balloon.visible:
		start_interaction()
		get_tree().set_input_as_handled()

func _physics_process(delta : float) -> void:
	# Only runs if using raycasts/specific directions for player detection
	if not dialogue_balloon.visible:
		for raycast in active_raycasts:
			if not raycast.is_colliding():
				continue
			if AUTO_START_INTERACTION:
				start_interaction()
			dialogue_balloon.show()
	else:
		var inactive_count : int = 0
		for raycast in active_raycasts:
			if not raycast.is_colliding():
				inactive_count += 1
		if inactive_count == active_raycasts.size():
			dialogue_balloon.visible = false

func _on_body_entered(body : PhysicsBody2D) -> void:
	if AUTO_START_INTERACTION:
		start_interaction()
	else:
		dialogue_balloon.show()

func _on_body_exited(body : PhysicsBody2D) -> void:
	dialogue_balloon.hide()

func start_interaction() -> void:
	"""
	Pauses the game and play each action under the $Actions node
	Actions that transition to another scene (e.g. StartCombatAction) may unpause
	the game themselves
	InteractivePawn processes even when the game is paused, but not
	PawnLeader, the player-controlled pawn
	"""
	dialogue_balloon.hide()
	get_tree().paused = true
	var actions = $Actions.get_children()
	# An interactive pawn should have some interaction
	assert actions != []
	for action in actions:
		action.interact()
		yield(action, "finished")
	if vanish_on_interaction:
		queue_free()
	get_tree().paused = false
