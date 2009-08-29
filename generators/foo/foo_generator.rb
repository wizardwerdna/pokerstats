class FooGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.directory "db/migration"
      m.template "hand_statistics.rhtml",   "db/migration/create_hand_statistics"
      m.template "player_statistics.rhtml",   "db/migration/create_player_statistics"
    end
  end
end
