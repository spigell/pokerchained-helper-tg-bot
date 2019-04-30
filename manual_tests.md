0) random / command => /help
1) /help

Accounts:
  - /account spigellossss # => stats
  - /account wrong # => error
  - /account # => error
  menu:
    - Players:
        spigellossss #=> stats
        wrong # => error
        empty # => error
  
Tables:
  - /tables # => stats
  menu:
    - Tables:
        table: # => right
          account # => stats
