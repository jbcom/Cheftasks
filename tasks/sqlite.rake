require 'sqlite3'

begin
  db = SQLite3::Database.new('config/audits.db', 0644)
rescue SQLite3::Exception => e 
    puts "Exception occurred: #{e}"
ensure
    db.close if db
end

namespace :sqlite do
  desc "Create sqlite audits table"

end
