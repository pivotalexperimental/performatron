namespace :performatron do
  desc "Upload all /tmp/scenarios/*.sql to remote server's /tmp/scenarios"
  task :upload_scenarios do
    run "mkdir -p /tmp/scenarios"
    Dir["/tmp/scenarios/*.sql"].each do |file|
      system("gzip '#{file}'")
      upload file + ".gz", file + ".gz"
      system("gunzip -f '#{file}.gz'")
      run("gunzip -f '#{file}.gz'")
    end
  end

  desc "Upload all /tmp/scenarios/*.bench to remote server's /tmp/scenarios"
  task :upload_sequences do
    run "mkdir -p /tmp/scenarios"
    Dir["/tmp/scenarios/*.bench"].each do |file|
      system("gzip '#{file}'")
      upload file + ".gz", file + ".gz"
      system("gunzip -f '#{file}.gz'")
      run("gunzip -f '#{file}.gz'")
    end
  end

  desc "Load a specific performance scenario from /tmp/scenario"
  task :load_scenario do
    raise "Must specify -Sscenario=" unless scenario
    run "cd #{current_path} && rake performatron:load_scenario SCENARIO=#{scenario} RAILS_ENV=#{rails_env}"
  end

  task :default do
    raise "Cannot build scenarios" unless system("rake performance:build_scenarios")
    upload_scenarios
  end
  
  task :run_httperf do
    global_options = "--hog --session-cookie"
    global_options << " --add-header='#{header}'" if header
    cmd = "httperf #{global_options} --server=#{host} --port=#{port} --wsesslog=#{num_sessions},0,#{filename} --rate=#{rate} 2>&1"
    puts "Running #{cmd}"
    run(cmd)
  end
end