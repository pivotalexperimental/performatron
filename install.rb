FileUtils.mkdir_p("#{RAILS_ROOT}/lib/performatron")

default_dir = File.dirname(__FILE__) + "/default"
unless File.exist?("#{RAILS_ROOT}/config/performatron.yml")
  FileUtils.cp(default_dir + "/performatron.yml", "#{RAILS_ROOT}/config/performatron.yml")
end
Dir[default_dir + "/performatron/*"].each do |filepath|
  filename = File.basename(filepath)
  new_path = "#{RAILS_ROOT}/lib/performatron/#{filename}"
  FileUtils.cp(default_dir + "/performatron/" + filename, new_path) unless File.exist?(new_path)
end