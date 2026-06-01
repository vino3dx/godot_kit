extends Node

## === 离线授权许可管理 ===
## 功能：
##  - AES-256-CBC 解密 license.dat
##  - 校验授权到期时间
##  - 支持编辑器与导出环境
##  - 授权失效或日期异常自动退出
## 授权 JSON 示例：
## { "expire": "2027-12-30" }
## ====================================

var KEY: PackedByteArray
var IV: PackedByteArray

func _ready():
	KEY = "1234567890ABCDEF1234567890ABCDEF".to_utf8_buffer()
	IV  = "ABCDEF1234567890".to_utf8_buffer()
	
	# 启动时自动检查，过期或异常则静默退出
	if not check_license():
		await get_tree().process_frame
		get_tree().quit()


# =========================
# 获取 license 路径
# =========================
func get_license_path() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://") + "license.dat"
	return OS.get_executable_path().get_base_dir() + "/license.dat"


# =========================
# 读取文件
# =========================
func read_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var txt = f.get_as_text()
	f.close()
	return txt.strip_edges().replace("\n", "").replace("\r", "").replace(" ", "")


# =========================
# AES-256-CBC 解密
# =========================
func decrypt(base64_text: String) -> String:
	var encrypted: PackedByteArray = Marshalls.base64_to_raw(base64_text)
	if encrypted.size() == 0:
		return ""
	
	var aes := AESContext.new()
	aes.start(AESContext.MODE_CBC_DECRYPT, KEY, IV)
	var decrypted: PackedByteArray = aes.update(encrypted)
	aes.finish()
	
	if decrypted.size() == 0:
		return ""
	
	# 去除 PKCS7 padding
	var pad_len = decrypted[decrypted.size() - 1]
	if pad_len >= 1 and pad_len <= 16:
		for i in range(pad_len):
			if decrypted[decrypted.size() - 1 - i] != pad_len:
				return ""
		decrypted = decrypted.slice(0, decrypted.size() - pad_len)
	
	return decrypted.get_string_from_utf8()


# =========================
# JSON 解析
# =========================
func parse_json(text: String) -> Dictionary:
	var result = JSON.parse_string(text)
	if result == null or not result is Dictionary:
		return {}
	return result


# =========================
# 判断闰年
# =========================
func is_leap_year(year:int) -> bool:
	return (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)


# =========================
# 日期合法性检查
# =========================
func is_valid_date(date_str:String) -> bool:

	if date_str.length() != 10:
		return false

	var parts = date_str.split("-")

	if parts.size() != 3:
		return false

	var year = parts[0].to_int()
	var month = parts[1].to_int()
	var day = parts[2].to_int()

	if year < 2000 or year > 9999:
		return false

	if month < 1 or month > 12:
		return false

	var max_day = 31

	match month:
		4, 6, 9, 11:
			max_day = 30
		2:
			max_day = 28
			if is_leap_year(year):
				max_day = 29

	if day < 1 or day > max_day:
		return false

	return true


# =========================
# 日期比较（返回 1=未过期  -1=已过期  0=异常）
# =========================
func _check_expire(expire:String) -> int:

	if not is_valid_date(expire):
		return 0  # 日期非法

	var today = Time.get_date_string_from_system(true)  # 返回 YYYY-MM-DD

	if not is_valid_date(today):
		return 0  # 系统日期异常

	if today <= expire:
		return 1  # 未过期
	return -1    # 已过期


# =========================
# 主入口：检查授权
# =========================
func check_license() -> bool:
	var path = get_license_path()
	
	if not FileAccess.file_exists(path):
		print("[LSM] config missing")      # 找不到文件
		return false
	
	var raw = read_file(path)
	if raw == "":
		print("[LSM] config empty")        # 文件为空
		return false
	
	var decrypted = decrypt(raw)
	if decrypted == "":
		print("[LSM] config unreadable")   # 解密失败
		return false
	
	var data = parse_json(decrypted)
	if data.is_empty() or not data.has("expire"):
		print("[LSM] config invalid")      # JSON 异常
		return false
	
	var status = _check_expire(data["expire"])
	
	match status:
		1:
			print("[LSM] runtime ok")      # 授权有效
			return true
		-1:
			print("[LSM] runtime end")     # 授权过期
			return false
		_:
			print("[LSM] runtime err")     # 日期异常
			return false
