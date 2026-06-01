extends Node
# [b]ConfigLoader[/b] —— Autoload 全局配置加载器
#
# 启动时自动读取 data/config.ini，供其他 Autoload 和场景脚本查询。
#
# 【查询接口】
#   ConfigLoader.get_value("AssetLoader", "base_path", "")
#   ConfigLoader.get_value("MyScene", "title", "默认标题")

signal config_loaded

@export_file("*.ini") var config_file_path: String = "data/config.ini"
@export var debug_print: bool = true

var _config := ConfigFile.new()
var is_loaded: bool = false

# ==============================
# 初始化
# ==============================
func _ready() -> void:
	_load()

func _load() -> void:
	# 重置，防止热重载时数据叠加
	_config = ConfigFile.new()
	is_loaded = false

	var path: String
	if OS.has_feature("editor"):
		path = "res://data/config.ini"
	else:
		path = OS.get_executable_path().get_base_dir() + "/data/config.ini"

	if not FileAccess.file_exists(path):
		push_error("[ConfigLoader] 未找到配置文件: " + path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[ConfigLoader] 无法打开配置文件: " + path)
		return

	var raw := file.get_as_text().replace("\\", "/")
	file.close()

	# 逐行自动补引号
	var lines := raw.split("\n")
	var fixed: PackedStringArray = []
	for line in lines:
		fixed.append(_fix_line(line))
	raw = "\n".join(fixed)

	if _config.parse(raw) != OK:
		push_error("[ConfigLoader] 解析失败，请检查 config.ini 格式（需 UTF-8）")
		return

	is_loaded = true
	_log("✅ 加载成功，小节: " + str(_config.get_sections()))
	config_loaded.emit()

# ==============================
# 对外查询接口
# ==============================
## 获取配置值，找不到时返回 default_value
func get_value(section: String, key: String, default_value: Variant = null) -> Variant:
	if not is_loaded:
		return default_value
	return _config.get_value(section, key, default_value)

## 判断某小节是否存在
func has_section(section: String) -> bool:
	return is_loaded and _config.has_section(section)

## 获取某小节所有键（供遍历用）
func get_section_keys(section: String) -> Array:
	if not is_loaded or not _config.has_section(section):
		return []
	return _config.get_section_keys(section)

# ==============================
# 内部工具
# ==============================
func _fix_line(line: String) -> String:
	var stripped := line.strip_edges()
	if stripped.begins_with(";") or stripped.begins_with("#") \
	or stripped.begins_with("[") or stripped == "":
		return line
	var eq_pos := line.find("=")
	if eq_pos == -1:
		return line
	var key := line.substr(0, eq_pos).strip_edges()
	var val := line.substr(eq_pos + 1).strip_edges()
	if val.begins_with('"') or val.begins_with("'"):
		return line
	if val == "true" or val == "false":
		return line
	if val.is_valid_float() or val.is_valid_int():
		return line
	if val == "":
		return key + ' = ""'
	return key + ' = "' + val + '"'

func _log(msg: String) -> void:
	if debug_print:
		print("[ConfigLoader] ", msg)
