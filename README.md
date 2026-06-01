# Godot-Kit

**Godot-Kit** 是一个专为 Godot Engine 开发者设计的轻量级工具库与通用类集合。它旨在解决中大型项目中常见的底层需求，如外部资源管理、运行时授权验证及硬件通讯封装，帮助开发者从繁琐的样板代码中解脱出来。

## 🚀 核心特性

该项目采用 **高内聚、低耦合** 的设计原则，所有模块均可独立引用或扩展。

### 1. 外部资产管理 (External Asset Loading)
支持在游戏运行时动态加载非工程内的资源，适用于 DLC 机制或展示类项目：
*   **运行时纹理加载**：支持 `.png`, `.jpg` 等格式直接转为 `ImageTexture`。
*   **多媒体支持**：便捷加载外部视频、音频流。
*   **自动路径映射**：统一管理不同平台的外部文件路径。

### 2. 配置与持久化 (External Configuration)
提供比内置 `ConfigFile` 更健壮的外部配置方案：
*   **JSON/INI 兼容**：支持多种格式的外部配置文件读写。
*   **运行时热更新**：支持在不重启应用的情况下重新加载配置参数。
*   **加密支持**：针对敏感配置项提供基础加密层。

### 3. 授权与安全 (License & Date Validation)
专为 B 端展示项目或外包交付设计：
*   **日期硬锁**：简单有效的运行时日期验证，防止超期使用。
*   **授权校验逻辑**：可扩展的硬件 ID 绑定或在线激活验证接口。

### 4. 增强型通用类
*   **DraggableElement**：支持 UI 元素的运行时自由拖拽。
*   **TransformBox**：类引擎编辑器的变换框，支持运行时缩放、旋转操作。
*   **Hardware Bridge**：封装了通过 UDP 或 Serial Port 进行硬件交互的常用通讯协议。

## 🛠️ 环境要求
*   **Godot Engine**: 4.x (建议使用 .NET 版本以获得最佳 C# 支持)
*   **Language**: GDScript / C#

## 📦 安装说明

1.  克隆本仓库到你的项目 `addons/` 目录下：
```bash
    git clone [https://github.com/your-username/godot-kit.git](https://github.com/your-username/godot-kit.git)
    ```
2.  在 Godot 编辑器中前往 `Project Settings -> Plugins`。
3.  找到 **Godot-Kit** 并勾选 `Enable`。

## 📖 快速上手

### 外部图片加载示例 (GDScript)
```gdscript
var loader = ExternalLoader.new()
var texture = loader.load_texture("C:/Exhibition/Assets/logo.png")
if texture:
    $Sprite2D.texture = texture
