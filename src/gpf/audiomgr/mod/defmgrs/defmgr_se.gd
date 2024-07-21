extends DefManager

const SE_DEF_ID := "se"

func _init():
	defmgr_id = SE_DEF_ID


func _on_mod_load_finished():
	# elevated logging only added at _on_mod_load_finished due to parent
	#	class logging overwhelming console if enabled earlier
#	GlobalLog.elevate_log_permissions(self)
	# elevated log only
	GlobalLog.info(self, "reading _raw data, size "+str(_raw_data.size()), true)
	if _raw_data.is_empty():
		return
	for def_directory_key in _raw_data.keys():
		var is_base_directory: bool = (def_directory_key == defmgr_id)
		GlobalLog.info(self, "reading def_directory_key {0}, size {1}".format(
				[def_directory_key, _raw_data[def_directory_key].size()]), true)
		if is_base_directory:
			_read_base_directory(def_directory_key)
		else:
			_read_unique_directory(def_directory_key)
	
	# all defMgrs must call this at end
	super._on_mod_load_finished()


# .ogg files can be placed in the default DefManager directory (specified by
#	the property 'defmgr_id'
#a unique directory alongside a SEPlayerDefinition
#	.tres resource in order to adjust the SoundEffectPlayerGlobal object properties
#	as it is created by GlobalAudio
# the directory name will be used as the data key in this DefManager as well
#	as the key argument for the GlobalAudio.play_se method
func _read_base_directory(arg_def_directory_key: String):
		for se_data_key in _raw_data[arg_def_directory_key]:
			var se_data_value = _raw_data[arg_def_directory_key][se_data_key]
			# elevated logging only
			GlobalLog.trace(self, "se_data_key = "+str(se_data_key), true)
			GlobalLog.trace(self, "se_data_value = "+str(se_data_value), true)
			# only gets the first AudioStreamOGGVorbis under each unique key (directory or file name)
			var audio_def: AudioStreamOggVorbis = null
	#			if typeof(se_data_value) == TYPE_STRING:
			if se_data_value is AudioStreamOggVorbis:
				audio_def = se_data_value
			# is base directory
			GlobalAudio.build_se(audio_def, se_data_key)
			data[se_data_key] = audio_def


# .ogg files can be placed in a unique directory alongside a SEPlayerDefinition
#	.tres resource in order to adjust the SoundEffectPlayerGlobal object properties
#	as it is created by GlobalAudio
# the directory name will be used as the data key in this DefManager as well
#	as the key argument for the GlobalAudio.play_se method
func _read_unique_directory(arg_def_directory_key: String):
		var data_def: Definition = null
		var audio_def: AudioStreamOggVorbis = null
		for se_data_key in _raw_data[arg_def_directory_key]:
			var se_data_value = _raw_data[arg_def_directory_key][se_data_key]
			# elevated logging only
			GlobalLog.trace(self, "se_data_key = "+str(se_data_key), true)
			GlobalLog.trace(self, "se_data_value = "+str(se_data_value), true)
			# only gets the first AudioStreamOGGVorbis under each unique key (directory or file name)
	#			if typeof(se_data_value) == TYPE_STRING:
			if se_data_value is AudioStreamOggVorbis:
				audio_def = se_data_value
			elif se_data_value is Definition:
				data_def = se_data_value
		if audio_def != null:
			if data_def != null:
				GlobalAudio.build_se(audio_def, arg_def_directory_key, data_def)
				data[arg_def_directory_key] = [audio_def, data_def]
			else:
				GlobalAudio.build_se(audio_def, arg_def_directory_key)
				data[arg_def_directory_key] = audio_def


