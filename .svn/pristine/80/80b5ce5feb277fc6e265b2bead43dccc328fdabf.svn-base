class_name HeartbeatMonitor
extends Node

##心跳监控器（HeartbeatMonitor）提供稳定的TCP长连接与心跳机制：自动连接、注册、状态同步、断线重连。
##
##[b][color=#00d1ff]用法[/color][/b][br]
##1. 添加节点（建议[color=#ffd166]Autoload[/color]或主场景）[br]
##2. 配置 [color=#ffd166]host / port / device_id[/color][br]
##3. 调用 [color=#06d6a0]set_state()[/color] 同步状态[br]
##4. 监听信号：[color=#06d6a0]connected / disconnected / state_changed[/color][br]
##
##[b][color=#00d1ff]通信协议[/color][/b][br]
##注册：[color=#ef476f]ID:&lt;id&gt;:Md5[/color][br]
##心跳：[color=#ef476f]State:&lt;id&gt;:&lt;state&gt;[/color][br]
##
##[b][color=#00d1ff]特性[/color][/b][br]
##• 自动重连（[color=#ffd166]reconnect_delay[/color]）[br]
##• 心跳控制（[color=#ffd166]heartbeat_interval[/color]）[br]
##• 防重复重连 / 注册保护[br]
##• 注册成功后才发送心跳

# 定义信号
signal connected ## 当成功连接到服务器时触发
signal disconnected ## 当与服务器断开连接时触发
signal state_changed(new_state: int) ## 当设备状态发生变化时触发，并传出新状态

# 外部修改属性
@export var host: String = "124.222.32.81" ## 服务器主机IP
@export var port: int = 8080 ## 服务器主机端口
@export var device_id: int = 1 ## 设备ID
@export var heartbeat_interval: float = 2.0 ## 心跳间隔
@export var reconnect_delay: float = 3.0 ## 断线后等多久尝试重连

# TCP客户端
var client := StreamPeerTCP.new() # TCP客户端实例（负责与服务器通信）
var _connected := false # 当前连接状态标记（是否已成功连接）
var current_state: int = 0 # 当前设备状态（可用于同步到服务器）
var _heartbeat_timer: Timer # 心跳定时器（定时发送心跳包）
var _reconnect_timer: Timer # 重连定时器（断线后延迟重连）
var _is_reconnecting := false # 是否正在重连（防止重复触发重连逻辑）

func _ready():
	_setup_timers()
	_connect_to_server()

# ─── 连接 ─────────────────────────────────────────────────────
func _connect_to_server():
	_is_reconnecting = false
	print("[HB] 连接服务器 %s:%d" % [host, port])
	client = StreamPeerTCP.new()   # 每次新建，避免旧状态残留
	var err = client.connect_to_host(host, port)
	if err != OK:
		push_error("[HB] connect_to_host 失败: %s" % err)
		_schedule_reconnect()

# ─── 每帧轮询 ─────────────────────────────────────────────────
func _process(_delta):
	client.poll()
	_check_connection_state()
	_read_incoming()

func _check_connection_state():
	var status = client.get_status()
	match status:
		StreamPeerTCP.STATUS_CONNECTED:
			if not _connected:
				_connected = true
				_is_reconnecting = false
				print("[HB] 连接成功！发送注册")
				connected.emit()
				_send_register()

		StreamPeerTCP.STATUS_CONNECTING:
			pass  # 正在握手，等待

		# 断线时停掉心跳，避免重连期间乱发
		StreamPeerTCP.STATUS_ERROR, StreamPeerTCP.STATUS_NONE:
			if _connected:
				_connected = false
				print("[HB] 连接断开！")
				_heartbeat_timer.stop()   # ← 加这行
				disconnected.emit()
				client.disconnect_from_host()
			_schedule_reconnect()

# ─── 接收服务器消息 ───────────────────────────────────────────
func _read_incoming():
	if not _connected:
		return
	if client.get_available_bytes() <= 0:
		return

	# 读取原始字节
	var msg_bytes: PackedByteArray = client.get_data(client.get_available_bytes())[1]
	var msg_str = msg_bytes.get_string_from_utf8()

	# 打印原始服务器返回
	print("[服务器原始] %s" % msg_str)

	# 原来的处理逻辑
	var msg = msg_str.strip_edges()
	if msg == "":
		return

	print("[HB] 收到: %s" % msg)
	
	if msg.contains("未注册ID:"):
		# 收到未注册提示，停心跳，重新注册
		print("[HB] 检测到未注册，重新发送注册包...")
		_heartbeat_timer.stop()
		_send_register()
	elif msg.contains("注册成功") or msg.contains("ID:%d:" % device_id):
		print("[HB] 注册确认，启动心跳") # 收到注册成功确认，再启用心跳
		_heartbeat_timer.stop()   # 防止重复start
		_heartbeat_timer.start()
	elif msg.begins_with("Success"):
		set_state(1)

# ─── 心跳 ─────────────────────────────────────────────────────
func _on_heartbeat_timer():
	if not _connected:
		return
	_send_state_packet()

# ─── 业务状态切换 ─────────────────────────────────────────────
func set_state(state: int):
	if current_state == state:
		return
	current_state = state
	print("[HB] 状态切换 → %d" % state)
	state_changed.emit(state)
	if _connected:
		_send_state_packet()

# ─── 发送：心跳/状态包 ───────────────────────────────────────
func _send_state_packet():
	var msg = "State:%d:%d" % [device_id, current_state]
	client.put_data(msg.to_utf8_buffer())
	print("[HB] 发送: %s" % msg)

# ─── 发送：注册包（每次连接成功后必须第一个发）───────────────
func _send_register():
	var msg = "ID:%d:Md5" % device_id
	client.put_data(msg.to_utf8_buffer())
	print("[HB] 注册: %s" % msg)
	
	# 注册包发出后再启动心跳，给服务器处理注册的时间
	await get_tree().create_timer(0.5).timeout
	_heartbeat_timer.start()

# ─── 重连调度 ─────────────────────────────────────────────────
func _schedule_reconnect():
	if _is_reconnecting:
		return # 已经在等待重连，不重复
	_is_reconnecting = true
	print("[HB] %s 秒后重连..." % reconnect_delay)
	_reconnect_timer.start()

func _on_reconnect_timer():
	_is_reconnecting = false # ← 加这行，让下一帧_check能重新调度
	_connect_to_server()

# ─── 定时器初始化 ─────────────────────────────────────────────
func _setup_timers():
	_heartbeat_timer = Timer.new()
	_heartbeat_timer.wait_time = heartbeat_interval
	_heartbeat_timer.autostart = false   # ← 改为 false，注册成功后再启动心跳
	_heartbeat_timer.timeout.connect(_on_heartbeat_timer)
	add_child(_heartbeat_timer)

	_reconnect_timer = Timer.new()
	_reconnect_timer.wait_time = reconnect_delay
	_reconnect_timer.one_shot = true
	_reconnect_timer.timeout.connect(_on_reconnect_timer)
	add_child(_reconnect_timer)
