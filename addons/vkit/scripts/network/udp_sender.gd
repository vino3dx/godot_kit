class_name UDPSender
extends Node

@export var config_loader: Node
@export var target_ip: String = "192.168.1.110"
@export var target_port: int = 6000

var udp := PacketPeerUDP.new()
var hex_commands: Array[PackedByteArray] = []

func _ready():
	udp.bind(0)

	if config_loader:
		if config_loader.get("is_loaded"):
			_load_from_config()
		elif config_loader.has_signal("config_loaded"):
			config_loader.config_loaded.connect(_on_config_loaded)

func _on_config_loaded():
	_load_from_config()

func _load_from_config():
	print("=== LOAD CONFIG ===")
	target_ip = str(config_loader.get_config("UDPSender", "target_ip", target_ip))
	target_port = int(config_loader.get_config("UDPSender", "target_port", target_port))
	udp.set_dest_address(target_ip, target_port)
	print("TARGET:", target_ip, target_port)

	hex_commands.clear()
	var keys = config_loader.config.get_section_keys("UDPSender")
	keys.sort()
	for k in keys:
		if k.begins_with("cmd_hex"):
			var raw = config_loader.get_config("UDPSender", k, "")
			print("RAW:", k, "=", raw)
			var bytes = _parse_hex(raw)
			print("PARSED:", bytes)
			if bytes.size() > 0:
				hex_commands.append(bytes)
	print("TOTAL CMD:", hex_commands.size())

func _parse_hex(hex_str: String) -> PackedByteArray:
	var result := PackedByteArray()
	if hex_str == null or hex_str == "":
		return result
	hex_str = str(hex_str).strip_edges()
	var parts = hex_str.split(" ")
	for p in parts:
		p = p.strip_edges()
		if p == "":
			continue
		if not _is_hex(p):
			push_warning("非法HEX字符: " + p)
			continue
		result.append(p.hex_to_int())
	return result

func _is_hex(s: String) -> bool:
	if s.length() == 0 or s.length() > 2:
		return false
	for c in s:
		var code = c.unicode_at(0)
		if not (
			(code >= 48 and code <= 57) or
			(code >= 65 and code <= 70) or
			(code >= 97 and code <= 102)
		):
			return false
	return true

func set_target(ip: String, port: int):
	target_ip = ip
	target_port = port
	udp.set_dest_address(target_ip, target_port)

func send_bytes(bytes: PackedByteArray):
	if bytes.size() == 0:
		push_warning("UDPSender: 尝试发送空数据")
		return
	udp.put_packet(bytes)

func send_string(text: String):
	send_bytes(text.to_utf8_buffer())

func _on_trigger(_state = null):
	if hex_commands.size() == 0:
		push_warning("UDPSender: hex_commands 为空，请检查配置")
		return
	print("=== UDP TRIGGER ===")
	for bytes in hex_commands:
		print("SEND:", bytes)
		udp.put_packet(bytes)
