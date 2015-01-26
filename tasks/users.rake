require 'json'
require 'unix_crypt'
require 'securerandom'
require 'csv'

desc "Prune passwords for non-sysadmins"
task :user_prune_passwords do |t, args|
  Dir['data_bags/users/*.json'].each do |databag_file|
    user_data = JSON.parse(File.read(databag_file))

    if user_data['groups'] and !user_data['groups'].include?('sysadmin')
      user_data.delete('password')
      user_json = JSON.pretty_generate(user_data)
      File.open(databag_file, 'w') { |f| f.write(user_json) }
    end
  end
end

desc "Generate default passwords for all users"
task :user_default_passwords do |t, args|
  CSV.open('data_bags/default_passwords.csv', 'w') do |csv|
    Dir['data_bags/users/*.json'].each do |databag_file|
      user_data = JSON.parse(File.read(databag_file))

      if user_data["password"]
        print "Password already set for #{user_data['id']}"
      else
        plaintext_password = SecureRandom.hex(16)
        csv << [ user_data['id'], plaintext_password ]
        user_data['password'] = UnixCrypt::SHA512.build(plaintext_password)

        user_json = JSON.pretty_generate(user_data)

        File.open(databag_file, 'w') { |f| f.write(user_json) }
      end
    end
  end
end

desc "Set custom password for a user databag (If password is not speciified a randomly generated one wil be used)"
task :user_custom_password, :user, :password do |t, args|
  databag_file = "data_bags/users/#{args.user}.json"

  if File.exist?(databag_file)
    user_data = JSON.parse(File.read(databag_file))

    if args.password
      user_password = args.password
    else
      user_password = SecureRandom.hex(16)
    end

    user_data['password'] = UnixCrypt::SHA512.build(user_password)
    user_json = JSON.pretty_generate(user_data)

    File.open(databag_file, 'w') { |f| f.write(user_json) }
    print "Password set to #{user_password}"
  else
    print "User not found by that name. Check name of JSON file and try again."
  end
end

desc "Add a public or private key to a user databag"
task :user_save_rsa, :rsa_file, :user do |t, args|
  if File.exist?(args.rsa_file)
    rsa_key = File.read(args.rsa_file)
    databag_file = "data_bags/users/#{args.user}.json"

    if File.exist?(databag_file)
      user_data = JSON.parse(File.read(databag_file))
    else
      user_data = {}
    end

    if File.extname(args.rsa_file) == ".pub"
      print "Saving public key"
      if user_data["ssh_keys"]
        user_data["ssh_keys"] << rsa_key.chomp!
      else
        user_data["ssh_keys"] = ["#{rsa_key.chomp!}"]
      end
    else
      print "Saving private key"
      user_data["ssh_private_key"] = rsa_key.chomp!
    end

    user_json = JSON.pretty_generate(user_data)

    if File.exist?(databag_file)
      File.open(databag_file, "w") { |f| f.write(user_json) }
    else
      print JSON.pretty_generate(user_json)
    end
  else
    print "Could not open #{args.rsa_file} for reading. Make sure this is the full path to a private key or public (.pub) key"
  end
end

