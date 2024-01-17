extends Control

# where changed emotion lists are saved
const EMOTIONS_SAVE_FILE = "user://emotions.txt"
# defaults (for resetting)
const default_emotions = {
	"anger":{"color":"(0.7412, 0.2824, 0.3059, 1)","emotions":["frustrated","jealous","mad","furious"]},
	"fear":{"color":"(0.5922, 0.5882, 0.6706, 1)","emotions":["nervous","insecure","embarassed","frightened","panicked"]},
	"happy":{"color":"(0.5373, 0.8588, 0.3882, 1)","emotions":["proud","confident","excited","hopeful","elation"]},
	"peaceful":{"color":"(0.6039, 0.3882, 0.7804, 1)","emotions":["affectionate","relaxed","thankful","passionate"]},
	"sad":{"color":"(0.3294, 0.4627, 0.7804, 1)","emotions":["bored","tired","guilty","inferior","hopeless"]},
	"surprise":{"color":"(0.3686, 0.5961, 0.749, 1)","emotions":["startled","confused","speechless","amazed","bewildered"]}
}

var emotions = default_emotions

@onready var tree = $Tree

func _ready():
	
	# load previous changes, if they exist
	load_emotions(EMOTIONS_SAVE_FILE)
	
	# show a random emotion
	get_random_emotion()
	
	# setup settings button and emotion list
	$SettingsButton.pressed.connect(_on_settings_pressed)
	tree.button_clicked.connect(_on_tree_button_pressed)
	reset_tree()


func reset_tree():
	# clear everything for reset
	tree.clear()
	# create and hide root to give multi-root tree
	var root = tree.create_item()
	tree.hide_root = true
	# for every emotion type
	for category in emotions.keys():
		# create colored heading
		var branch = tree.create_item(root)
		branch.set_text(0, category)
		branch.set_custom_bg_color(0, parse_color(emotions[category]["color"]))
		branch.set_selectable(0, false)
		# for every emotion in emotion type
		for emotion in emotions[category]["emotions"]:
			# add emotion and remove button
			var twig = tree.create_item(branch)
			twig.set_text(0, emotion)
			twig.add_button(0, load("res://icons/cross.png"), 1)
			twig.set_selectable(0, false)
		# add new emotion button
		var new_emotion = tree.create_item(branch)
		new_emotion.set_editable(0, true)
		new_emotion.set_text(0, "New Emotion")
		new_emotion.add_button(0, load("res://icons/plus.png"), 0)
	# add reset to default button
	var reset = tree.create_item(root)
	reset.set_text(0, "Reset to Default")
	reset.add_button(0, load("res://icons/return.png"), 2)
	reset.set_custom_bg_color(0, Color.GHOST_WHITE)
	reset.set_selectable(0, false)


func _unhandled_input(event):
	# if on computer (devloping), get random emotion on left click
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_random_emotion()
	# if on mobile, get random emotion on screen touch
	elif event is InputEventScreenTouch and event.pressed:
		get_random_emotion()


# change color string in JSON to Godot Color
func parse_color(color_string):
	var color = color_string.replace("(", "")
	color = color.replace(")", "")
	var color_array = color.split(", ")
	return Color(float(color_array[0]), float(color_array[1]), float(color_array[2]), float(color_array[3]))


# get random emotion and color from dictionary
func get_random_emotion():
	var category = emotions[emotions.keys()[randi() % emotions.size()]]
	$BackgroundColor.color = parse_color(category["color"])
	$EmotionContainer/EmotionLabel.text = category["emotions"][randi() % category["emotions"].size()]


# save emotion dictionary to file using JSON
func save_emotions(file):
	var save = FileAccess.open(file, FileAccess.WRITE)
	var data = JSON.stringify(emotions)
	save.store_line(data)


# try and load emotion dictionary from file using JSON
func load_emotions(file):
	if not FileAccess.file_exists(file):
		return
	
	var save_data = FileAccess.open(file, FileAccess.READ)
	var json = save_data.get_line()
	emotions = JSON.parse_string(json)


func _on_tree_button_pressed(item, column, id, _mouse_button_index):
	print(item.get_text(column))
	# if reset button, reset emotions to default
	if id == 2:
		print("reseting")
		emotions = default_emotions
		reset_tree()
		save_emotions(EMOTIONS_SAVE_FILE)
		return
	
	# otherwise, get emotion and emotion type
	var category = emotions[item.get_parent().get_text(column)]
	var emotion_array = category["emotions"]
	if id == 0:
		# add the emotion if adding
		print("add emotion")
		emotion_array.append(item.get_text(column))
	elif id == 1:
		# remove emotion if removing
		print("remove emotion")
		# keep one emotion no matter what, so no divide by zero in random checks
		if emotion_array.size() > 1:
			emotion_array.erase(item.get_text(column))
	else:
		push_error("invalid button id")
	
	# update visuals and save changes
	reset_tree()
	save_emotions(EMOTIONS_SAVE_FILE)


# toggle emotion list visiblity
func _on_settings_pressed():
	tree.visible = not tree.visible
