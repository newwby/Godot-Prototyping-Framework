extends GameGlobal

#class_name GlobalAudio

##############################################################################

# GlobalAudio is a singleton that instantiates SoundEffectPlayerGlobal and BGMPlayer
# nodes from resources saved in the usr://def/core/audio directory.

#//TODO
# add duplicate check and error for duplicate key on both build_bgm and
# need support for bus assignment, pitch scale, mix target, pausing streams

##############################################################################

signal audio_bus_data_saved(audio_bus_name)
signal audio_config_loaded()
signal audio_config_saved()

const AUDIO_CONFIG_PATH := "user://bus_data.ini"

# optional flag for overwriting config file at runtime, thus simulating
#	a new user experience
# DEV NOTE: make sure to back up your previous config file if you wish to keep
#	it, as enabling this argument will not preserve it
# specify as a command-line argument in editor/main_run_args (for debug versions)
#	or in the executable path arguments (for release versions)
const CMD_ARG_IGNORE_CONFIG := "reset_audio"

# config ini keys for saving loading the persistent AudioBusData settings
# currently creating AudioBusData at runtime and then changing properties
#	after loading from disk, but could shift to a model where the AudioBusData
#	resources are saved to user:// instead
const BUS_KEY_AMP := "amplitude"
const BUS_KEY_MUTE := "is_muted"

# stores AudioBusData objects as values using the name of the AudioBus as key
var audio_bus_data := {}

# the config file that audio bus data is saved to
var audio_config: ConfigFile = null

# key is the file name, value is the bgmPlayer created from the file
var bgm_register = {}
# key is the file name, value is the sePlayer created from the file
var se_register = {}

##############################################################################

# virtual methods


# Called when the node enters the scene tree for the first time.
func _ready():
	# config options are skipped if a specific testing option is enabled
	# if it is not present, load config as normal
	# if it is, overwrite the audio config with a blank config
	var write_new_config: bool = GlobalFunc.has_cmd_arg(CMD_ARG_IGNORE_CONFIG)
	
	# set up audio data and configs
	_store_base_bus_data()
	_verify_audio_config(write_new_config)
	_read_audio_config()
	
	# log if debug option on, so the forgetful main developer doesn't leave
	#	it on and push to production
	if write_new_config:
		GlobalLog.warning(self, "{0} flag enabled; overwriting audio_config file".format([CMD_ARG_IGNORE_CONFIG]))


##############################################################################

# public methods


# creates a BackgroundMusicPlayer node and registers it with the singleton
#	(so it can be called with play_bgm public method)
# must be passed an audio resource of the .ogg format
func build_bgm(
		arg_audio_resource: AudioStreamOggVorbis,
		arg_file_name: String = "") -> void:
	var new_bgm_player = BackgroundMusicPlayer.new()
	var audio_register_key: String
	if arg_file_name != "":
		new_bgm_player.name = arg_file_name
		audio_register_key = arg_file_name
	elif arg_file_name == "":
		audio_register_key = str(self)
	new_bgm_player.add_unique_stream(arg_audio_resource)
	bgm_register[audio_register_key] = new_bgm_player
	self.call_deferred("add_child", new_bgm_player)


# creates a SoundEffectPlayerGlobal node and registers it with the singleton
#	(so it can be called with play_se public method)
# must be passed an audio resource of the .ogg format
func build_se(
		arg_audio_resource: AudioStreamOggVorbis,
		arg_file_name: String = "",
		arg_data_definition: Definition = null) -> void:
	if arg_audio_resource == null:
		GlobalLog.error(self, "build_se called with invalid params: "+\
				"audio {0}, key {1}, datadef {2}".format([
					arg_audio_resource, arg_file_name, arg_data_definition]))
		return
	if arg_file_name == "":
		GlobalLog.error(self, "build_se called with invalid key")
		return
	arg_audio_resource.loop = false
	var new_se_player = SoundEffectPlayerGlobal.new()
	var audio_register_key: String
	if arg_file_name != "":
		new_se_player.name = arg_file_name
		audio_register_key = arg_file_name
	elif arg_file_name == "":
		audio_register_key = str(self)
	new_se_player.add_unique_stream(arg_audio_resource)
	se_register[audio_register_key] = new_se_player
	if arg_data_definition != null:
		arg_data_definition.assign_properties(new_se_player)
	self.call_deferred("add_child", new_se_player)


func bus_get_vol_by_name(arg_audio_bus_name: String) -> float:
	var bus_index = AudioServer.get_bus_index(arg_audio_bus_name)
	if bus_index <= AudioServer.bus_count-1 and bus_index >= 0:
		return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(arg_audio_bus_name))
	else:
		GlobalLog.error(self, "could not find bus name {1}, returned index {2}; method returning nil volume".\
				format([arg_audio_bus_name, bus_index]))
		return 0.0


func bus_set_vol_by_name(arg_audio_bus_name: String, arg_new_vol_db: float = 0.0) -> void:
	var bus_index = AudioServer.get_bus_index(arg_audio_bus_name)
	if bus_index <= AudioServer.bus_count-1 and bus_index >= 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(arg_audio_bus_name), arg_new_vol_db)
	else:
		GlobalLog.error(self, "could not find bus name {1}, returned index {2}".\
				format([arg_audio_bus_name, bus_index]))


func bus_mute_by_name(arg_audio_bus_name: String, arg_mute: bool = true) -> void:
	var bus_index = AudioServer.get_bus_index(arg_audio_bus_name)
	if bus_index <= AudioServer.bus_count-1 and bus_index >= 0:
		AudioServer.set_bus_mute(AudioServer.get_bus_index(arg_audio_bus_name), arg_mute)
	else:
		GlobalLog.error(self, "could not find bus name {1}, returned index {2}".\
				format([arg_audio_bus_name, bus_index]))


# method to duplicate a sound effect and return it to the caller
# can be used as part of an onready var setup to add a sound effect player
# node to an entity or other node
# entities (such as players/enemies/objects) should parent their own sound
# effects, for positional audio
# will return a reference to the new sound effect
# will return null if the key isn't found in the se_register
# (remember to check new seplayer is inside tree before doing anything with it)
func duplicate_se(arg_audio_key: String, parent: Node) -> SoundEffectPlayerGlobal:
	var new_se = null
	var get_potential_se = get_se(arg_audio_key)
	if get_potential_se is SoundEffectPlayerGlobal:
		new_se = get_potential_se.duplicate()
		if new_se is SoundEffectPlayerGlobal:
			get_potential_se.connect(
					"update_duplicate", new_se, "_on_update_duplicate")
	if parent.is_inside_tree()\
	and new_se != null:
		parent.call_deferred("add_child", new_se)
	return new_se


func fetch_audio_config() -> ConfigFile:
	if GlobalData.validate_file(AUDIO_CONFIG_PATH):
		var expected_config = ConfigFile.new()
		var err = expected_config.load(AUDIO_CONFIG_PATH)
		# If the file didn't load, ignore it.
		if err != OK:
			return null
		else:
			return expected_config
	else:
		return null


func fetch_bus_data(arg_bus_name: String) -> AudioBusData:
	if audio_bus_data.has(arg_bus_name):
		var bus_data = audio_bus_data[arg_bus_name]
		if bus_data is AudioBusData:
			return bus_data
	# else
	return null


func get_bgm(arg_audio_key: String) -> BackgroundMusicPlayer:
	var bgm_node: BackgroundMusicPlayer = null
	if bgm_register.has(arg_audio_key):
		bgm_node = bgm_register[arg_audio_key]
	return bgm_node


func get_se(arg_audio_key: String) -> SoundEffectPlayerGlobal:
	var se_node: SoundEffectPlayerGlobal = null
	if se_register.has(arg_audio_key):
		se_node = se_register[arg_audio_key]
	return se_node


# does nothing if bgm not found, check with bgm_register.has() before calling
func play_bgm(arg_audio_key: String) -> void:
	var get_audiostream = get_bgm(arg_audio_key)
	if get_audiostream is BackgroundMusicPlayer:
		get_audiostream.play()


# does nothing if se not found, check with se_register.has() before calling
# play_se should be used for sound effects when you have a custom listener
# set up, or the camera is stationary (i.e. whilst using an interface)
# for sound effects played during normal gameplay use duplicate_se instead
func play_se(arg_audio_key: String) -> void:
	var seplayer_node: SoundEffectPlayerGlobal = get_se(arg_audio_key)
	if seplayer_node != null:
		if seplayer_node.can_loop() == false:
			seplayer_node.play()
		else:
			GlobalLog.warning(self, "{0} called on {1} se, key: {2}".format([
				"play_se", "stream_can_looping", str(arg_audio_key)]))


func play_se_stream(arg_audio_key: String) -> void:
	var seplayer_node: SoundEffectPlayerGlobal = get_se(arg_audio_key)
	if seplayer_node != null:
		if seplayer_node.can_loop():
			seplayer_node.play_looping()
		else:
			GlobalLog.warning(self, "{0} called on {1} se, key: {2}".format([
				"play_se_stream", "non-stream_can_looping", str(arg_audio_key)]))


func stop_se_stream(arg_audio_key: String) -> void:
	var seplayer_node: SoundEffectPlayerGlobal = get_se(arg_audio_key)
	if seplayer_node != null:
		if seplayer_node.can_loop():
			seplayer_node.play_looping(false)
		else:
			GlobalLog.warning(self, "{0} called on {1} se, key: {2}".format([
				"stop_se_stream", "non-stream_can_looping", str(arg_audio_key)]))


# as play_se but checks if interface_sounds_allowed is true before passing
func play_ui_se(arg_audio_key: String) -> void:
	if arg_audio_key == "":
		GlobalLog.debug_warning(self, "play_ui_se called with empty string")
	# interface_sounds_allowed allows blocking unwanted se on focus grab
	#	(i.e. with the GlobalInterface method 'grab_focus_quiet')
	elif GlobalInterface.interface_sounds_allowed:
		play_se(arg_audio_key)


# update the property of a SoundEffectPlayerGlobal registered by globalAudio, and
# any sound effects previously duplicated from that SoundEffectPlayerGlobal
func update_se(
		arg_audio_key: String,
		arg_property_name: String,
		arg_property_value):
	# find seplayer
	var target_seplayer = get_se(arg_audio_key)
	# check valid
	if not target_seplayer is SoundEffectPlayerGlobal:
		GlobalLog.warning(self,
					[target_seplayer, " not seplayer"])
	# update self and propagate the update
	if target_seplayer is SoundEffectPlayerGlobal:
		target_seplayer._on_update_duplicate(
					arg_property_name, arg_property_value)
		target_seplayer.emit_signal(
				"update_duplicate", arg_property_name, arg_property_value)


# can pass a previously loaded config file if desired
func write_audio_config() -> void:
	if is_instance_valid(audio_config) == false:
		audio_config = fetch_audio_config()
		if is_instance_valid(audio_config) == false:
			GlobalLog.error(self, "write_audio_config error - config file missing")
			return

	# save game audio data
	var bus_data = null
	for bus_name in audio_bus_data.keys():
		bus_data = audio_bus_data[bus_name]
		if not bus_data is AudioBusData:
			GlobalLog.error(self, "bus data for {0} invalid type".format([bus_name]))
		else:
			audio_config.set_value("Volume", bus_name, {
				BUS_KEY_AMP: bus_data.amplitude,
				BUS_KEY_MUTE: bus_data.is_muted}
			)
	
	# save config file to disk
	if audio_config.save(AUDIO_CONFIG_PATH) != OK:
		GlobalLog.warning(self, "could not save audio_config to "+AUDIO_CONFIG_PATH)
	else:
		emit_signal("audio_config_saved")


# can pass a previously loaded config file if desired
func write_bus_data(arg_bus_data: AudioBusData) -> void:
	if is_instance_valid(arg_bus_data) == false:
		return
	if arg_bus_data.name == "":
		GlobalLog.error(self, "write_bus_data error - audio bus data invalid")
		return
	
	if is_instance_valid(audio_config) == false:
		audio_config = fetch_audio_config()
		if is_instance_valid(audio_config) == false:
			GlobalLog.error(self, "write_bus_data error - config file missing")
			return
	
	# dostuff
	audio_config.set_value("Volume", arg_bus_data.name, {
		BUS_KEY_AMP: arg_bus_data.amplitude,
		BUS_KEY_MUTE: arg_bus_data.is_muted})
	
	# save config file to disk
	if audio_config.save(AUDIO_CONFIG_PATH) != OK:
		GlobalLog.warning(self, "could not save audio_config to "+AUDIO_CONFIG_PATH)
	else:
		emit_signal("audio_bus_data_saved", arg_bus_data.name)


##############################################################################

# private methods

func _read_audio_config() -> void:
	if audio_bus_data.is_empty():
		GlobalLog.error(self, "config audio tried to load before base AudioBusData was loaded")
		#//TODO add is_ready property/signal yield handling
		return
	if is_instance_valid(audio_config) == false:
		audio_config = fetch_audio_config()
		if is_instance_valid(audio_config) == false:
			GlobalLog.error(self, "write_audio_config error - config file missing")
			return
	
	var bus_db = null
	if not audio_config.has_section("Volume"):
		GlobalLog.warning(self, "could not load config audio, missing section")
		return
	var config_volume_section = audio_config.get_section_keys("Volume")
	for bus_key in config_volume_section:
		if audio_bus_data.has(bus_key):
			bus_db = audio_bus_data[bus_key]
			if not bus_db is AudioBusData:
				GlobalLog.error(self, "non-AudioBusData stored in audio_bus_data")
			# else
			var bus_config_values = audio_config.get_value("Volume", bus_key)
			if not typeof(bus_config_values) == TYPE_DICTIONARY:
				GlobalLog.error(self, "volume config entry not stored as dict")
			if bus_config_values.has(BUS_KEY_AMP):
				bus_db.amplitude = bus_config_values[BUS_KEY_AMP]
			if bus_config_values.has(BUS_KEY_MUTE):
				bus_db.is_muted = bus_config_values[BUS_KEY_MUTE]
				# elevated log only
				GlobalLog.info(self, "bus_key {0} loading bus_db.is_muted {1}".\
						format([bus_key, bus_db.is_muted]), true)
	# finish
	emit_signal("audio_config_loaded")


func _store_base_bus_data() -> void:
	var bus_name := ""
	var base_bus_db := 0.0
	for idx in range(AudioServer.bus_count):
		bus_name = ""
		base_bus_db = 0.0
		bus_name = AudioServer.get_bus_name(idx)
		base_bus_db = AudioServer.get_bus_volume_db(idx)
		var bus_data_obj = AudioBusData.new(bus_name, base_bus_db)
		if bus_data_obj is AudioBusData:
			if bus_data_obj.connect("save_to_disk", Callable(self, "write_bus_data").bind(bus_data_obj)) != OK:
				GlobalLog.warning(self, "audio bus data for "+bus_name+" save signal failed")
		audio_bus_data[bus_name] = bus_data_obj


# checks if audio config exists, writes the default audio config to disk if not
# if arg_force_reset is specified the existing audio_config will be
#	overwritten, use with caution
func _verify_audio_config(arg_force_reset: bool = false) -> void:
	var expected_config = fetch_audio_config()
	if is_instance_valid(expected_config) and arg_force_reset == false:
		self.audio_config = expected_config
	else:
		self.audio_config = ConfigFile.new()
		write_audio_config()


# unknown usage so deprecated
#func _update_se_register():
#	pass


# unknown usage so deprecated
#func _update_bgm_register():
#	pass

