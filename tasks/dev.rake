Dir.mkdir('logs') unless File.exists?('logs')

namespace :dev do

  task :console do
    byebug
  end

  task :sberbank_44 do
	loop do
    	WebBot.new('sberbank_44').run 60
    end
  end

  task :zakupki_44 do
  	loop do
    	WebBot.new('zakupki_44').run 120
    end
  end
end