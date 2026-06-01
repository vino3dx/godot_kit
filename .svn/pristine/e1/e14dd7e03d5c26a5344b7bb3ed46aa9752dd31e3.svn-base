class_name DataLoader
extends Node
## [b]DataLoader - 通用数据读取管理器[/b]
##
## [b]功能简介：[/b][br]
## • 支持多种数据格式读取：TEXT / JSON / CSV / INI[br]
## • 自动适配开发环境（res://）与打包后环境（外部文件）[br]
## • 优先读取 exe 同目录下的外部文件，实现热替换配置[br]
## • 提供统一数据出口 loaded_data，便于全局访问[br]
## • 支持自动加载与手动加载两种模式[br]
## • 内置错误检测与日志提示，方便调试[br][br]
##
## [b]路径策略：[/b][br]
## 1. 若为绝对路径 → 直接使用[br]
## 2. 若为 res:// 路径 → 优先查找 exe 同级目录下同名文件[br]
## 3. 若外部不存在 → fallback 使用内置资源[br][br]
##
## [b]推荐用法：[/b][br]
## • 开发阶段：使用 res://data/config.json[br]
## • 打包后：在 exe 同目录放置 data/config.json 覆盖配置[br][br]
##
## [b]适用场景：[/b][br]
## 配置系统 / 本地数据表 / 可热更新参数 / 设备配置读取等

## 数据格式枚举
enum DataFormat {
	TEXT,
	JSON,
	CSV,
	INI
}

@export_group("基础设置")
@export var data_format: DataFormat = DataFormat.TEXT:
	set(val):
		data_format = val
		update_configuration_warnings()

@export_file("*.txt", "*.json", "*.csv", "*.ini") var file_path: String = ""

@export_group("高级设置")
@export var csv_delimiter: String = ","
@export var auto_load_on_ready: bool = true

## 存储读取后的数据
var loaded_data: Variant = null

# =========================
# 生命周期
# =========================
func _ready() -> void:
	if auto_load_on_ready and not Engine.is_editor_hint():
		load_data()

# =========================
# 对外接口
# =========================
func load_data() -> Variant:
	if file_path.is_empty():
		push_warning("[%s] 未指定读取路径" % name)
		return null
		
	var final_path := _get_real_path(file_path)

	if not FileAccess.file_exists(final_path):
		push_error("❌ [%s] 文件不存在: %s" % [name, final_path])
		return null

	match data_format:
		DataFormat.TEXT:
			loaded_data = _read_as_text(final_path)
		DataFormat.JSON:
			loaded_data = _read_as_json(final_path)
		DataFormat.CSV:
			loaded_data = _read_as_csv(final_path)
		DataFormat.INI:
			loaded_data = _read_as_ini(final_path)

	if loaded_data != null:
		print("✅ [%s] 数据加载成功: %s" % [name, final_path])
	else:
		push_error("❌ [%s] 数据加载失败: %s" % [name, final_path])

	return loaded_data

func reload() -> Variant:
	return load_data()

# =========================
# 读取实现
# =========================
func _read_as_text(path: String) -> String:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return ""
	return file.get_as_text()

func _read_as_json(path: String) -> Variant:
	var content = _read_as_text(path)
	if content.is_empty():
		push_error("JSON文件为空: %s" % path)
		return null
		
	var result = JSON.parse_string(content)
	if result == null:
		push_error("JSON解析失败: %s" % path)
	return result

func _read_as_csv(path: String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return []
	
	var result: Array = []
	var headers = file.get_csv_line(csv_delimiter)
	
	while not file.eof_reached():
		var line = file.get_csv_line(csv_delimiter)
		
		if line.size() < headers.size() or line[0].is_empty():
			continue
			
		var entry = {}
		for i in range(headers.size()):
			entry[headers[i]] = _auto_convert(line[i])
		
		result.append(entry)
	
	return result

func _read_as_ini(path: String) -> Dictionary:
	var config = ConfigFile.new()
	if config.load(path) != OK:
		push_error("INI读取失败: %s" % path)
		return {}
		
	var dict = {}
	for section in config.get_sections():
		dict[section] = {}
		for key in config.get_section_keys(section):
			dict[section][key] = config.get_value(section, key)
	return dict

# =========================
# 工具函数
# =========================

## 自动类型转换（CSV用）
func _auto_convert(value: String) -> Variant:
	if value.is_valid_int():
		return int(value)
	if value.is_valid_float():
		return float(value)
	return value

## 路径解析（核心）
func _get_real_path(path: String) -> String:
	# 绝对路径直接用
	if path.is_absolute_path():
		return path
	
	# 同目录优先
	var exe_dir = OS.get_executable_path().get_base_dir()
	var external_path = exe_dir.path_join(path.replace("res://", ""))
	
	if FileAccess.file_exists(external_path):
		return external_path
	
	# 内置资源
	return path

# =========================
# 编辑器提示
# =========================
func _get_configuration_warnings() -> PackedStringArray:
	if file_path.is_empty():
		return ["必须指定一个文件路径才能读取数据。"]
	return []
