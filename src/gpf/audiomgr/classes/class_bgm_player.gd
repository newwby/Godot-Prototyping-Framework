extends AudioStreamPlayer

class_name BackgroundMusicPlayer

##############################################################################

# BGMPlayer is an extension of an audio playaback node (the AudioStreamPlayer
# class). It allows the volumes to be adjusted on a per bgm track basis.

# BGMPlayer and SoundEffectPlayer nodes should be automatically instantiated
# at runtime (see globalAudio & globalMod for detail) and called via
# GlobalAudio rather than directly

##############################################################################

# tracks the preset volume db at time of readying
# (so individual sound effects can have adjustments for audioStreams that
# are too loud for the intended purpose)
var initial_volume_db := 0.0

# modifies the volume db, user-set
var volume_multiplier := 1.0

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


##############################################################################

# private methods


#func example_method():
#	pass

