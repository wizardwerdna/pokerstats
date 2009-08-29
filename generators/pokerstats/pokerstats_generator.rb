class PokerstatsGenerator < Rails::Generator::Base  
  def manifest
    record do |m|
      m.migration_template "create_pokerstats.rhtml",   "db/migrate", :migration_file_name => "create_pokerstats"
    end
  end
end
