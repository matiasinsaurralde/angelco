# https://angel.co/syndicates?list_name=leaderboard&page=2&list_name=leaderboard

require './angelco'

dname = Time.now.strftime('%d_%m_%Y')

if !Dir.exists?( dname )
  Dir.mkdir( dname )
end

$DIR = dname

Angelco::get_syndicates()
