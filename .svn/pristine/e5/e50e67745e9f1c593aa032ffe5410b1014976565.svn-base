shader_type canvas_item;

// 扫光参数
uniform float sweep_speed : hint_range(0.1, 5.0) = 1.0;   // 扫光速度
uniform float sweep_width : hint_range(0.01, 0.5) = 0.1;  // 扫光宽度
uniform float intensity : hint_range(0.0, 3.0) = 1.5;     // 扫光亮度
uniform float angle : hint_range(0.0, 6.28) = 0.0;        // 扫光角度，0为水平
uniform float interval_time : hint_range(0.1, 10.0) = 3.0; // 扫光间隔

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);

    // 扫光方向向量
    vec2 dir = vec2(cos(angle), sin(angle));

    // 当前周期内时间（0~1）
    float t = mod(TIME, interval_time) / interval_time;

    // 当 t 在一定范围内才扫光
    float sweep_phase = smoothstep(0.0, 0.05, t) - smoothstep(0.95, 1.0, t);

    // UV 投影到扫光方向
    float proj = dot(UV, dir);

    // 扫光位置沿方向移动
    float position = t * sweep_speed;

    // 扫光亮度（条状高光）
    float light = smoothstep(-sweep_width, sweep_width, proj - position) * sweep_phase;

    vec3 color = base_color.rgb + light * intensity;

    COLOR = vec4(color, base_color.a);
}
