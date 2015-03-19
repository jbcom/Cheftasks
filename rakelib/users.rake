namespace :ct do
  namespace :users do
    desc "Create a new user databag"
    task :default, :user do |t, args|
      if args[:user]
        puts "User created at #{users(args[:user])}"
      else
        puts "Required parameter 'user' missing"
      end
    end

    desc "Create a Users recipe from databags"
    task :generate_recipe, :recipe_name do |t, args|
      args.with_defaults(recipe_name: 'users')

      File::open("#{SITE_COOKBOOK}/recipes/#{args[:recipe_name]}.rb", 'w') do |f|
        f << "# #{SITE_COOKBOOK_NAME}::#{args[:recipe_name]}"
        f << "# Managed by Cheftasks"

        users do |u|
          f << "user '#{u['id']}' do"

          %w(comment gid home iterations password provider salt shell supports system uid username).each do |x|
            case u[x]
            when String
              f << "\t#{x} '#{u[x]}'"
            when Fixnum
              f << "\t#{x} #{u[x]}"
            when Hash
              f << "\t#{x} (#{u[x].to_s})"
            else
              puts "Ignoring parameter '#{x}' with value '#{u[x]}', unsupported type"
            end
          end

          f << "end\n\n"
        end
      end
    end

    desc "Prune passwords (optionally restrict to users in group)\n\tOptional environment variables:\n\tNOT=false (Restricts to users NOT in group)"
    task :prune_passwords, :group do |t, args|
      args.with_defaults(group: 'users')

      Dir.glob(users) do |databag_file|
        user_data = JSON.parse(File.read(databag_file))

        if args[:group]
          if user_data['groups']
            if ENV['NOT']
              next if user_data['groups'].include?(args[:group])
            else
              next unless user_data['groups'].include?(args[:group])
            end
          end
        end

        user_data.delete('password')
        user_json = JSON.pretty_generate(user_data)
        File.open(databag_file, 'w') { |f| f.write(user_json) }
      end
    end

    desc "Generate passwords (optionally restrict to group)\n\tOptional environment variables:\n\tREGENERATE=false (Overwrites existing passwords)\n\tPASSWORD_LENGTH=#{DEFAULT_PASSWORD_LENGTH} (Generates a password N characters in length)"
    task :generate_passwords, :group do |t, args|
      password_length = ENV['PASSWORD_LENGTH'] || DEFAULT_PASSWORD_LENGTH

      CSV.open("#{TOP_DIR}/default_passwords.csv", 'w') do |csv|
        Dir.glob(users) do |databag_file|
          user_data = JSON.parse(File.read(databag_file))

          if user_data["password"] and !ENV['REGENERATE']
           puts "Password already set for #{user_data['id']}"
          else
            if args[:group]
              if user_data['groups']
                next unless user_data['groups'].include?(args[:group])
              else
                next
              end
            end

            password = SecureRandom.hex(password_length)
            csv << [ user_data['id'], password ]
            user_data['password'] = UnixCrypt::SHA512.build(password)

            user_json = JSON.pretty_generate(user_data)

            File.open(databag_file, 'w') { |f| f.write(user_json) }
          end
        end
      end
    end

    desc "Set custom password for a user (Omit password to generate one)\n\tOptional environment variables:\n\tPASSWORD_LENGTH=#{DEFAULT_PASSWORD_LENGTH} (Generates a password N characters in length)"
    task :custom_password, :user, :password do |t, args|
      if args[:user]
        password_length = ENV['PASSWORD_LENGTH'] || DEFAULT_PASSWORD_LENGTH
        args.with_defaults(password: SecureRandom.hex(password_length))
        databag_file = users(args[:user])
        user_data = JSON.parse(File.read(databag_file)) 
        user_data['password'] = UnixCrypt::SHA512.build(user_password)
        user_json = JSON.pretty_generate(user_data)

        File.open(databag_file, 'w') { |f| f.write(user_json) }
        puts "Password set to #{user_password}"
      else
        puts "Required parameter 'user' missing"
      end
    end
      
    desc "Add a SSH public / private key from STDIN for a user (optionally specify file path)"
    task :add_key, :user, :key_file do |t, args|
      begin
        key = (args[:key_file] || STDIN.read).chomp!
        databag_file = users(args[:user])
        user_data = JSON.parse(File.read(databag_file))

        if key.include?('PRIVATE KEY')
          puts "Saving private key"
          user_data["ssh_private_key"] = key
        else
          puts "Saving public key"
          if user_data['ssh_keys']
            if user_data['ssh_keys'].include?(key)
              puts "SSH key is already added for #{args[:user]}"
            else
              ssh_keys = (user_data['ssh_keys'] << key)
            end
          else
            ssh_keys = [key]
          end
          
          user_data["ssh_keys"] = ssh_keys
        end

        user_json = JSON.pretty_generate(user_data)

        File.open(databag_file, "w") { |f| f.write(user_json) }
      rescue Errno::EPIPE
        puts "No file specified and STDIN is empty"
        exit(74) #IO Error
      end
    end

    private
    def users(databag_name = '', &block)
      p = File.join(DATABAGS_DIR, 'users')
      FileUtils.mkdir_p p

      if databag_name
        p = File.join(users, "#{databag_name}.json")

        unless File.exist?(p)
          user_data = { 'id' => databag_name }
          user_json = JSON.pretty_generate(user_data)
          File.open(users, "w") { |f| f.write(user_json) }
        end
      else
        p = File.join(users, '*.json')
      end

      if block_given?
        Dir.glob(p) do |x|
          d = JSON.parse(File.read(data))
          block.call(d)
        end
      end

      return p
    end
  end
end
