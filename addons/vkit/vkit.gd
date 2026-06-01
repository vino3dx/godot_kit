@tool
extends EditorPlugin

const AUTOLOAD_PATH := "res://addons/vkit/scripts/autoload/"
var registered_singletons: Array[String] = []

func _enter_tree() -> void:
	_register_all_autoloads()
	print("【vkit】自动注册完成")

func _exit_tree() -> void:
	_unregister_all_autoloads()
	print("【vkit】已卸载")

# 遍历目录自动注册单例
func _register_all_autoloads() -> void:
	var dir := DirAccess.open(AUTOLOAD_PATH)
	if dir == null:
		push_error("VKit: 找不到目录 -> " + AUTOLOAD_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".gd") and not file_name.begins_with("."):
			var script_path = AUTOLOAD_PATH + file_name
			
			# 确保生成标准的全局大驼峰命名
			var camel_case = file_name.get_basename().to_camel_case()
			var singleton_name = camel_case.capitalize().replace(" ", "")

			# 【核心修复】如果项目设置里已经有这个单例了，说明用户可能手动关了它，保持现状，不再重复注册
			if not ProjectSettings.has_setting("autoload/" + singleton_name):
				add_autoload_singleton(singleton_name, script_path)
			
			if not registered_singletons.has(singleton_name):
				registered_singletons.append(singleton_name)

		file_name = dir.get_next()
	dir.list_dir_end()

# 反注册清理单例
func _unregister_all_autoloads() -> void:
	for singleton_name in registered_singletons:
		remove_autoload_singleton(singleton_name)
	registered_singletons.clear()
