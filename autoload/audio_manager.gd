extends Node

const SETTINGS_PATH := "user://settings.cfg"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const MUSIC_PLAYER_COUNT := 2
const SFX_PLAYER_COUNT := 8

var music_fade_duration := 0.8 #音乐淡出淡入时长
var _music_players: Array[AudioStreamPlayer] = []
var _sfx_players: Array[AudioStreamPlayer] = []
var _current_music_player := 0


func _ready() -> void:
	_create_players()
	_load_volumes()

# 音乐调用函数
func play_music(stream: AudioStream) -> void: 
	if stream == null:
		return
	var current := _music_players[_current_music_player]
	if current.stream == stream and current.playing:
		return
	var next_index := (_current_music_player + 1) % MUSIC_PLAYER_COUNT
	var next := _music_players[next_index]
	next.stream = stream
	next.volume_db = -40.0
	next.play()
	create_tween().tween_property(next, "volume_db", 0.0, music_fade_duration)
	if current.playing:
		var fade := create_tween()
		fade.tween_property(current, "volume_db", -40.0, music_fade_duration)
		fade.tween_callback(current.stop)
	_current_music_player = next_index

# 音效调用函数
func play_sfx(stream: AudioStream, volume := 1.0) -> void:
	if stream == null:
		return
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(clampf(volume, 0.0, 1.0))
			player.play()
			return


func set_bus_volume(bus_name: StringName, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(clampf(value, 0.0, 1.0)))
	_save_volumes()


func get_bus_volume(bus_name: StringName) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	return 1.0 if bus_index < 0 else db_to_linear(AudioServer.get_bus_volume_db(bus_index))


func _create_players() -> void:
	for index in MUSIC_PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		player.name = "Music%d" % index
		player.bus = MUSIC_BUS
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_music_players.append(player)
	for index in SFX_PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		player.name = "SFX%d" % index
		player.bus = SFX_BUS
		add_child(player)
		_sfx_players.append(player)


func _load_volumes() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	set_bus_volume(&"Master", float(config.get_value("audio", "master", 1.0)))
	set_bus_volume(MUSIC_BUS, float(config.get_value("audio", "music", 1.0)))
	set_bus_volume(SFX_BUS, float(config.get_value("audio", "sfx", 1.0)))


func _save_volumes() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", "master", get_bus_volume(&"Master"))
	config.set_value("audio", "music", get_bus_volume(MUSIC_BUS))
	config.set_value("audio", "sfx", get_bus_volume(SFX_BUS))
	config.save(SETTINGS_PATH)
