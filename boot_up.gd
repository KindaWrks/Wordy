extends Node2D

var wordy_main = "res://wordy.tscn"

func _on_timer_timeout():
	get_tree().change_scene_to_file(wordy_main)
