module Pokerstats
  module HandConstants
    HAND_REPORT_SPECIFICATION = [
      [:session_filename, 'string'],
      [:starting_at, 'datetime'],
      [:name, 'string'], 
      [:table_name, 'string'], 
      [:description, 'string'], 
      [:ante, 'decimal'],
      [:sb, 'decimal'], 
      [:bb, 'decimal'], 
      [:board, 'string'], 
      [:total_pot, 'decimal'], 
      [:rake, 'decimal'],
      [:played_at, 'datetime'], 
      [:tournament, 'string'],
      [:max_players, 'integer'],
      [:number_players, 'integer'],
      [:game_type, 'string'],
      [:limit_type, 'string'],
      [:stakes_type, 'decimal']
    ]
    HAND_INFORMATION_KEYS = HAND_REPORT_SPECIFICATION.map{|each| each.first}
    HAND_RECORD_INCOMPLETE_MESSAGE = "hand record is incomplete"
    PLAYER_RECORDS_NO_PLAYER_REGISTERED = "no players have been registered"
    PLAYER_RECORDS_DUPLICATE_PLAYER_NAME = "player screen_name has been registered twice"
    PLAYER_RECORDS_NO_BUTTON_REGISTERED = "no button has been registered"
    PLAYER_RECORDS_UNREGISTERED_PLAYER = "player has not been registered"
    PLAYER_RECORDS_OUT_OF_BALANCE = "hand record is out of balance"                

    MAX_SEATS = 12

    CARDS = "AKQJT98765432"
  end
end