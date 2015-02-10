namespace :ct do
  namespace :install do
    desc "Symlink Cheftasks into your chef-repo (optionally install Chef development kit)"
    task :default, :support_libs do |t, args|
      args.with_defaults(support_libs: false)
      REPO_DIR = ENV['REPO_DIR'] || File.expand_path(File.join(TOP_DIR, ".."))

      if MANAGER and args[:support_libs]
        sh 'which chef'
        unless $?.success?
          if MANAGER == 'brew'
            sh 'which brew'
            unless $?.success?
              puts "Installing Homebrew, the OSX package manager."
              sh 'ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
            end

            install_app('caskroom/cask/brew-cask')

            sh 'brew update'
          end

          install_app('chef', MANAGER_GUI)
        end

        puts 'ChefDK is installed and ready to go'

        puts 'Installing support libraries'
        BREW_LIBS.each do |lib|
          install_app lib
        end

        puts 'Installing support gems'
        CHEF_GEMS.each do |gem|
          install_gem gem
        end
      else
        puts "No supported package manager found. Install development environment manually."
      end

      make_symlinks(REPO_DIR)
    end

    desc "Update Cheftasks to the latest"
    task :update do
      sh 'git stash'
      sh 'git checkout master'
      sh 'git pull'
      sh 'git stash pop'

      if $?.success?
        Rake::Task["install"].reenable
        Rake::Task["install"].invoke
      else
        puts "Pulling from remote failed. Status of repository is:"
        sh 'git status'
      end
    end

    private
    def install_app(name, pkg_mgr=MANAGER, action=ACTION, elevate=ELEVATE)
      puts "Installing #{name}"

      cmd = (elevate)? "sudo #{pkg_mgr}": pkg_mgr
      cmd += " #{action} #{name}"
      sh cmd
    end

    def install_gem(name, elevate=ELEVATE)
      puts "Installing #{name}"

      cmd = (elevate)? "sudo chef": 'chef'
      cmd += " gem install --no-ri --no-rdoc #{name}"
      sh cmd
    end

    def make_symlinks(repo_dir)
      begin
        Dir.chdir(repo_dir) do
          Dir.mkdir 'config'
          FileUtils.ln_sf "#{TOP_DIR}/config/cheftasks.rb", 'config/'

          if Dir.exist? 'rakelib' and !File.symlink? 'rakelib'
            FileUtils.mv 'rakelib', 'sitelib'
            puts 'Moving existing rakelib directory to sitelib'
          end

          FileUtils.ln_sf "#{TOP_DIR}/rakelib", '/'

          if File.exist? 'Rakefile' and !File.symlink? 'Rakefile'
            FileUtils.mv 'Rakefile', 'sitelib/site.rake.disabled'
            puts 'Moving existing Rakefile to sitelib/site.rake.disabled (Manually enable after verifying compatibility with Cheftasks)'
          end

          FileUtils.ln_sf "#{TOP_DIR}/Rakefile", "#{repo_dir}/"
          sh 'rake -T'
        end
      rescue Errno::ENOENT
        puts "Failure changing directories to #{repo_dir}. Verify repository location."
        exit(78) # Bad configuration error
      end
    end
  end
end
