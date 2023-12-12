require 'fileutils'
require_relative "./id_generator"
require_relative "./string_helper"

scene_path = ENV['SCENE']
in_directory = ENV['COMPONENT'].gsub(/\/\z/, "")
component_directory = "#{`echo $GDUTILS_HOME`.strip}/#{in_directory}"

directory = File.dirname(scene_path)
out_components_directory = "#{directory}/Components"

FileUtils.mkdir_p(out_components_directory)
`cp #{component_directory}/*.gd #{out_components_directory}`

ext_resource_lines = []
component_lines = []

Dir["#{component_directory}/*.tscn"].each do |tscn_path|
  content = File.read(tscn_path)
  filename = File.basename(tscn_path)
  filename_without_extension = File.basename(filename, '.tscn')
  class_name = titleize(filename_without_extension)
  uid = content.match(/uid:\/\/[a-z0-9]+/)[0]
  component_id = generate_id(1)
  ext_resource_lines << %(
[ext_resource type="PackedScene" uid="#{uid}" path="res://#{out_components_directory}/#{filename}" id="#{component_id}"])
  component_lines << %(
[node name="#{class_name}" parent="." instance=ExtResource("#{component_id}")]
)

  File.open("#{out_components_directory}/#{filename}", 'w') do |file|
    file << content.gsub("{{out_components_directory}}", out_components_directory)
  end
end

new_lines = []
File.readlines(scene_path, chomp: true).each do |line|
  new_lines << line
end

load_steps = new_lines[0].match(/load_steps=(\d+)/)[1].to_i + 1 rescue 1
new_lines[0].gsub!(/load_steps=(\d+)/, "load_steps=#{load_steps}") 

new_lines = new_lines[0..1] + ext_resource_lines + new_lines[2..] + component_lines

File.open(scene_path, "w") { |f| f << new_lines.join("\n") }
