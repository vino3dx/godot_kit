class_name WindowController
extends Node

## 窗口控制器：多显示器切换、窗口定位、居中、边界夹紧，以及 无边框/窗口化/全屏/ 独占全屏四种模式的运行时切换。
##
## 用法：
##   1. 将 WindowController 节点拖入场景树（推荐挂在 Autoload 或主场景根节点）。[br]
##   2. 如需读取 .ini 配置，将 ConfigLoader 节点赋给 config_loader。[br]
##   3. 运行时调用 apply_window_mode() / move_to_screen() 等公开方法即可。[br]
##
## config.ini [Window] 支持的键：[br]
##   screen, pos_x, pos_y, center, clamp_to_screen[br]
##   window_mode = windowed | borderless | fullscreen | exclusive_fullscreen[br]
##   override_size = true | false[br]
##   override_width, override_height[br]

# 窗口模式
enum WindowMode {
	WINDOWED,            ## 普通窗口
	BORDERLESS,          ## 无边框窗口
	FULLSCREEN,          ## 全屏（桌面全屏，保留任务栏层级）
	EXCLUSIVE_FULLSCREEN ## 独占全屏（独占 GPU 输出，适合游戏）
}

@export var config_loader: Node ## ConfigLoader 需暴露 is_loaded: bool、config_loaded 信号以及 get_config(section, key) 方法。
@export var window_mode: WindowMode = WindowMode.WINDOWED ## 启动时的窗口模式。

# 窗口位置覆盖
@export var screen: int = 0 ## 目标显示器索引（0 为主显示器）。
@export var pos_x: int = 0 ## 窗口左上角相对于目标显示器的 X 偏移（像素），仅在非居中模式下生效。
@export var pos_y: int = 0 ## 窗口左上角相对于目标显示器的 Y 偏移（像素），仅在非居中模式下生效。
@export var center: bool = true ## 若为 true，窗口将在目标显示器上居中，忽略 pos_x / pos_y。
@export var clamp_to_screen: bool = true ## 若为 true，自动将窗口夹紧在目标显示器可视区域内，防止越界。

# 窗口尺寸覆盖
@export var override_size: bool = false ## 勾选后启用自定义窗口尺寸覆盖
@export var override_width: int = 1280 ## 覆盖宽度（像素）。仅在 override_size = true 时生效。
@export var override_height: int = 720 ## 覆盖高度（像素）。仅在 override_size = true 时生效。

func _ready() -> void:
	if config_loader:
		if config_loader.is_loaded:
			_apply_from_config()
		else:
			config_loader.config_loaded.connect(_on_config_loaded)
	else:
		_apply_window_position()

func _on_config_loaded() -> void:
	_apply_from_config()

# =========================
# 公开 API
# =========================

## 切换窗口模式，可在运行时随时调用。
func apply_window_mode(mode: WindowMode = window_mode) -> void:
	window_mode = mode
	match mode:
		WindowMode.WINDOWED:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		WindowMode.BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		WindowMode.FULLSCREEN:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		WindowMode.EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

## 将窗口移动到指定显示器并重新定位，可在运行时随时调用。
func move_to_screen(target_screen: int) -> void:
	screen = target_screen
	await _apply_window_position()

## 将窗口在当前显示器上居中。
func center_on_screen() -> void:
	center = true
	await _apply_window_position()

## 运行时动态设置窗口尺寸（同时启用 override_size）。
func set_window_size(width: int, height: int) -> void:
	override_size   = true
	override_width  = width
	override_height = height
	await _apply_window_position()

# =========================
# 从 Config 注入
# =========================

func _apply_from_config() -> void:
	var win_cfg := _get_section_dict("Window")

	screen          = int(win_cfg.get("screen",          screen))
	pos_x           = int(win_cfg.get("pos_x",           pos_x))
	pos_y           = int(win_cfg.get("pos_y",           pos_y))
	center          = _parse_bool(win_cfg.get("center",          center))
	clamp_to_screen = _parse_bool(win_cfg.get("clamp_to_screen", clamp_to_screen))
	override_size   = _parse_bool(win_cfg.get("override_size",   override_size))
	override_width  = int(win_cfg.get("override_width",  override_width))
	override_height = int(win_cfg.get("override_height", override_height))

	var mode_str: String = str(win_cfg.get("window_mode", "")).strip_edges().to_lower()
	match mode_str:
		"borderless":            window_mode = WindowMode.BORDERLESS
		"fullscreen":            window_mode = WindowMode.FULLSCREEN
		"exclusive_fullscreen":  window_mode = WindowMode.EXCLUSIVE_FULLSCREEN
		_:                       window_mode = WindowMode.WINDOWED

	_apply_window_position()

# =========================
# 核心：设置窗口模式 + 尺寸 + 位置
# =========================
func _apply_window_position() -> void:
	await get_tree().process_frame

	var screen_count := DisplayServer.get_screen_count()
	if screen < 0 or screen >= screen_count:
		screen = 0

	# ── FULLSCREEN 直接返回（关键修复） ──
	if window_mode in [WindowMode.FULLSCREEN, WindowMode.EXCLUSIVE_FULLSCREEN]:
		apply_window_mode(window_mode)
		return

	apply_window_mode(window_mode)

	await get_tree().process_frame
	await get_tree().process_frame

	if override_size:
		DisplayServer.window_set_size(Vector2i(override_width, override_height))
		await get_tree().process_frame
		await get_tree().process_frame

	var screen_pos  := DisplayServer.screen_get_position(screen)
	var screen_size := DisplayServer.screen_get_size(screen)
	var window_size := DisplayServer.window_get_size()

	var final_pos := screen_pos

	if center:
		final_pos += Vector2i((screen_size - window_size) / 2.0)
	else:
		final_pos += Vector2i(pos_x, pos_y)

	# clamp 修复
	if clamp_to_screen:
		var min_pos := screen_pos
		var max_pos := screen_pos + screen_size - window_size

		if window_size.x > screen_size.x:
			max_pos.x = min_pos.x
		if window_size.y > screen_size.y:
			max_pos.y = min_pos.y

		final_pos.x = clamp(final_pos.x, min_pos.x, max_pos.x)
		final_pos.y = clamp(final_pos.y, min_pos.y, max_pos.y)

	DisplayServer.window_set_position(final_pos)

# =========================
# 工具函数
# =========================

## 安全解析布尔值：兼容 bool 类型与 "true"/"false" 字符串。
func _parse_bool(value: Variant) -> bool:
	if value is bool:
		return value
	return str(value).strip_edges().to_lower() == "true"

## 读取 ConfigLoader 中指定 section 为字典。
func _get_section_dict(section: String) -> Dictionary:
	var result := {}
	if not config_loader:
		return result
	if not config_loader.config.has_section(section):
		return result
	for key in config_loader.config.get_section_keys(section):
		result[key] = config_loader.get_config(section, key)
	return result
