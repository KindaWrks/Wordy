# Leaderboard.gd

extends Node

const LEADERBOARD_FILE = "user://LBoard.txt"

@onready var LBoard = $"."
@onready var LBLabel = $ScrollContainer/LeaderboardLabel

var leaderboard_data = {}

func _ready():
	load_leaderboard()
	update_lb_label()
	
func _process(_delta):
	var attempts = get_parent().attempts
	show_hide_lb()
	
	# Check for new week and reset leaderboard if it's Monday
	if get_current_weekday() == "Monday":
		reset_leaderboard()
		update_lb_label()

func load_leaderboard():
	var file = FileAccess.open(LEADERBOARD_FILE, FileAccess.READ)
	if FileAccess.file_exists(LEADERBOARD_FILE):
		file.open(LEADERBOARD_FILE, FileAccess.READ)
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			if line != "":
				var parts = line.split(":")
				if parts.size() == 2:
					leaderboard_data[parts[0].strip_edges()] = parts[1].strip_edges().to_int()
		file.close()

func save_leaderboard():
	var file = FileAccess.open(LEADERBOARD_FILE, FileAccess.WRITE)
	file.open(LEADERBOARD_FILE, FileAccess.WRITE)
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
	var lb_text = "           Leaderboard\n" + "         ________________" + "\n"
	var cumulative_total = 0
	
	for date_key in leaderboard_data.keys():
		var score = leaderboard_data[date_key]
		cumulative_total += score
		lb_text += date_key + ": " + str(score) + "\n"
	
	lb_text += "\nWeek Total: " + str(cumulative_total)
	
	LBLabel.text = lb_text

func show_hide_lb():
	if Input.is_action_just_pressed("Show_LB"):
		LBoard.visible = !LBoard.visible

func get_current_weekday():
	var day = Time.get_datetime_dict_from_system()
	return ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][day.weekday]


func calculate_week_total():
	var week_total = 0
	var current_weekday = Time.get_datetime_dict_from_system().weekday
	var days_of_week = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
	
	for day_key in leaderboard_data.keys():
		var day_index = days_of_week.find(day_key)
		if day_index <= current_weekday:
			week_total += leaderboard_data[day_key]
	
	return week_total

# Fixed monday reset bug?
func reset_leaderboard():
	if get_current_weekday() == "Monday":
		var current_week_total = calculate_week_total()
		leaderboard_data.clear()
		leaderboard_data["Monday"] = current_week_total  # Save the current Monday's score
		save_leaderboard()
	else:
		leaderboard_data.clear()
		save_leaderboard()
