extends Node

# URL for the updated files zip (use HTTPS for security) changed to wordy_updates repo
var url = "https://raw.githubusercontent.com/KindaWrks/wordy_updates/main/wordy_update.zip"
# Output file path (desktop)
var output_file = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP) + "/wordy_update.zip"
# Version file path (user://version.txt)
var version_file = "user://version.txt"
# Current Version
var current_version = ""
# Remote version text
var remote_version = ""
# Update comeplete confirm
@onready var UCDialog = $UCDialog
@onready var UDDialog = $UDDialog

func _ready():
	if not FileAccess.file_exists(version_file):
		var file = FileAccess.open(version_file, FileAccess.WRITE)
		file.store_string("1.0.0")  # or any other default version
		file.close()
		
	# Get current version from file (make out of func var?)
	current_version = get_version_from_file()
	# Get remote version (is this correct?)
	remote_version = get_remote_version()

func get_version_from_file():
	var version = ""
	var file = FileAccess.open(version_file, FileAccess.READ)
	if FileAccess.file_exists(version_file):
		version = file.get_as_text().strip_edges()
	else:
		print("Version file not found.")
	file.close()
	return version

func get_remote_version():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", _on_remote_version_received)
	var github_url = "https://raw.githubusercontent.com/KindaWrks/wordy_updates/main/version.txt" # Changed to wordy_updates repo
	http_request.request(github_url)

func _on_remote_version_received(_result, response_code, _headers, body):
	if response_code == 200:
		remote_version = body.get_string_from_utf8().strip_edges()
		print("Remote version:", remote_version) 
		# Compare versions and download update if necessary
		if get_version_from_file() != remote_version:
			download_update()
			UDDialog.visible = true
			print("Downloading please wait...")
		else:
			print("Version up to date!")
	else:
		print("Failed to retrieve remote version.")

func download_update():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.download_file = output_file
	http_request.connect("request_completed", _on_request_completed)
	http_request.request(url)

func _on_request_completed(_result, response_code, _headers, _body):
	if response_code == 200:
		print("Download complete!")
		UDDialog.visible = false
		UCDialog.visible = true
		update_version_file()
	else:
		print("Download failed with code ", response_code)

func update_version_file():
	var file = FileAccess.open(version_file, FileAccess.WRITE)
	if file:
		if remote_version:
			file.store_string(remote_version)
		else:
			file.store_string("")  # or a default value
		file.close()
	else:
		print("Failed to update version file.")


func _on_accept_dialog_confirmed():
	get_tree().quit()
	UCDialog.queue_free()
