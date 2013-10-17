require 'date'

dates = {}

File.read('quantcast.csv').split("\n").each do |ln|
  #puts ln
  d = Date.strptime(ln, '%b %d, %Y')
  n = ln.split('Uniques ').last.gsub(',', '').to_i
  #puts "#{d.strftime('%d/%m/%Y')},#{n}"
  dates.store( d, n )
end

dates.sort_by { |d,n| d.to_time.to_i }.each do |d, n|
  puts "#{d.strftime('%d/%m/%Y')},#{n}"
end
