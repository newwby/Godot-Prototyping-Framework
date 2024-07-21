extends Definition

class_name SEPlayerDefinition

##############################################################################

# series of exports for defMgrSE to use to build SEPlayerNodes

@export var base_vol_db_adj := 0.0
@export var pitch_scale := 1.0
@export var autoplay := false
@export var bus := "Master"

@export var se_loop_behaviour =\ # (SoundEffectPlayerGlobal.LOOP_BEHAVIOUR)
		SoundEffectPlayerGlobal.LOOP_BEHAVIOUR.NEVER

# for positional sound effects
#export(float) var max_distance := 2000.0
#export(float) var attenuation := 1.0
#export(int) var area_mask := 1

##############################################################################


# init for extended definitions
#func _init():
#	self.def_id = "se"


##############################################################################


func assign_properties(arg_target: Object) -> void:
	def_properties["se_loop_behaviour"] = se_loop_behaviour
	def_properties["pitch_scale"] = pitch_scale
	def_properties["autoplay"] = autoplay
	def_properties["bus"] = bus
	def_properties["base_vol_db_adj"] = base_vol_db_adj
#	def_properties["max_distance"] = max_distance
#	def_properties["attenuation"] = attenuation
#	def_properties["area_mask"] = area_mask
	super.assign_properties(arg_target)

