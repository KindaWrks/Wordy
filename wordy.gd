extends Node2D
## When EXPORTING under resources include non resource/folders the_words.txt or game will crash
## as it can't locate the array do to not having the text file 
@onready var line_edit = $LineEdit
var selected = false
var dragging_start_position = Vector2()
var guess_container = VBoxContainer.new()  # Create a VBoxContainer to hold all guesses
var correct_word = ""  # Selected correct word
var correct_words = []  # Array of correct words
var attempts = 0  # Number of attempts
@onready var attempts_taken = $RichTextLabel
var current_date = ""  # Store the current date
var game_sounds = {}
@onready var fireworks = $fireworks
@onready var fireworks_mirror = $fireworks/mirrored

func _ready():
	get_viewport().transparent_bg = true
	# Load the array from a file
	load_words_from_file("res://the_words.txt", correct_words)
	
	# Select a random word from the array at the start of the game
	if correct_words.size() > 0:
		correct_word = correct_words[randi() % correct_words.size()]
	guess_container.global_position.x = 125
	guess_container.global_position.y = 20
	
	# Load the stored date from the file
	check_date()
	game_sound_effects()
	
func game_sound_effects():
	# Load and assign sounds by name
	game_sounds["clapping"] = load("res://Sounds/clapping.mp3")

	
func _process(_delta):
	if selected: # Dragging logic
		var mouse_position = get_global_mouse_position()
		var window_position = Vector2(DisplayServer.window_get_position())
		DisplayServer.window_set_position(window_position + (mouse_position - dragging_start_position))
	
	
func _on_area_2d_input_event(_viewport, _event, _shape_idx):
	if Input.is_action_just_pressed("left_click"):
		selected = true
		dragging_start_position = get_global_mouse_position()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			selected = false
			
func _on_area_2_dclose_input_event(_viewport, _event, _shape_idx):
	if Input.is_action_just_pressed("left_click"):
		get_tree().quit()
			
			
 # Get the date as 00/00/0000
func get_date():
	# Returning time/date stamp
	var time = Time.get_datetime_dict_from_system()
	@warning_ignore("shadowed_variable")
	var current_date = "%d/%02d/%02d" % \
		[time.month, time.day, time.year]
	return current_date

 # Caheck the date and lock play
func check_date():
	var current_date_str = get_date()
	var file = FileAccess.open("user://stored_date.txt", FileAccess.READ)
	if file != null:
		if file.get_error() == OK:
			var saved_date_str = file.get_line()
			file.close()
			if current_date_str == saved_date_str:
				line_edit.text = "  Come back tomorrow!"
				line_edit.editable = false  # Disable editing
				line_edit.focus_mode = false  # Disable focus
				line_edit.set_meta("mouse_filter", Control.MOUSE_FILTER_STOP)  # Stop mouse interaction
				return
		else:
			file.close()
	else:
		file = FileAccess.open("user://stored_date.txt", FileAccess.WRITE)
		file.store_line(get_date())
		file.close()
	
	# load word array from text file
func load_words_from_file(filename, array):
	var file = FileAccess.open(filename, FileAccess.READ)
	if file != null:
		while not file.eof_reached():
			var line = file.get_line()
			array.append(line.to_upper())
		file.close()
	else:
		print("Error loading file")

 # Text submisson and attempt setting
func _on_line_edit_text_submitted(text):
	# Check if the current date has changed
	var new_date = get_date()
	if new_date != current_date:
		attempts = 0  # Reset attempts
		current_date = new_date  # Update the current date
	
	attempts += 1
	
	line_edit.text = ""
	line_edit.caret_column = line_edit.text.length()
	line_edit.caret_blink = true

	if attempts <= 6:
		if text.length() > correct_word.length():
			line_edit.text = "Words are five letters!"
			attempts -= 1 
			line_edit.caret_column = line_edit.text.length()
			line_edit.caret_blink = true
			return

		var input_array = text.to_upper().split("")  # Convert input to uppercase
		
		var button_container = HBoxContainer.new()

		for i in range(input_array.size()):
			var letter = input_array[i]
			var button = create_button(letter, i)
			button_container.add_child(button)

			if letter == correct_word.to_upper()[i]:  # Compare with uppercase correct word
				button.modulate = Color.GREEN
			elif correct_word.to_upper().find(letter) != -1:
				button.modulate = Color.YELLOW
			else:
				button.modulate = Color.RED

		guess_container.add_child(button_container)


	if text.to_upper() == correct_word.to_upper():  # Check if the entire word is correct (uppercase)
		line_edit.queue_free()
		attempts_taken.visible = true  # Temp richtextlabel to have a guess amounts win screen
		attempts_taken.text = "It took you " + str(attempts) + " attempts!"
		$AudioStreamPlayer.stream = game_sounds["clapping"]
		$AudioStreamPlayer.play()
		fireworks.visible = true
		fireworks.play("stars")
		fireworks_mirror.play("stars_mirror")
		# Save the current date here
		var file = FileAccess.open("user://stored_date.txt", FileAccess.WRITE)
		file.store_line(get_date())
		file.close()
	else:
		if attempts == 6:
			line_edit.text = "Correct answer: " + correct_word.to_upper()
			line_edit.editable = false  # Disable editing
			line_edit.focus_mode = false  # Disable focus
			line_edit.set_meta("mouse_filter", Control.MOUSE_FILTER_STOP)  # Stop mouse interaction
			# Save the current date here
			var file = FileAccess.open("user://stored_date.txt", FileAccess.WRITE)
			file.store_line(get_date())
			file.close()

	get_node("/root/Wordy").add_child(guess_container)
	
	# button creation
func create_button(letter, i):
	var sprite = Sprite2D.new()
	var texture

	if letter == correct_word.to_upper()[i]:  # Correct letter
		texture = load("res://Letters/" + letter + "_green.png")
	elif correct_word.to_upper().find(letter) != -1:  # Present in word, wrong spot
		texture = load("res://Letters/" + letter + "_yellow.png")
	else:  # Wrong letter
		texture = load("res://Letters/" + letter + "_red.png")

	sprite.texture = texture
	sprite.scale = Vector2(1, 1)  # Adjust the scale as needed
	
	# Calculate the position of the sprite
	var x = (i * (sprite.texture.get_size().x + 3))  # Add 3 pixels of spacing
	var y = (3 + (attempts * 30))  # Increase y position by 30 pixels for each attempt
	
	sprite.position = Vector2(x, y)  # Set the position of the sprite
	
	return sprite
