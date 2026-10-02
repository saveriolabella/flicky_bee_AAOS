extends Control

signal end_game()

@export var score_pop_scene : PackedScene
@export var danger_curve : Curve

var health_total := 10.0
var health := 10.0 
var hp_bar : TextureProgressBar

var fly_total := 5.0
var fly := 5.0
var fly_bar : TextureProgressBar

var is_audio_muted := false
var persist_node: Persist = null

var distance : float
var score : int

# Called when the node enters the scene tree for the first time.
func _ready():
	hp_bar = $Health_Meter/HealthBar
	fly_bar = $Flight_Meter/FlyBar
	_cache_persist_node()
	_connect_persist_signal()
	_sync_mute_state_from_persist()
	_refresh_mute_icon()
	_update_score(0, 0)
	_setup()


func _setup() -> void:
	self.show()
	$Health_Meter.show()
	$Flight_Meter.show()
	_update_score(0, 0)
	_update_distance(0)
	$PauseButton.show()
	$MuteButton.show()
	_sync_mute_state_from_persist()
	_refresh_mute_icon()
	$Pause.hide()


func _exit_tree() -> void:
	_disconnect_persist_signal()


func _cache_persist_node() -> void:
	if get_window().has_node("Persist"):
		persist_node = get_window().get_node("Persist")
	else:
		persist_node = null


func _connect_persist_signal() -> void:
	if persist_node == null:
		return
	var callback := Callable(self, "_on_global_audio_mute_state_changed")
	if !persist_node.is_connected("audio_mute_state_changed", callback):
		persist_node.connect("audio_mute_state_changed", callback)


func _disconnect_persist_signal() -> void:
	if persist_node == null:
		return
	var callback := Callable(self, "_on_global_audio_mute_state_changed")
	if persist_node.is_connected("audio_mute_state_changed", callback):
		persist_node.disconnect("audio_mute_state_changed", callback)


func _sync_mute_state_from_persist() -> void:
	if persist_node != null:
		is_audio_muted = persist_node.is_audio_muted
	else:
		is_audio_muted = false


func _refresh_mute_icon() -> void:
	$MuteButton/Slash.visible = is_audio_muted


func _on_global_audio_mute_state_changed(muted: bool) -> void:
	is_audio_muted = muted
	_refresh_mute_icon()


func _update_health_bar(new_health : float, total : float) -> void:
	health_total = total
	health = clamp(new_health, 0.0, health_total)
	var danger = danger_curve.sample(inverse_lerp(health_total, 0, health))
	if danger > 0.0:
		if $AnimationPlayer.current_animation != "Danger":
			$AnimationPlayer.play("Danger")
		$AnimationPlayer.speed_scale = clamp(danger, 0.1, 1.0)
	else:
		if $AnimationPlayer.current_animation != "Fine":
			$AnimationPlayer.play("Fine")
	if hp_bar != null:
		hp_bar.max_value = health_total
		hp_bar.value = health
		hp_bar.step = 0.05


func _update_fly_bar(new_flight : float, total : float) -> void:
	fly_total = total
	fly = clamp(new_flight, 0.0, fly_total)
	if fly_bar != null:
		fly_bar.max_value = fly_total
		fly_bar.value = fly
		fly_bar.step = 0.05


func _update_score(difference : int, total : int) -> void:
	if difference > 0:
		var new_pop = score_pop_scene.instantiate()
		new_pop.text = "+ " + str(difference)
		add_child(new_pop)
	$Center_Dock/Frame/Box1/Score.text = str(total)
	score = total


func _update_distance(dist : float) -> void:
	distance = dist
	$Center_Dock/Frame/Box2/Distance.text = str(distance) + " m"


func _player_death() -> void:
	$Health_Meter.hide()
	$Flight_Meter.hide()


func _on_play_again_pressed():
	emit_signal("play_again")


func _on_pause_pressed():
	$PauseButton.hide()
	$Pause.show()
	get_tree().paused = true


func _on_mute_pressed() -> void:
	if persist_node == null:
		_cache_persist_node()
	if persist_node == null:
		return

	if is_audio_muted:
		var granted = persist_node.request_audio_focus_global()
		if granted:
			persist_node.set_audio_muted_global(false)
		return

	persist_node.set_audio_muted_global(true)
	persist_node.abandon_audio_focus_global()


func _on_continue_pressed():
	$PauseButton.show()
	$Pause.hide()
	get_tree().paused = false


func _on_return_pressed():
	get_tree().paused = false
	emit_signal("end_game")
	self.hide()

