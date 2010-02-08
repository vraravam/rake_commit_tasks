namespace :svn do
  desc "display svn status"
  task :st do
    puts %x[svn st --ignore-externals | grep -v ^X]
  end

  desc "svn up and check for conflicts"
  task :up do
    output = %x[svn up #{ENV['SVN_IGNORE_EXTERNALS']}]
    puts output
    output.each do |line|
      raise "SVN conflict detected. Please resolve conflicts before proceeding." if conflicts?(line)
    end
  end

  desc "add new files to svn"
  task :add do
    %x[svn st].split("\n").each do |line|
      if marked_for_addition?(line) && !svn_conflict_file?(line)
        file = line.split(' ').last
        %x[svn add #{file.inspect}]
        puts %[added #{file.inspect}]
      end
    end
  end

  desc "Set flag to ignore externals"
  task :set_ignore_externals_flag do
    ENV['SVN_IGNORE_EXTERNALS'] = '--ignore-externals'
  end

  desc "remove deleted files from svn"
  task :delete do
    %x[svn st].split("\n").each do |line|
      if marked_for_deletion?(line)
        file = line.split(' ').last
        %x[svn up #{file.inspect} && svn rm #{file.inspect}]
        puts %[removed #{file.inspect}]
      end
    end
  end
  task :rm => "svn:delete"

  desc "reverts all files in svn and deletes new files"
  task :revert_all do
    system "svn revert -R ."
    %x[svn st].split("\n").each do |line|
      next unless marked_for_addition?(line)
      filename = line.split(' ').last
      rm_r filename
      puts "removed #{filename.inspect}"
    end
  end

  def merge_to_trunk(revision)
    puts "Merging changes into trunk. Don't forget to check these in."
    sh "svn up #{PATH_TO_TRUNK_WORKING_COPY.inspect}"
    sh "svn merge -c #{revision} . #{PATH_TO_TRUNK_WORKING_COPY.inspect}"
  end

  def marked_for_addition?(line)
    line.split(' ').first == "?"
  end

  def marked_for_deletion?(line)
    line.split(' ').first == "!"
  end

  def conflicts?(line)
    line.split(' ').first == "C"
  end

  def svn_conflict_file?(line)
    line =~ /\.r\d+$/ || line =~ /\.mine$/
  end
end
