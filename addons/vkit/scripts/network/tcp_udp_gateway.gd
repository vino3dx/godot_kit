class_name TcpUdpGateway
extends Node
## TcpUdpGateway 是一个用于在 TCP 服务器与局域网 UDP 设备之间进行双向数据桥接的协议网关节点。
##
## [b]功能特性：[/b][br]
## • 双向转发：支持 TCP (云端) 到 UDP (硬件)，以及 UDP 到 TCP 的无缝流转[br]
## • 原始透传：默认支持底层字节流直接转发，完全保留原始数据[br]
## • 指令映射 (可选)：内置字典替换机制，支持截获并动态翻译报文：[br]
## 　　收到 TCP : "4F50454E" (OPEN) -> 转发 UDP : "55 01 12 00 00 00 01 69"[br]
## 　　收到 UDP : "AA 01 00" -> 回传 TCP : "53554343455353" (SUCCESS)[br]
## • 脏数据过滤：自动校验 UDP 包的发送方 IP，屏蔽局域网内的未知干扰[br]
## • 状态监听：提供 tcp_connected / tcp_disconnected 信号，便于外部掌控网络状态[br][br]
##
## [b]适用场景：[/b][br]
## 适用于需要将云端服务器（长连接）通讯代理到本地硬件设备（如继电器、传感器等短连接设备）的边缘网关程序或中间件。

signal tcp_connected()
signal tcp_disconnected()

# ==========================================
# 面板配置 (Inspector)
# ==========================================
@export_group("TCP Settings")
@export var tcp_server_ip: String = "127.0.0.1"
@export var tcp_server_port: int = 8080

@export_group("UDP Settings")
@export var udp_listen_port: int = 9001
@export var udp_target_ip: String = "192.168.101.110"
@export var udp_target_port: int = 6000

@export_group("Gateway Logic")
@export var use_mapping: bool = true ## 是否启用键值对映射转换。如果不勾选，则转发原始字节流。

## TCP指令(Key) 到 UDP指令(Value) 的转换表
## 格式示例： Key(String) : Value(String/Hex字符串)
## 注意：代码中会将收到的字节转为16进制大写字符串进行匹配
@export var tcp_to_udp_map: Dictionary = {
	"4F50454E": "55 01 12 00 00 00 01 69", # 比如：TCP收到 "OPEN" 对应的Hex，转为UDP的继电器指令
	"434C4F5345": "55 01 12 00 00 00 00 68" # 比如：CLOSE -> 关
}

## UDP回码(Key) 到 TCP回传(Value) 的转换表
@export var udp_to_tcp_map: Dictionary = {
	"AA 01 00": "53554343455353" # 比如：继电器成功回码 -> TCP返回 "SUCCESS"
}

# ==========================================
# 内部变量
# ==========================================
var tcp := StreamPeerTCP.new()
var udp := PacketPeerUDP.new()
var _was_tcp_connected := false

func _ready() -> void:
	_bind_udp(udp_listen_port)
	tcp.connect_to_host(tcp_server_ip, tcp_server_port)

func _process(_delta: float) -> void:
	_process_tcp_inbound()
	_process_udp_inbound()

# ------------------------------------------
# 处理 TCP -> UDP (服务器 -> 硬件)
# ------------------------------------------
func _process_tcp_inbound() -> void:
	tcp.poll()
	var status = tcp.get_status()
	
	# 连接状态切换监控
	if status == StreamPeerTCP.STATUS_CONNECTED and not _was_tcp_connected:
		_was_tcp_connected = true
		tcp_connected.emit()
	elif status != StreamPeerTCP.STATUS_CONNECTED and _was_tcp_connected:
		_was_tcp_connected = false
		tcp_disconnected.emit()

	if status == StreamPeerTCP.STATUS_CONNECTED and tcp.get_available_bytes() > 0:
		var raw_data = tcp.get_partial_data(tcp.get_available_bytes())[1]
		
		if use_mapping:
			# 将原始字节转为大写Hex字符串用于匹配
			var hex_key = raw_data.hex_encode().to_upper()
			if tcp_to_udp_map.has(hex_key):
				var mapped_hex = tcp_to_udp_map[hex_key].replace(" ", "")
				print("[Gateway] TCP->UDP 匹配转换: ", hex_key, " => ", mapped_hex)
				_send_udp(mapped_hex.hex_decode())
			else:
				print("[Gateway] TCP->UDP 未匹配，丢弃或原始发送 (此处设为丢弃)")
		else:
			print("[Gateway] TCP->UDP 原始透传")
			_send_udp(raw_data)

# ------------------------------------------
# 处理 UDP -> TCP (硬件 -> 服务器)
# ------------------------------------------
func _process_udp_inbound() -> void:
	while udp.get_available_packet_count() > 0:
		var raw_data = udp.get_packet()
		if udp.get_packet_ip() != udp_target_ip: continue
		
		if use_mapping:
			var hex_key = raw_data.hex_encode().to_upper()
			# 注意：由于UDP可能带空格，匹配前最好清理字典里的空格
			if _find_and_send_mapped_tcp(hex_key):
				pass 
			else:
				print("[Gateway] UDP->TCP 未匹配")
		else:
			print("[Gateway] UDP->TCP 原始透传")
			_send_tcp(raw_data)

# ==========================================
# 工具函数
# ==========================================
func _find_and_send_mapped_tcp(hex_key: String) -> bool:
	# 遍历字典寻找匹配项（处理字典值中可能存在的空格）
	for k in udp_to_tcp_map.keys():
		var clean_k = k.replace(" ", "").to_upper()
		if clean_k == hex_key:
			var target_hex = udp_to_tcp_map[k].replace(" ", "")
			_send_tcp(target_hex.hex_decode())
			print("[Gateway] UDP->TCP 匹配转换: ", hex_key, " => ", target_hex)
			return true
	return false

func _bind_udp(port: int):
	udp.bind(port)

func _send_udp(data: PackedByteArray):
	udp.set_dest_address(udp_target_ip, udp_target_port)
	udp.put_packet(data)

func _send_tcp(data: PackedByteArray):
	if tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		tcp.put_data(data)
