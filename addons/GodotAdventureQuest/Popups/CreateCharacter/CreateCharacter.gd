tool
extends CreationPopup
# Permite crear un nuevo personaje con los archivos necesarios para que funcione
# en el Popochiu: CharacterCCC.tscn, CharacterCCC.gd, CharacterCCC.tres.

const CHARACTER_SCRIPT_TEMPLATE := 'res://script_templates/CharacterTemplate.gd'
const BASE_CHARACTER_PATH := 'res://src/Nodes/Character/Character.tscn'

var _new_character_name := ''
var _new_character_path := ''
var _character_path_template: String


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func set_main_dock(node: PopochiuDock) -> void:
	.set_main_dock(node)
	# Por defecto: res://src/Characters
	_character_path_template = _main_dock.characters_path + '%s/Character%s'


func create() -> void:
	if not _new_character_name:
		_error_feedback.show()
		return
	
	# TODO: Verificar si no hay ya un personaje en el mismo PATH.
	# TODO: Eliminar archivos creados si la creación no se completa.
	
	# Crear el directorio donde se guardará el nuevo personaje -----------------
	_main_dock.dir.make_dir(_main_dock.characters_path + _new_character_name)

	# Crear el script del nuevo personaje --------------------------------------
	var character_template := load(CHARACTER_SCRIPT_TEMPLATE)
	if ResourceSaver.save(_new_character_path + '.gd', character_template) != OK:
		push_error('No se pudo crear el script: %s.gd' % _new_character_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return

	# Crear la instancia del nuevo personaje y asignarle el script creado ------
	var new_character: Character = preload(BASE_CHARACTER_PATH).instance()
	#	Primero se asigna el script para que no se vayan a sobrescribir otras
	#	propiedades por culpa de esa asignación.
	new_character.set_script(load(_new_character_path + '.gd'))
	new_character.script_name = _new_character_name
	new_character.name = 'Character' + _new_character_name
	
	# Crear el archivo de la escena --------------------------------------------
	var new_character_packed_scene: PackedScene = PackedScene.new()
	new_character_packed_scene.pack(new_character)
	if ResourceSaver.save(_new_character_path + '.tscn',\
	new_character_packed_scene) != OK:
		push_error('No se pudo crear la escena: %s.tscn' % _new_character_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	
	# Crear el Resource del personaje ------------------------------------------
	var character_resource: GAQCharacter = GAQCharacter.new()
	character_resource.script_name = _new_character_name
	character_resource.scene = _new_character_path + '.tscn'
	character_resource.resource_name = _new_character_name
	if ResourceSaver.save(_new_character_path + '.tres',\
	character_resource) != OK:
		push_error('No se pudo crear el GAQCharacter del personaje: %s' %\
		_new_character_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return

	# Agregar el personaje al Godot Adventure Quest ----------------------------
	var gaq: Node = ResourceLoader.load(_main_dock.GAQ_PATH).instance()
	gaq.characters.append(ResourceLoader.load(_new_character_path + '.tres'))
	var new_gaq: PackedScene = PackedScene.new()
	new_gaq.pack(gaq)
	if ResourceSaver.save(_main_dock.GAQ_PATH, new_gaq) != OK:
		push_error('No se pudo agregar el personaje a GAQ: %s' %\
		_new_character_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	_main_dock.ei.reload_scene_from_path(_main_dock.GAQ_PATH)
	
	# Actualizar la lista de habitaciones en el Dock ---------------------------
	_main_dock.add_to_list('character', _new_character_name)

	# Abrir la escena creada en el editor --------------------------------------
	yield(get_tree().create_timer(0.1), 'timeout')
	_main_dock.ei.select_file(_new_character_path + '.tscn')
	_main_dock.ei.open_scene_from_path(_new_character_path + '.tscn')
	
	# Fin
	hide()

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _update_name(new_text: String) -> void:
	._update_name(new_text)

	if _name:
		_new_character_name = _name
		_new_character_path = _character_path_template %\
		[_new_character_name, _new_character_name]

		_info.bbcode_text = (
			'En [b]%s[/b] se crearán los archivos:\n[code]%s, %s y %s[/code]' \
			% [
				_main_dock.characters_path + _new_character_name,
				'Character' + _new_character_name + '.tscn',
				'Character' + _new_character_name + '.gd',
				'Character' + _new_character_name + '.tres'
			])
	else:
		_info.clear()


func _clear_fields() -> void:
	._clear_fields()
	
	_new_character_name = ''
	_new_character_path = ''
