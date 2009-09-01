module Pokerstats
  module HandConstants
    HAND_REPORT_SPECIFICATION = [
      # [key,   sql_type,   function]
      [:session_filename, 'string'],
      [:starting_at, 'datetime'],
      [:name, 'string'], 
      [:description, 'string'], 
      [:sb, 'decimal'], 
      [:bb, 'decimal'], 
      [:board, 'string'], 
      [:total_pot, 'decimal'], 
      [:rake, 'decimal'], 
      [:played_at, 'datetime'], 
      [:tournament, 'string']
    ]
    HAND_INFORMATION_KEYS = HAND_REPORT_SPECIFICATION.map{|each| each.first}
    HAND_RECORD_INCOMPLETE_MESSAGE = "hand record is incomplete"
    PLAYER_RECORDS_NO_PLAYER_REGISTERED = "no players have been registered"
    PLAYER_RECORDS_DUPLICATE_PLAYER_NAME = "player screen_name has been registered twice"
    PLAYER_RECORDS_NO_BUTTON_REGISTERED = "no button has been registered"
    PLAYER_RECORDS_UNREGISTERED_PLAYER = "player has not been registered"
    PLAYER_RECORDS_OUT_OF_BALANCE = "hand record is out of balance"                

    MAX_SEATS = 12
  end
end