extends AudioStreamPlayer

class_name SoundEffectPlayerGlobal

##############################################################################

# SoundEffectPlayerGlobal is an extension of a position audio playaback node (the
# AudioStreamPlayer2D class). It allows the volumes to be adjusted on
# a per sound effect basis.

# BGMPlayer and SoundEffectPlayerGlobal nodes should be automatically instantiated
# at runtime (see globalAudio & globalMod for detail) and called via
# GlobalAudio rather than directly

##############################################################################

# signal emitted when globalAudio updates a root SoundEffectPlayerGlobal and
# the root wishes to pass the update on to all duplicates
# warning-ignore:unused_signal
signal update_duplicate(property_name, property_value)

enum LOOP_BEHAVIOUR {NEVER, FINISH_PLAYING, PAUSE_STREAM}

# tracks the preset volume db at time of readying
# (so individual sound effects can have adjustments for audioStreams that
# are too loud for the intended purpose)
var initial_volume_db := 0.0

# modifies the volume db, def-set
var base_vol_db_adj = 0.0: set = _set_base_vol_db_adj
# modifies the volume db, user-set
var volume_multiplier := 1.0

var se_loop_behaviour: int = LOOP_BEHAVIOUR.NEVER: set = _set_se_loop_behaviour
var is_currently_looping: bool = false

##############################################################################

# setters and getters


func _set_base_vol_db_adj(arg_value: float):
	base_vol_db_adj = arg_value
	_set_actual_player_volume()


func _set_se_loop_behaviour(arg_value: int):
	if not arg_value in LOOP_BEHAVIOUR.values():
		GlobalLog.warning(self, "se_loop_behaviour invalid set value of "+str(arg_value))
		return
	else:
		se_loop_behaviour = arg_value
		set_stream_loop(can_loop())


##############################################################################

# virtual methods


# sound effect players should never play on being added to the scene tree,
# they should only play on being called.
func _init():
	autoplay = false


##############################################################################

# public methods


# create a unique resource when setting up a sound effect player
# separate to setter shadow preserves original non-unique/ref set function
func add_unique_stream(arg_audiostream: AudioStream):
	self.stream = arg_audiostream.duplicate()


func can_loop() -> bool:
	return (se_loop_behaviour != LOOP_BEHAVIOUR.NEVER)


func play_looping(arg_start_playing: bool = true):
	if stream == null:
		GlobalLog.warning(self, "play_looping call failed, err is_null")
		return
	if not stream is AudioStreamOggVorbis:
		GlobalLog.warning(self, "play_looping call failed, err invalid audiostream")
		return
	if se_loop_behaviour == LOOP_BEHAVIOUR.FINISH_PLAYING:
		if arg_start_playing and not is_currently_looping:
			stream.loop = true
			is_currently_looping = true
			play()
		elif not arg_start_playing:
			is_currently_looping = false
			stream.loop = false
	elif se_loop_behaviour == LOOP_BEHAVIOUR.PAUSE_STREAM:
		if arg_start_playing and not playing:
			play()
		stream_paused = !arg_start_playing
	else:
		GlobalLog.warning(self, "play_looping call failed, err invalid loop value")


func set_stream_loop(arg_value: bool):
	if stream != null:
		if stream is AudioStreamOggVorbis:
			stream.loop = arg_value
			return
	# catchall
	GlobalLog.warning(self, "set_stream_loop called but no AudioStreamOggVorbis found")


##############################################################################

# private methods


func _on_update_duplicate(arg_property_name, arg_property_value):
	if arg_property_name in self:
		# If the property does not exist or the given value's type
		# doesn't match, nothing will happen.
		set(arg_property_name, arg_property_value)
	else:
		GlobalLog.warning(self, [arg_property_name, " not found"])


func _set_actual_player_volume() -> void:
	self.volume_db = (initial_volume_db+base_vol_db_adj)*volume_multiplier

