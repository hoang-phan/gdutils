extends Node2D
class_name PlayerMovementComponent

@export var anim : AnimationTree
var playback : AnimationNodeStateMachinePlayback
var actor : CharacterBody2D

func _ready():
	actor = get_parent()
	playback = anim.get("parameters/playback")

func _physics_process(delta: float):
	var direction : Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	actor.velocity = direction * actor.speed
	
	if direction == Vector2.ZERO:
		playback.travel("Idle")
	else:
		playback.travel("Run")
		anim.set("parameters/Run/direction/blend_position", direction)
		anim.set("parameters/Idle/direction/blend_position", direction)

	actor.move_and_slide()
