module Stimulus::Manifest
  extend self

  def generate_from(controllers_path)
    manifest = extract_controllers_from(controllers_path).collect do |controller_path|
      import_and_register_controller(controllers_path, controller_path)
    end

    manifest.uniq
  end

  def write_index_from(controllers_path)
    File.open(Rails.root.join(controllers_path.join("index.js")), "w+") do |index|
      index.puts "// This file is auto-generated by ./bin/rails stimulus:manifest:update"
      index.puts "// Run that command whenever you add a new controller or create them with"
      index.puts "// ./bin/rails generate stimulus controllerName"
      index.puts
      index.puts %(import { application } from "./application")
      index.puts generate_from(controllers_path)
    end
  end

  def import_and_register_controller(controllers_path, controller_path)
    controller_path = controller_path.relative_path_from(controllers_path).to_s
    module_path = controller_path.split('.').first
    controller_class_name = module_path.underscore.camelize.gsub(/::/, "__")
    tag_name = module_path.remove(/_controller/).gsub(/_/, "-").gsub(/\//, "--")

    <<-JS

import #{controller_class_name} from "./#{module_path}"
application.register("#{tag_name}", #{controller_class_name})
    JS
  end

  def extract_controllers_from(directory)
    (directory.children.select { |e| e.to_s =~ /_controller(\.\w+)+$/ } +
      directory.children.select(&:directory?).collect { |d| extract_controllers_from(d) }
    ).flatten.sort
  end
end
