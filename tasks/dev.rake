Dir.mkdir('logs') unless File.exists?('logs')

namespace :dev do

  task :console do
    byebug
  end

  task :test do
    WebBot.new('zakupki_44').run 10
  end
end