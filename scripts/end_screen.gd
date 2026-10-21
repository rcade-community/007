extends CanvasLayer

const VICTORY_FONT_SIZE = 32

@onready var win_text: Label = $WinText

var background: ColorRect
var kills_label: Label
var rainbow_time := 0.0
var rainbow_active := false

func _ready():
	background = ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0, 0, 0, 0)
	add_child(background)
	move_child(background, 0)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	win_text.reparent(vbox)

	kills_label = Label.new()
	kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kills_label.visible = false
	vbox.add_child(kills_label)

func _process(delta):
	if not rainbow_active:
		return
	rainbow_time += delta
	background.color = Color.from_hsv(fmod(rainbow_time * 0.3, 1.0), 0.6, 0.9)

func show_message(text: String):
	rainbow_active = false
	background.color = Color(0, 0, 0, 0)
	kills_label.visible = false
	win_text.remove_theme_font_size_override("font_size")
	win_text.text = text
	show()

func show_victory(kill_count: int):
	rainbow_active = true
	rainbow_time = 0.0
	win_text.add_theme_font_size_override("font_size", VICTORY_FONT_SIZE)
	win_text.text = "YOU WON!"
	kills_label.text = "ENEMIES DESTROYED: %d" % kill_count
	kills_label.visible = true
	show()

func hide_message():
	rainbow_active = false
	hide()
