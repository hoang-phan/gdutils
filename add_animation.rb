require_relative "./id_generator"

scene_path = ENV['SCENE']
asset_path = ENV['ASSET'].gsub(/\/\z/, "")
node_name = ENV['NODE'] || "Body"

frames = {}
index = 0

Dir["#{asset_path}/**/*.import"].each do |import_path|
  index += 1
	file_path = import_path[0..-8]
	uid = File.read(import_path).match(/uid:\/\/[a-z0-9]+/)[0]
	relative_path = file_path.split("#{asset_path}/")[1]
	animation_name, direction = relative_path.split("/")
	anim = "#{animation_name}_#{direction}".downcase
	frames[anim] ||= []
	frames[anim] << [uid, file_path, generate_id(index)]
end

new_lines = []
File.readlines(scene_path, chomp: true).each do |line|
  new_lines << line
end

load_steps = new_lines[0].match(/load_steps=(\d+)/)[1].to_i rescue 0
load_steps += index # total frame size
  + frames.size # total new animations
  + 1 # animation reset
  + 1 # animation library
  + 1 # sprite frame
new_lines[0].gsub!(/load_steps=(\d+)/, "load_steps=#{load_steps}") 

frame_lines = []

frames.values.each do |group|
  group.each do |(uid, file_path, id)|
    frame_lines << %([ext_resource type="Texture2D" uid="#{uid}" path="res://#{file_path}" id="#{id}"])
  end
end

sprite_frames_id = "SpriteFrames_#{generate_str(5)}"

animation_lines = frames.map do |anim, lst|
  frame_list = lst.map do |(_, _, id)|
%({
"duration": 1.0,
"texture": ExtResource("#{id}")
})
  end.join(", ")

%({
"frames": [#{frame_list}],
"loop": true,
"name": &"#{anim}",
"speed": 5.0
})
end.join(", ")

reset_animation_id = "Animation_#{generate_str(5)}"
reset_animation = %(
[sub_resource type="Animation" id="#{reset_animation_id}"]
length = 0.001
tracks/0/type = "value"
tracks/0/imported = false
tracks/0/enabled = true
tracks/0/path = NodePath("Body:animation")
tracks/0/interp = 1
tracks/0/loop_wrap = true
tracks/0/keys = {
"times": PackedFloat32Array(0),
"transitions": PackedFloat32Array(1),
"update": 1,
"values": [&"#{frames.keys[0]}"]
}
tracks/1/type = "value"
tracks/1/imported = false
tracks/1/enabled = true
tracks/1/path = NodePath("Body:frame")
tracks/1/interp = 1
tracks/1/loop_wrap = true
tracks/1/keys = {
"times": PackedFloat32Array(0),
"transitions": PackedFloat32Array(1),
"update": 1,
"values": [0]
}
)

animations = {}
animation_map = {}

frames.each do |anim, lst|
  id = "Animation_#{generate_str(5)}"
  animation_map[id] = anim
  animations[id] = %(
[sub_resource type="Animation" id="#{id}"]
resource_name = "#{anim}"
length = #{(lst.size * 0.1).round(1)}
tracks/0/type = "value"
tracks/0/imported = false
tracks/0/enabled = true
tracks/0/path = NodePath("Body:animation")
tracks/0/interp = 1
tracks/0/loop_wrap = true
tracks/0/keys = {
"times": PackedFloat32Array(0),
"transitions": PackedFloat32Array(1),
"update": 1,
"values": [&"#{anim}"]
}
tracks/1/type = "value"
tracks/1/imported = false
tracks/1/enabled = true
tracks/1/path = NodePath("Body:frame")
tracks/1/interp = 1
tracks/1/loop_wrap = true
tracks/1/keys = {
"times": PackedFloat32Array(#{lst.size.times.map { |i| (i * 0.1).round(1).to_s }.join(", ")}),
"transitions": PackedFloat32Array(#{lst.size.times.map { "1" }.join(", ")}),
"update": 1,
"values": #{lst.size.times.to_a}
}
)
end

animation_library_id = "AnimationLibrary_#{generate_str(5)}"

new_lines = new_lines[0..1] + frame_lines + [%(
[sub_resource type="SpriteFrames" id="#{sprite_frames_id}"]
animations = [#{animation_lines}]
#{reset_animation}
#{animations.values.join("\n")}

[sub_resource type="AnimationLibrary" id="#{animation_library_id}"]
_data = {
"RESET": SubResource("#{reset_animation_id}"),
#{animation_map.map do |id, anim|
  %("#{anim}": SubResource("#{id}"))
end.join(",\n")}
}
)] + new_lines[2..] + [
%(
[node name="Body" type="AnimatedSprite2D" parent="."]
sprite_frames = SubResource("#{sprite_frames_id}")
animation = &"#{frames.keys[0]}"

[node name="AnimationPlayer" type="AnimationPlayer" parent="."]
libraries = {
"": SubResource("#{animation_library_id}")
}
)]

File.open(scene_path, "w") { |f| f << new_lines.join("\n") }
