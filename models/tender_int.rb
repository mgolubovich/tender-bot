class TenderInt  < ActiveRecord::Base
  ActiveRecord::Base.establish_connection(
  adapter:  'mysql2',
  encoding: 'utf8',
  database: 'parser',
  username: 'developer',
  password: 'vGm6k',
  host:     '10.0.105.13'
  ) 
  self.table_name = 'tenders'
end