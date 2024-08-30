extends Node

############################################ VARIABLES #########################################################

signal player_played_card()

@onready var player_deck = $"../TableGame/Deck"							# Bonus-card deck
@onready var player_hand_cards = $"../TableGame/PlayerCards"			# Players hand cards
@onready var field_cards_preview = $"../TableGame/BigCardsOnField"		# Preview cards (left)
@onready var player_edit_cards = $"../TableGame/EditCards"				# Edit cards (right)
@onready var play_card_button = $GameBoard/PlayCardButton				# Button to play card
@onready var draw_card_button											# Button to draw bonus-card

# Static card data
var style_boxes

# All card colors
var colors = {Color("#ea4d53"): "red",
			  Color("#ebbc6d"): "yellow",
			  Color("#328948"): "green",
			  Color("#554dc9"): "blue",
			  Color("#989595"): "grey",
			  Color("#7fffd4"): "aquamarine"}

# Card texts (grey bonus cards get text based on effect)
var card_types = {"red":    "EMOTIONEN\nWie fühlst du dich in Bezug auf das zu reflektierende Thema? Welche positiven oder negativen Gefühle empfindest du?\n[ Fang an zu tippen.. ]",
				  "yellow": "FAKTEN\nWelche für deine Reflektion relevanten Fakten, Daten, Informationen fallen dir ein?\n[ Fang an zu tippen.. ]",
				  "green":  "OPTIMISMUS\nWelche Vorteile oder Möglichkeiten ergeben sich?\n[ Fang an zu tippen.. ]",
				  "blue":   "KREATIVITÄT\nWelche verrückten oder eher fernen Dinge fallen die zu deinem Thema ein?\n[ Fang an zu tippen.. ]",
				  "aquamarine": "REFLEKTION\nWorüber möchtest du diese Runde reflektieren? Schreibe dein Thema auf.\n[ Fang an zu tippen.. ]"}

# Card icons (grey bonus cards get icons based on effect, aquamarine does not need an icon)
var card_icons = {"red":    "res://ressources/icons/face.svg",
				  "yellow": "res://ressources/icons/note.svg",
				  "green":  "res://ressources/icons/thumb.svg",
				  "blue":   "res://ressources/icons/bulb.svg"}

# Bonus card effect text
var bonus_card_effects = {"joker": "Entferne eine gegnerische Karte aus dem Spiel und bekomme eine beliebige Perspektivenkarte auf die Hand.",
						  "switch": "Wähle eine Karte und tausche die Position mit einem nicht gelockten Feld (andere Karte oder leeres Feld).", 
						  "doublepoints": "Spiele diese Karte auf ein Feld. Alle mit diesem Feld verdienten Punkte werden verdoppelt.",
						  "lock":  "Reserviere ein leeres Feld für dich, der Gegner kann darauf keine Karte spielen.\n\nODER\n\nSperre eine Karte. Gesperrte Karten können nicht entfernt oder bewegt werden."}

# Bonus card icons
var bonus_card_icons = {"joker": "res://ressources/icons/joker.svg",
						 "switch": "res://ressources/icons/switch.svg", 
						 "doublepoints": "res://ressources/icons/doublepoints.png",
						 "lock": "res://ressources/icons/lock.svg"}

# information for game
var gameboard_fields : Array
var field_is_selected : bool = false
var selected_field : ReferenceRect = null
var active_card : Panel = null
var edit_to_hand_cards : Dictionary = {}
var field_to_preview_cards : Dictionary = {}
var bonus_cards : Dictionary = {}
var reflection_card_filled : bool = false

############################################ PROCESS #########################################################

func _process(_delta):
	
	# Update visibility of play button
	if field_is_selected and active_card != null:
		play_card_button.visible = true
	else:
		play_card_button.visible = false
	
	# Update text for hand cards according to edit
	for edit_card in edit_to_hand_cards.keys():
		var edit_card_text = edit_card.get_child(0).text
		if len(edit_card_text) == 0:
			edit_to_hand_cards[edit_card].get_child(1).visible = true
			edit_to_hand_cards[edit_card].get_child(0).text = ""
		else:
			edit_to_hand_cards[edit_card].get_child(1).visible = false
			edit_to_hand_cards[edit_card].get_child(0).text = edit_card_text

############################################ INITIATION #########################################################

# Loaded when entering tavern
func _ready():
	initiate_gameboard()

# Prepare game without player cards, after filling reflection card initiate player cards
func initiate_gameboard():
	if !reflection_card_filled:
		initiate_style_boxes()
		initiate_field_buttons()
		initiate_reflection_card()
	else:
		initiate_player_cards()
		initiate_player_deck()

# Prepare style boxes for cards
func initiate_style_boxes():
	style_boxes = {}
	for color in colors.keys():
		var new_style_box = StyleBoxFlat.new()
		new_style_box.bg_color = color
		new_style_box.border_width_left = 1
		new_style_box.border_width_top = 1
		new_style_box.border_width_right = 1
		new_style_box.border_width_bottom = 1
		new_style_box.border_color = Color("#000000")
		style_boxes[colors[color]] = new_style_box

############################################ FIELD #########################################################

# Prepare fields with buttons
func initiate_field_buttons():
	gameboard_fields = self.find_child("GameBoard").get_child(0).get_child(0).get_child(0).get_children()
	for field in gameboard_fields:
		var new_button = Button.new()
		new_button.custom_minimum_size = Vector2(35, 35)
		new_button.flat = true
		field.add_child(new_button)
		new_button.connect("focus_entered", func(): _field_selected(new_button))
		new_button.connect("focus_exited", func(): _field_deselected())
		new_button.connect("mouse_entered", func(): _hovering_over_button(new_button))
		new_button.connect("mouse_exited", func(): _stop_hovering_over_button(new_button))
	play_card_button.connect("button_down", func(): _play_card())

func _field_selected(button):
	field_is_selected = true
	selected_field = button.get_parent()

func _field_deselected():
	field_is_selected = false

func _hovering_over_button(button):
	if button.get_parent().get_child(1).get_class() == "Panel":
		var field_card = button.get_parent().get_child(1)
		field_to_preview_cards[field_card].visible = true

func _stop_hovering_over_button(button):
	if button.get_parent().get_child(1).get_class() == "Panel":
		var field_card = button.get_parent().get_child(1)
		field_to_preview_cards[field_card].visible = false

# Prepare reflection card
func initiate_reflection_card():
	var reflection_card_edit = create_edit_card(colors[colors.keys()[5]])
	reflection_card_edit.visible = true
	active_card = reflection_card_edit

############################################ PLAYER #########################################################

# Prepare player hand cards
func initiate_player_cards():
	for color in ["red", "yellow", "green", "blue"]:
		create_hand_card(color, card_icons[color])
		create_hand_card(color, card_icons[color])

# Prepare player bonus card deck
func initiate_player_deck():
	var effects = generate_random_effects()
	for i in range(3):
		var next_card = create_small_card("grey", "Icon", bonus_card_icons[effects[i]], bonus_card_effects[effects[i]])
		next_card.position = Vector2(0 + 2*i, 0 - 2*i)
		player_deck.add_child(next_card)
		var next_card_big = create_big_card("grey", "Preview", bonus_card_effects[effects[i]])
		player_edit_cards.add_child(next_card_big)
		bonus_cards[effects[i]] = next_card_big
	var new_draw_button = Button.new()
	new_draw_button.size = Vector2(39, 39)
	new_draw_button.position = Vector2(0, -4)
	new_draw_button.flat = true
	player_deck.add_child(new_draw_button)
	draw_card_button = new_draw_button
	draw_card_button.connect("button_down", func(): _draw_button_pressed(draw_card_button))
	draw_card_button.connect("button_up", func(): _draw_button_released(draw_card_button))

func generate_random_effects():
	var random_effects = ["switch", "doublepoints", "lock"]
	random_effects.shuffle()
	random_effects = random_effects.slice(0,2)
	random_effects.append("joker")
	random_effects.shuffle()
	return random_effects

func _draw_button_pressed(button):
	button.grab_focus()

func _draw_button_released(button):
	button.release_focus()
	_show_next_bonus_card()

func _show_next_bonus_card():
	_click_hand_card(bonus_cards.values()[len(bonus_cards)-1])

func _click_hand_card(edit_card):
	
	if !reflection_card_filled:
		return
	
	for card in player_edit_cards.get_children():
		if card == edit_card:
			edit_card.visible = !edit_card.visible
			if edit_card.visible:
				active_card = edit_card
			else:
				active_card = null
		else:
			card.visible = false

############################################ PLAYING CARD #########################################################

# Play card
func _play_card():
	if play_card_on_field_allowed(active_card, selected_field):
		execute_play_card()
	else:
		print("This move is not allowed!")

func play_card_on_field_allowed(_active_card, field):
	return field.get_child(1).get_class() != "Panel"

func execute_play_card():
	
	if reflection_card_filled:
		pass
	else:
		create_preview_card(colors[colors.keys()[5]], active_card.get_child(0).text)
		var reflection_card_small = create_small_card(colors[colors.keys()[5]], "Text", "res://ressources/icons/puzzleteil.png", active_card.get_child(0).text)
		self.get_node("ReflectionCardSlot").add_child(reflection_card_small)
		
		var reflection_button = Button.new()
		reflection_button.custom_minimum_size = Vector2(35, 35)
		reflection_button.flat = true
		reflection_button.focus_mode = Control.FOCUS_NONE
		self.get_node("ReflectionCardSlot").add_child(reflection_button)
		reflection_button.connect("mouse_entered", func(): _hovering_over_reflection_button(reflection_button))
		reflection_button.connect("mouse_exited", func(): _stop_hovering_over_reflection_button(reflection_button))
		
		active_card.queue_free()
		active_card = null
		reflection_card_filled = true
		initiate_gameboard()
		return
	
	if len(active_card.get_child(0).text) == 0:
		print("Please type something on the card!")
		return
	
	# Play card on the field
	var field_position = gameboard_fields.find(selected_field)
	var color_name = colors[active_card.get_theme_stylebox("panel").bg_color]
	if color_name == "grey":
		var new_field_card = create_small_card(color_name, "Icon", bonus_card_icons[bonus_cards.keys()[len(bonus_cards)-1]], bonus_cards.values()[len(bonus_cards)-1].get_child(0).placeholder_text)
		var new_preview_card = create_preview_card(color_name, bonus_cards.values()[len(bonus_cards)-1].get_child(0).placeholder_text)
		gameboard_fields[field_position].add_child(new_field_card)
		field_to_preview_cards[new_field_card] = new_preview_card
	else:
		create_field_card(field_position, color_name, card_icons[color_name], active_card.get_child(0).text)
	gameboard_fields[field_position].move_child(gameboard_fields[field_position].get_child(2), 1)
	
	# Remove hand and edit cards
	if color_name == "grey":
		bonus_cards.erase(bonus_cards.keys()[len(bonus_cards)-1])
		player_deck.get_child(len(player_deck.get_children())-2).queue_free()
	else:
		var active_hand_card = edit_to_hand_cards[active_card]
		edit_to_hand_cards.erase(active_card)
		active_hand_card.queue_free()
	active_card.queue_free()
	active_card = null
	play_card_button.visible = false
	player_played_card.emit()

func _hovering_over_reflection_button(button):
	if button.get_parent().get_child(0).get_class() == "Panel":
		field_cards_preview.get_child(0).visible = true

func _stop_hovering_over_reflection_button(button):
	if button.get_parent().get_child(0).get_class() == "Panel":
		field_cards_preview.get_child(0).visible = false

############################################ CARD CREATION METHODS #########################################################

func create_hand_card(color, icon_path):
	var new_hand_card = create_small_card(color, "Text", icon_path, card_types[color])
	var new_edit_card = create_edit_card(color)
	var new_button = Button.new()
	new_button.custom_minimum_size = Vector2(35, 35)
	new_button.flat = true
	new_hand_card.add_child(new_button)
	new_button.connect("pressed", func(): _click_hand_card(new_edit_card))
	player_hand_cards.add_child(new_hand_card)
	edit_to_hand_cards[new_edit_card] = new_hand_card

func create_field_card(field_position, color, icon_path, text):
	var new_field_card = create_small_card(color, "Text", icon_path, text)
	var new_preview_card = create_preview_card(color, text)
	gameboard_fields[field_position].add_child(new_field_card)
	field_to_preview_cards[new_field_card] = new_preview_card
	return new_field_card

func create_edit_card(color):
	var new_edit_card = create_big_card(color, "Edit", card_types[color])
	player_edit_cards.add_child(new_edit_card)
	return new_edit_card

func create_preview_card(color, text):
	var new_preview_card = create_big_card(color, "Preview", text)
	field_cards_preview.add_child(new_preview_card)
	return new_preview_card

# color = "red" | "yellow" | "green" | "blue" | "grey" | "aquamarine"
# type = "Text" | "Icon"
# icon_path = Path zu Icon-Texture
# text = String an Text für das Label
func create_small_card(color, type, icon_path, text):
	
	# Card Panel
	var new_small_card = Panel.new()
	new_small_card.custom_minimum_size = Vector2(35, 35)
	new_small_card.add_theme_stylebox_override("panel", style_boxes[color])
	new_small_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER | Control.SIZE_EXPAND
	
	# Card Label
	var new_text_label = Label.new()
	new_text_label.custom_minimum_size = Vector2(600, 600)
	new_text_label.scale = Vector2(0.05, 0.05)
	new_text_label.offset_left = 2
	new_text_label.offset_top = 2
	new_text_label.offset_right = 2
	new_text_label.offset_bottom = 2
	new_text_label.text = text
	new_text_label.add_theme_color_override("background_color", style_boxes[color].bg_color)
	new_text_label.add_theme_color_override("font_color", Color.BLACK)
	new_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	new_text_label.add_theme_font_size_override("font_size", 50)
	new_text_label.clip_text = true
	new_small_card.add_child(new_text_label)
	
	# Card Icon
	var new_icon = TextureRect.new()
	new_icon.texture = load(icon_path)
	new_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	new_icon.set_anchor(SIDE_TOP, 0.0)
	new_icon.set_anchor(SIDE_BOTTOM, 1.0)
	new_icon.set_anchor(SIDE_LEFT, 0.0)
	new_icon.set_anchor(SIDE_RIGHT, 1.0)
	new_icon.offset_top = 5.0
	new_icon.offset_bottom = -5.0
	new_icon.offset_left = 5.0
	new_icon.offset_right = -5.0
	new_small_card.add_child(new_icon)
	
	# Only show Label or Icon, not both
	if type == "Text":
		new_icon.visible = false
	elif type == "Icon":
		new_text_label.visible = false
	else:
		printerr("Invalid Card Type. Only Label or Icon accepted.")
	
	return new_small_card

# color = "red" | "yellow" | "green" | "blue" | "grey" | "aquamarine"
# type = "Edit" | "Preview"
# text = String an Text
func create_big_card(color, type, text):
	
	# Card Panel
	var new_big_card = Panel.new()
	new_big_card.custom_minimum_size = Vector2(100, 100)
	new_big_card.add_theme_stylebox_override("panel", style_boxes[color])
	
	# Card TextEdit
	var new_text_edit = TextEdit.new()
	new_text_edit.custom_minimum_size = Vector2(1900, 1900)
	new_text_edit.scale = Vector2(0.05, 0.05)
	new_text_edit.offset_left = 2
	new_text_edit.offset_top = 2
	new_text_edit.offset_right = 2
	new_text_edit.offset_bottom = 2
	new_text_edit.placeholder_text = text
	new_text_edit.add_theme_color_override("background_color", style_boxes[color].bg_color)
	new_text_edit.add_theme_color_override("font_color", Color.BLACK)
	new_text_edit.add_theme_color_override("font_placeholder_color", Color.BLACK)
	new_text_edit.add_theme_font_size_override("font_size", 100)
	new_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	new_big_card.add_child(new_text_edit)
	new_big_card.visible = false
	
	# Only allow to edit on Edit Cards
	if type == "Edit": # Edit Card
		new_text_edit.editable = true
	elif type == "Preview": # Preview Card
		new_text_edit.editable = false
	else:
		printerr("Invalid Card Type. Only Edit or Preview accepted.")
	
	return new_big_card

############################################################################################################################
