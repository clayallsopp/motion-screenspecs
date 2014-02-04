unless defined?(Motion::Project::Config)
  raise "This file must be required within a RubyMotion project Rakefile."
end

class Motion::Project::Config

  def spec_core_files_with_screenshots
    files = spec_core_files_without_screenshots

    lib_helper = File.join(File.dirname(__FILE__), 'spec', 'helpers.rb')
    files << lib_helper unless files.include?(lib_helper)
    files
  end

  alias_method "spec_core_files_without_screenshots", "spec_core_files"
  alias_method "spec_core_files", "spec_core_files_with_screenshots"
end

lib_dir_path = File.dirname(File.expand_path(__FILE__))
Motion::Project::App.setup do |app|
  app.files.unshift(Dir.glob(File.join(lib_dir_path, "motion/**/*.rb")))
end
