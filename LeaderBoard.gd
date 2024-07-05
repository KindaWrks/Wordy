# Leaderboard.gd

extends Node

const LEADERBOARD_FILE = "user://LBoard.txt"

@onready var LBoard = $"."
@onready var LBLabel = $LeaderboardLabel

var leaderboard_data = {}

func _ready():
	load_leaderboard()
	update_lb_label()
	
func _process(_delta):
	var attempts = get_parent().attempts
	show_hide_lb()

func load_leaderboard():
	var file = FileAccess.open(LEADERBOARD_FILE, FileAccess.READ)
	if FileAccess.file_exists(LEADERBOARD_FILE):
		FileAccess.open(LEADERBOARD_FILE, FileAccess.READ)
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			if line != "":
				var parts = line.split(":")
				if parts.size() == 2:
					leaderboard_data[parts[0].strip_edges()] = parts[1].strip_edges().to_int()
		file.close()

func save_leaderboard():
	var file = FileAccess.open(LEADERBOARD_FILE, FileAccess.WRITE)
	FileAccess.open(LEADERBOARD_FILE, FileAccess.WRITE)
	for date_key in leaderboard_data.keys():
		file.store_line(date_key + ": " + str(leaderboard_data[date_key]))
	file.close()

func update_score(attempts):
	var current_date = get_current_weekday()
	
	# Calculate score based on attempts
	var score = 5 - (attempts - 1)
	if score < 0:
		score = 0
	
	if current_date not in leaderboard_data:
		leaderboard_data[current_date] = 0
	
	leaderboard_data[current_date] += score
	
	save_leaderboard()
	
func update_lb_label():
	# Construct text to display in the label
	var lb_text = "           Leaderboard\n" + "         ________________" + "\n"
	for date_key in leaderboard_data.keys():
		lb_text += date_key + ": " + str(leaderboard_data[date_key]) + "\n"
	
	LBLabel.text = lb_text
	
func show_hide_lb():
	if Input.is_action_just_pressed("Show_LB"):
		LBoard.visible = !LBoard.visible
	

func get_current_weekday():
	var day = Time.get_datetime_dict_from_system()
	return ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][day.weekday]

func check_new_week():
	var current_date = get_current_weekday()
	if current_date not in leaderboard_data:
		return true
	else:
		return false
