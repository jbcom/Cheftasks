module Audit
    class Auditer
      require 'sqlite3'

      attr_accessor :conn

      DB = "audit.db"
      TABLE = "Audit"
      SCHEMA = "Id INTEGER PRIMARY KEY, Type INTEGER, Name TEXT, Results TEXT"
      OBJECTS = [
        'ROLE' => 0,
        'COOKBOOK' => '1',
        'METADATA' => '2',
        'RECIPE' => '3'
      ]

      def initialize
        begin
          @conn = SQLite3::Database.new(DATABASE_PATH, 0644)
        rescue SQLite3::Exception => e
            puts "Exception occurred: #{e}"
        ensure
            @conn.close if db
        end
      end

      def refresh
        @conn.execute "DROP TABLE IF EXISTS #{TABLE}"
        @conn.execute "CREATE TABLE #{TABLE}(#{SCHEMA})"
      end
    end

    def self.connect
      Auditer.new
    end
end
