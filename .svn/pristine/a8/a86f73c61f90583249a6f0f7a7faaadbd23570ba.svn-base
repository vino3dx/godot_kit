shader_type canvas_item;

uniform float scroll_speed = 0.1;
uniform int cols = 15;
// 添加一个 uniform 变量来控制透明度
// hint_range(0.0, 1.0) 会在 Inspector 中显示为滑块
uniform float transparency : hint_range(0.0, 1.0) = 1.0; // 默认完全不透明

void fragment() {
    // 获取当前像素的 UV 坐标
    vec2 uv = UV;

    // 计算当前列的索引（从 0 到 14，因为 cols 是 15）
    // 注意：如果你的纹理实际有 16 列，那么 cols 应该是 16
    int col_index = int(floor(uv.x * float(cols)));

    // 计算基于时间的偏移量
    // 使用 mod() 函数确保 time_offset 永远在 [0, 1) 区间内循环
    float time_offset = mod(TIME * scroll_speed, 1.0);

    // 判断列的奇偶性
    if (mod(float(col_index), 2.0) == 0.0) {
        // 偶数列（0, 2, 4...）向下移动
        // 使用 mod() 确保 UV 坐标在 [0, 1) 区间内循环
        uv.y = mod(uv.y - time_offset, 1.0);
    } else {
        // 奇数列（1, 3, 5...）向上移动
        // 使用 mod() 确保 UV 坐标在 [0, 1) 区间内循环
        uv.y = mod(uv.y + time_offset, 1.0);
    }

    // 从纹理中获取颜色
    vec4 final_color = texture(TEXTURE, uv);

    // 应用透明度
    // final_color.a 是当前像素的原始 alpha 值
    // 我们用原始 alpha 值乘以 transparency 变量来达到调节效果
    final_color.a *= transparency;

    // 将修改后的颜色和透明度赋给最终的颜色输出
    COLOR = final_color;
}