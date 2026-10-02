extends Node

class_name Persist

signal audio_mute_state_changed(is_muted: bool)

@export var game_ver := 1.0
const keys = [
	"version",
	"shadows",
	"clutter",
	"music_vol",
	"sfx_vol",
	"furthest_distance",
	"highest_score",
	"total_distance",
	"total_score",
	"honey_points",
	"accessories",
	"achievements",
	"hat",
	"trail", 
	"flower"]

var shadows := true
var clutter := true
var music_vol := 0.8
var sfx_vol := 0.8

var furthest_distance := 0.0
var highest_score := 0
var total_distance := 0.0
var total_score := 0

var honey_points := 0
var accessories : PackedStringArray
var achievements : PackedStringArray

var hat := "default"
var trail := "default"
var flower := "default"

var audio_focus_plugin: Object = null
var audio_focus_connected := false
var is_audio_muted := false
var muted_by_focus_loss := false


func af_log(message: String) -> void:
	print("[AudioFocus] ", message)


func _ready() -> void:
	_connect_audio_focus_signal()


func _exit_tree() -> void:
	_disconnect_audio_focus_signal()


func _get_audio_focus_plugin() -> Object:
	if audio_focus_plugin != null:
		return audio_focus_plugin
	if !Engine.has_singleton("ReadyLinkAudioFocusPlugin"):
		return null
	audio_focus_plugin = Engine.get_singleton("ReadyLinkAudioFocusPlugin")
	return audio_focus_plugin


func _connect_audio_focus_signal() -> void:
	var plugin = _get_audio_focus_plugin()
	if plugin == null:
		return
	var callback := Callable(self, "_on_android_audio_focus_changed")
	if plugin.has_signal("focus_changed") and !plugin.is_connected("focus_changed", callback):
		plugin.connect("focus_changed", callback)
		audio_focus_connected = true


func _disconnect_audio_focus_signal() -> void:
	var plugin = _get_audio_focus_plugin()
	if plugin == null:
		return
	var callback := Callable(self, "_on_android_audio_focus_changed")
	if audio_focus_connected and plugin.is_connected("focus_changed", callback):
		plugin.disconnect("focus_changed", callback)
	audio_focus_connected = false


func request_audio_focus_global() -> bool:
	var plugin = _get_audio_focus_plugin()
	if plugin == null:
		return true

	var result = plugin.call("request_audio_focus")
	if typeof(result) == TYPE_BOOL:
		return bool(result)

	result = plugin.call("requestAudioFocus")
	if typeof(result) == TYPE_BOOL:
		return bool(result)

	af_log("request_audio_focus/requestAudioFocus method not found on singleton")
	return false


func abandon_audio_focus_global() -> void:
	var plugin = _get_audio_focus_plugin()
	if plugin == null:
		return
	plugin.call("abandon_audio_focus")


func _set_all_audio_muted(muted: bool) -> void:
	for bus_idx in range(AudioServer.get_bus_count()):
		AudioServer.set_bus_mute(bus_idx, muted)


func set_audio_muted_global(muted: bool, caused_by_focus_loss: bool = false) -> void:
	is_audio_muted = muted
	muted_by_focus_loss = muted and caused_by_focus_loss
	_set_all_audio_muted(muted)
	emit_signal("audio_mute_state_changed", is_audio_muted)


func _on_android_audio_focus_changed(focus_change: int) -> void:
	af_log("focus_changed signal value=" + str(focus_change))
	if focus_change < 0:
		if !is_audio_muted:
			set_audio_muted_global(true, true)
	elif focus_change == 1:
		# Policy: remain muted after focus regain until user explicitly unmutes.
		if muted_by_focus_loss:
			muted_by_focus_loss = false


func _save_game() -> void:
	print("Saving ...")
	var save_dict = {
		"version" = game_ver,
		"shadows" = shadows,
		"clutter" = clutter,
		"music_vol" = music_vol,
		"sfx_vol" = sfx_vol,
		"furthest_distance" = furthest_distance,
		"highest_score" = highest_score,
		"total_distance" = total_distance,
		"total_score" = total_score,
		"honey_points" = honey_points,
		"accessories" = accessories,
		"achievements" = achievements,
		"hat" = hat,
		"trail" = trail,
		"flower" = flower
	}
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	var json_string = JSON.stringify(save_dict)
	save_file.store_line(json_string)
	print("Saved!")


func _load_game() -> void:
	print("Loading ...")
	if FileAccess.file_exists("user://savegame.save"):
		var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
		print("Save File Length: ", save_file.get_length())
		var valid = true
		while save_file.get_position() < save_file.get_length():
			var json_string = save_file.get_line()
			var json = JSON.new()
			var parse = json.parse(json_string)
			if not parse == OK:
				print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
				continue
			var data = json.get_data()
			if data.has("version"):
				if data["version"] < game_ver:
					valid = false
			for k in keys:
				if !data.has(k):
					valid = false
			if valid:
				shadows = data["shadows"]
				clutter = data["clutter"]
				music_vol = data["music_vol"]
				sfx_vol = data["sfx_vol"]
				furthest_distance = data["furthest_distance"]
				highest_score = data["highest_score"]
				total_distance = data["total_distance"]
				total_score = data["total_score"]
				honey_points = data["honey_points"]
				accessories = data["accessories"]
				achievements = data["achievements"]
				hat = data["hat"]
				trail = data["trail"]
				flower = data["flower"]
				print("Loaded!")
			else:
				print("Save File is missing Data Keys")
				_file_surgery(data)
	else:
		print("No File to Load... Creating initial Save")
		_save_game()


func _file_surgery(data) -> void:
	print("Performing File Surgery")
	if data.has("shadows"):
		shadows = data["shadows"]
	if data.has("clutter"):
		clutter = data["clutter"]
	if data.has("music_vol"):
		music_vol = data["music_vol"]
	if data.has("sfx_vol"):
		sfx_vol = data["sfx_vol"]
	if data.has("furthest_distance"):
		furthest_distance = data["furthest_distance"]
	if data.has("highest_score"):
		highest_score = data["highest_score"]
	if data.has("total_distance"):
		total_distance = data["total_distance"]
	if data.has("total_score"):
		total_score = data["total_score"]
	if data.has("honey_points"):
		honey_points = data["honey_points"]
	if data.has("accessories"):
		accessories = data["accessories"]
	if data.has("achivements"):
		achievements = data["achievements"]
	if data.has("hat"):
		hat = data["hat"]
	if data.has("trail"):
		trail = data["trail"]
	if data.has("flower"):
		flower = data["flower"]
	print("File Surgery Complete, saving to rebuild")
	_save_game()


func _register_scores(score : int, distance : float) -> void:
	if score > highest_score:
		highest_score = score
	if distance > furthest_distance:
		furthest_distance = distance
	_save_game()


func _add_scores(score : int, distance : float) -> void:
	total_score += score
	total_distance += distance
	_save_game()


func _add_points(points : int) -> void:
	honey_points += points


func _spend_points(points : int) -> void:
	honey_points = clamp(
		honey_points - points, 0, honey_points
	)


func _add_accessory(acc : String) -> void:
	if !accessories.has(acc):
		accessories.append(acc)
		_save_game()


func _clear_data() -> void:
	print("CLEARING DATA")
	furthest_distance = 0.0
	highest_score = 0
	total_distance = 0.0
	total_score = 0
	honey_points = 0
	accessories = []
	hat = "default"
	trail = "default"
	flower = "default"
	_save_game()
