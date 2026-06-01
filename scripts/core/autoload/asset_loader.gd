# [b]AssetLoader[/b] —— Autoload 全局资源加载器
#
# 依赖 ConfigLoader（需在 Autoload 列表中排在 AssetLoader 之前）。
#
# 【config.ini 配置】
#   [AssetLoader]
#   base_path = C:/Users/Administrator/App
#   image_dir = images
#   audio_dir = audio
#   video_dir = video
#
# 【加载图片】
#   $TextureRect.texture = AssetLoader.load_texture("logo.png")
#
# 【加载音频】
#   $AudioStreamPlayer.stream = AssetLoader.load_audio("bgm.mp3")
#
# 【加载视频（EIRTeam.FFmpeg）】
#   $VideoStreamPlayer.stream = AssetLoader.load_video_stream("intro.mp4")
extends Node

const SECTION := "AssetLoader"

var base_path: String = ""
var image_dir: String = "images"
var audio_dir: String = "audio"
var video_dir: String = "video"

var _texture_cache: Dictionary = {}

# ==============================
# 初始化
# ==============================
func _ready() -> void:
	# ConfigLoader 已在本节点之前执行完毕，直接取值
	base_path = ConfigLoader.get_value(SECTION, "base_path", base_path)
	image_dir = ConfigLoader.get_value(SECTION, "image_dir", image_dir)
	audio_dir = ConfigLoader.get_value(SECTION, "audio_dir", audio_dir)
	video_dir = ConfigLoader.get_value(SECTION, "video_dir", video_dir)

	print("[AssetLoader] base_path = ", base_path)
	print("[AssetLoader] image_dir = ", image_dir)
	print("[AssetLoader] audio_dir = ", audio_dir)
	print("[AssetLoader] video_dir = ", video_dir)

# ==============================
# 路径构建
# ==============================
func _build_path(sub_dir: String, file_name: String) -> String:
	var base := base_path.replace("\\", "/").strip_edges()
	if not base.ends_with("/"):
		base += "/"
	if sub_dir == "":
		return base + file_name
	# sub_dir 是绝对路径时直接用
	var sd := sub_dir.replace("\\", "/").strip_edges()
	if sd.begins_with("/") or (sd.length() > 1 and sd.substr(1, 1) == ":"):
		if not sd.ends_with("/"):
			sd += "/"
		return sd + file_name
	return base + sd + "/" + file_name

func get_image_path(file_name: String) -> String:
	return _build_path(image_dir, file_name)

func get_audio_path(file_name: String) -> String:
	return _build_path(audio_dir, file_name)

func get_video_path(file_name: String) -> String:
	return _build_path(video_dir, file_name)

# ==============================
# 图片加载（带缓存）
# ==============================
func load_texture(file_name: String) -> Texture2D:
	if _texture_cache.has(file_name):
		return _texture_cache[file_name]
	var path := get_image_path(file_name)
	if not FileAccess.file_exists(path):
		push_error("[AssetLoader] 图片不存在: " + path)
		return null
	var img := Image.new()
	if img.load(path) != OK:
		push_error("[AssetLoader] 图片加载失败: " + path)
		return null
	var tex := ImageTexture.create_from_image(img)
	_texture_cache[file_name] = tex
	return tex

func clear_cache() -> void:
	_texture_cache.clear()

# ==============================
# 音频加载
# ==============================
func load_audio(file_name: String) -> AudioStream:
	var path := get_audio_path(file_name)
	if not FileAccess.file_exists(path):
		push_error("[AssetLoader] 音频不存在: " + path)
		return null
	match file_name.get_extension().to_lower():
		"ogg": return AudioStreamOggVorbis.load_from_file(path)
		"wav": return AudioStreamWAV.load_from_file(path)
		"mp3": return AudioStreamMP3.load_from_file(path)
	push_error("[AssetLoader] 不支持的音频格式: " + file_name)
	return null

# ==============================
# 视频加载（EIRTeam.FFmpeg）
# ==============================
func load_video_stream(file_name: String) -> VideoStream:
	var path := get_video_path(file_name)
	if not FileAccess.file_exists(path):
		push_error("[AssetLoader] 视频不存在: " + path)
		return null
	var stream := FFmpegVideoStream.new()
	stream.file = path
	return stream
