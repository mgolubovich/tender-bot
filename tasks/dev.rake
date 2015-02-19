Dir.mkdir('logs') unless File.exists?('logs')

namespace :dev do

  task :console do
    byebug
  end

  task :sberbank_44 do
	loop do
    	WebBot.new('Сбербанк-АСТ_44').run 60
    end
  end

  task :zakupki_44, :mins do |t, args|
    Celluloid::Actor[:zakupki_44] = WebBot.new('Закупки_44')
    return '2 big' if args.mins.to_i > 300
    Celluloid::Actor[:zakupki_44].run args.mins.to_i
  end

  
end