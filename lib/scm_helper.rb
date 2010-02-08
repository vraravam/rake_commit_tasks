require File.expand_path(File.dirname(__FILE__) + '/cruise_status')

module ScmHelper
  def self.git?
    `git symbolic-ref HEAD 2>/dev/null`
    $?.success?
  end

  def self.ok_to_check_in?
    return true unless self.class.const_defined?(:CCRB_RSS)
    cruise_status = CruiseStatus.new(CCRB_RSS)
    cruise_status.pass? ? true : are_you_sure?( "Build FAILURES: #{cruise_status.failures.join(', ')}" )
  end

  def self.are_you_sure?(message)
    puts "\n", message
    input = ""
    while (input.strip.empty?)
      input = Readline.readline("Are you sure you want to check in? (y/n): ")
    end
    return input.strip.downcase[0, 1] == "y"
  end

  def self.sh_with_output(command)
    puts command
    output = `#{command}`
    puts output
    raise unless $?.success?
    output
  end
end

module GitHelper
  def self.files_to_check_in?
    lines = %x[git status].split("\n")
    !locally_committed?(lines) || (locally_committed?(lines) && not_pushed?(lines))
  end

  private
  def self.locally_committed?(lines)
    lines.any?{|line| line =~ /nothing to commit/}
  end

  def self.not_pushed?(lines)
    lines.any? {|line| line =~ /is ahead of/}
  end
end

module SvnHelper
  def self.files_to_check_in?
    %x[svn st --ignore-externals].split("\n").reject {|line| line[0, 1] == "X"}.any?
  end
end
