class PokerstatsGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.directory "db/migration"
      m.template "hand_statistics.rhtml",   "db/migration/create_hand_statistics.migration"
      m.template "player_statistics.rhtml",   "db/migration/create_player_statistics.migration"
    end
  end
end
