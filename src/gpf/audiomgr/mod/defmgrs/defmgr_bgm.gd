extends DefManager


func _on_mod_load_finished():
	GlobalLog.change_log_permissions(self, false)
	var bgm_value
	for defdirectory in _raw_data:
#		print(defdirectory)
		for bgm_key in _raw_data[defdirectory]:
			bgm_value = _raw_data[defdirectory][bgm_key]
			# handling for store_def_array (deprecated)
			# will only get the first file under any key (file name)
			if typeof(bgm_value) == TYPE_ARRAY:
				bgm_value = bgm_value[0]
			if bgm_value is AudioStreamOggVorbis:
				GlobalAudio.build_bgm(bgm_value, bgm_key)
				GlobalLog.info(self, "{0} {1} created at {2}".format(
					["bgm", bgm_key, bgm_value]))
	
	# all defMgrs must call this at end
	super._on_mod_load_finished()

