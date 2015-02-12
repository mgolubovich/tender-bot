Dir.mkdir('logs') unless File.exists?('logs')

namespace :dev do

  task :console do
    byebug
  end

  task :test do
    puts '------------------------------------------------------100 часов-----------------------------------------------------'
    WebBot.new('zakupki_44').run 6000
  end
end