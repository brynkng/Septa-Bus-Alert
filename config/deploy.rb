require "rvm/capistrano"
require "bundler/capistrano" 

set :user, 'brynkng'
set :use_sudo, false
set :application, "septabusalert"
set :repository,  "git@github.com:brynkng/Septa-Bus-Alert.git"

set :rvm_type, :system

set :scm, :git # You can set :scm explicitly or Capistrano will make an intelligent guess based on known version control directory names
set :scm_username, 'brynkng'
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`
set :deploy_via, :remote_cache
#ssh_options[:forward_agent] = true
#default_run_options[:pty] = true

role :web, "162.216.113.68"                          # Your HTTP server, Apache/etc
role :app, "162.216.113.68"                          # This may be the same as your `Web` server
role :db,  "162.216.113.68", :primary => true # This is where Rails migrations will run
role :db,  "162.216.113.68"

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
 namespace :deploy do
   task :start do ; end
   task :stop do ; end
   task :restart, :roles => :app, :except => { :no_release => true } do
     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
   end
 end
