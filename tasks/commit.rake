require File.expand_path(File.dirname(__FILE__) + '/../lib/commit_message')
require File.expand_path(File.dirname(__FILE__) + '/../lib/scm_helper')

# To use this library, you will need to define a rake task called 'pc'. All steps that are needed before and after 'pc' are implemented here.
namespace :scm do
  namespace :git do
    desc "Run steps that are needed before running tests"
    task :track_and_update => ['git:st', 'git:reset_soft', "giternal:update", 'git:add', 'git:st']

    desc "Run to check in"
    task :ci do
      if GitHelper.files_to_check_in?
        if ScmHelper.ok_to_check_in?
          commit_message = CommitMessage.new
          ScmHelper.sh_with_output("git config user.name #{commit_message.pair.inspect}")
          message = commit_message.joined_message
          ScmHelper.sh_with_output("git commit -m #{message.inspect}")  # local commit

          Rake::Task['git:pull_rebase'].invoke
          Rake::Task['git:push'].invoke   # remote push
        end
      else
        puts "Nothing to commit"
      end
    end
  end

  namespace :svn do
    desc "Run steps that are needed before running tests"
    task :track_and_update => ['svn:st', 'svn:delete', 'svn:add', 'svn:up']

    desc "Run to check in"
    task :ci do
      if SvnHelper.files_to_check_in?
        if ScmHelper.ok_to_check_in?
          message = CommitMessage.new.joined_message
          commit_command = "svn ci -m #{message.inspect}"
          output = ScmHelper.sh_with_output commit_command
          revision = output.match(/Committed revision (\d+)\./)[1]
          SvnHelper.merge_to_trunk(revision) if self.class.const_defined?(:PATH_TO_TRUNK_WORKING_COPY) && `svn info`.include?("branches")
        end
      else
        puts "Nothing to commit"
      end
    end
  end

  task :update do
    if ScmHelper.git?
      Rake::Task["scm:git:track_and_update"].invoke
    else
      Rake::Task["scm:svn:track_and_update"].invoke
    end
  end

  task :ci do
    if ScmHelper.git?
      Rake::Task["scm:git:ci"].invoke
    else
      Rake::Task["scm:svn:ci"].invoke
    end
  end
end

task :commit => ["scm:update", :pc, "scm:ci"]

task :ci => "scm:ci"
