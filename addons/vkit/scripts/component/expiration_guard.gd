class_name ExpirationGuard
extends Node
## 软件授权到期检查守护脚本。
##
## 该单例负责在程序启动时验证授权日期。支持静默退出或弹窗提示后退出。[br]
## 建议将其作为 Autoload (单例) 使用，并放在加载顺序的首位。

# --- 导出配置 ---
@export_group("授权设置")
@export var expiration_date: String = "2025-01-01" ## 授权过期日期 (格式：YYYY-MM-DD)
@export var use_dialog: bool = true ## 是否开启到期弹窗提示

@export_group("弹窗样式")
@export var dialog_title: String = "⚠ 软件授权到期"  ## 弹窗标题
@export_multiline var dialog_text: String = "软件授权已到期！\n\n请联系服务方获取授权续期。" ## 弹窗正文内容
@export var ok_button_text: String = "  确定  " ## 确定按钮的文本
@export_range(0.1, 0.9) var screen_ratio: float = 0.5 ## 弹窗占屏幕的比例 (0.0 - 1.0)

# --- 内部变量 ---
var _dialog: AcceptDialog

func _ready() -> void:
	if _is_expired():
		_handle_expiration()

## 核心逻辑：判断是否过期
func _is_expired() -> bool:
	var date_dict := Time.get_date_dict_from_system()
	var current_date := "%04d-%02d-%02d" % [
		date_dict["year"],
		date_dict["month"],
		date_dict["day"]
	]
	return current_date > expiration_date

## 处理过期后的行为
func _handle_expiration() -> void:
	push_error("[ExpirationGuard] 授权已过期。当前日期对比阈值：%s" % expiration_date)
	
	if use_dialog:
		_show_expiry_dialog()
	else:
		# 如果不使用对话框，延迟一帧直接退出
		get_tree().quit()

## 创建并显示对话框
func _show_expiry_dialog() -> void:
	_dialog = AcceptDialog.new()
	_dialog.title = dialog_title
	_dialog.dialog_text = dialog_text
	_dialog.ok_button_text = ok_button_text
	
	# 设置模态（必须先点击对话框）
	_dialog.exclusive = true
	
	# 字体大小适配（可选，根据项目需求调整）
	_dialog.add_theme_font_size_override("title_font_size", 24)
	_dialog.add_theme_font_size_override("font_size", 20)
	
	# 连接信号
	_dialog.confirmed.connect(_on_exit_requested)
	_dialog.close_requested.connect(_on_exit_requested)
	
	add_child(_dialog)
	
	# 居中弹出
	_dialog.popup_centered_ratio(screen_ratio)

## 退出程序的回调
func _on_exit_requested() -> void:
	print("[ExpirationGuard] 用户确认，程序退出。")
	get_tree().quit()
