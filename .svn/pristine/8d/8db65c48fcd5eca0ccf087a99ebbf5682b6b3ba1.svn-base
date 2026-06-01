class_name UDPReceiver
extends Node

# =========================
# 信号
# =========================
## 收到原始字节时触发
signal packet_received(data: PackedByteArray)
## 收到的数据能解析为 UTF-8 字符串时额外触发
signal string_received(text: String)

# =========================
# 配置
# =========================
@export var config_manager: Node
@export var listen_port: int = 6000
@export var auto_start: bool = true

var udp := PacketPeerUDP.new()
var _is_listening: bool = false

# =========================
# init
# =========================
func _ready():
	if config_manager:
		if config_manager.get("is_loaded"):
			_load_from_config()
		elif config_manager.has_signal("config_loaded"):
			config_manager.config_loaded.connect(_on_config_loaded)
	
	if auto_start:
		start_listening()

func _on_config_loaded():
	_load_from_config()

func _load_from_config():
	print("=== RECEIVER LOAD CONFIG ===")
	listen_port = int(config_manager.get_config("UDPReceiver", "listen_port", listen_port))
	print("LISTEN PORT:", listen_port)
	# 如果已在监听，重启以应用新端口
	if _is_listening:
		stop_listening()
		start_listening()

# =========================
# 开始 / 停止监听
# =========================
func start_listening() -> bool:
	if _is_listening:
		push_warning("UDPReceiver: 已在监听中，请先 stop_listening()")
		return false
	var err = udp.bind(listen_port)
	if err != OK:
		push_error("UDPReceiver: 绑定端口 %d 失败，错误码 %d" % [listen_port, err])
		return false
	_is_listening = true
	print("UDPReceiver: 开始监听端口", listen_port)
	return true

func stop_listening():
	if _is_listening:
		udp.close()
		_is_listening = false
		print("UDPReceiver: 停止监听")

# =========================
# 每帧轮询接收
# =========================
func _process(_delta):
	if not _is_listening:
		return
	while udp.get_available_packet_count() > 0:
		var data: PackedByteArray = udp.get_packet()
		var sender_ip = udp.get_packet_ip()
		var sender_port = udp.get_packet_port()
		print("UDPReceiver ← [%s:%d] bytes=%d" % [sender_ip, sender_port, data.size()])
		emit_signal("packet_received", data)
		# 尝试 UTF-8 解码
		var text = data.get_string_from_utf8()
		if text != "":
			emit_signal("string_received", text)

# =========================
# 工具：手动解析收到的 HEX
# =========================
func bytes_to_hex_string(data: PackedByteArray) -> String:
	var parts: Array[String] = []
	for b in data:
		parts.append("%02X" % b)
	return " ".join(parts)
