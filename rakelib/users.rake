namespace :chef do
  namespace :users do
    desc "Prune passwords (optionally restrict to users in group)\nOptional environment variables:\nNOT=false (Restricts to users NOT in group)"
    task :prune_passwords, :group do |t, args|
      args.with_defaults(group: 'users')
      databags_init('users')

      Dir.glob("#{TOP_DIR}/data_bags/users/*.json") do |databag_file|
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

    desc "Generate passwords (optionally restrict to group)\nOptional environment variables:\nREGENERATE=false (Overwrites existing passwords)\nPASSWORD_LENGTH=#{DEFAULT_PASSWORD_LENGTH} (Generates a password N characters in length)"
    task :generate_passwords, :group do |t, args|
      password_length = ENV['PASSWORD_LENGTH'] || DEFAULT_PASSWORD_LENGTH
      databags_init('users')

      CSV.open("#{TOP_DIR}/default_passwords.csv", 'w') do |csv|
        Dir.glob("#{TOP_DIR}/data_bags/users/*.json") do |databag_file|
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

    desc "Set custom password for a user (Omit password to generate one)\nOptional environment variables:\nPASSWORD_LENGTH=#{DEFAULT_PASSWORD_LENGTH} (Generates a password N characters in length)"
    task :custom_password, :user, :password do |t, args|
      if args[:user]
        password_length = ENV['PASSWORD_LENGTH'] || DEFAULT_PASSWORD_LENGTH
        args.with_defaults(password: SecureRandom.hex(password_length))
        databags_init('users', args[:user])
        databag_file = "data_bags/users/#{args[:user]}.json"

        user_data = JSON.parse(File.read(databag_file)) 
        user_data['password'] = UnixCrypt::SHA512.build(user_password)
        user_json = JSON.pretty_generate(user_data)

        File.open(databag_file, 'w') { |f| f.write(user_json) }
        puts "Password set to #{user_password}"
      else
        puts "Required parameter 'user' not specified"
      end
    end
      
    desc "Add a SSH public / private key from STDIN for a user (optionally specify file path)"
    task :add_key, :user, :key_file do |t, args|
      begin
        key = (args[:key_file] || STDIN.read).chomp!
        databags_init('users', args[:user])
        databag_file = "data_bags/users/#{args.user}.json"

        user_data = JSON.parse(File.read(databag_file)) || {}

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
  end
end
