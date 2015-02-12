require 'selenium-webdriver'
require 'nokogiri'
require 'logger'
require 'active_record'
require 'active_support'
require 'yaml'
require 'open-uri'
require './lib/dsl.rb'
require 'forwardable'


class WebBot

  #include Dsl
  extend Forwardable
  def_delegators(:@doc, :css, :at_css, :xpath, :at_xpath)

  def initialize list_file_name
    @list_name = list_file_name
    load "./lists/#{list_file_name}.rb"
    #p @source_name
    #load "./sources/#{@source_name}.rb"
    #load "/#{list_file}.rb"
    @logger = Logger.new("logs/#{list_file_name}.log", 0, 60 * 1024 * 1024)
    init_db
    update_proxy_list
    next_proxy
  end

  def run min_seconds
    log "Start running bot for #{min_seconds} seconds minimum"
    run_until = (DateTime.now + min_seconds.seconds).to_datetime
    log run_until.to_s
    ids = get_last_ids
    last_id = ids[:last_id]
    link = ids[:link]
    while run_until > DateTime.now do
      get link + last_id.to_s
      get_tender
      last_id -= 1
    end
    @driver.quit if @driver
  end

  def init_db
    ActiveRecord::Base.logger = @logger
    #ActiveRecord::Base.establish_connection(db_config)
    require './models/tender_int.rb'
  end

  def log msg
    @logger.info msg
    puts Time.new.strftime"%Y-%m-%d_%H-%M-%S" + '  ' + msg
  end

  def update_proxy_list 
    log "Получаем список прокси с hideme"
    hm_config = YAML.load_file('config/hideme.yml')
    hm_url = hm_config['base_url'] + hm_config.map { |k, v| "#{k}=#{v}" unless k == 'base_url'}.join('&')
    raw_data = open(hm_url).read
    data = JSON.parse(raw_data)
    @proxy_list = data.map { |e| "#{e['host']}:#{e['port']}" }
    log "Получен список #{@proxy_list.to_s}"
    @current_proxy_index = 0
  end

  def next_proxy
    log "Switch to next proxy"
    @driver.quit if @driver
    if @current_proxy_index == @proxy_list.count
      log "Hit the ground, updating proxy list"
      update_proxy_list
      next_proxy
    else
      proxy_address = @proxy_list[@current_proxy_index]
      profile = Selenium::WebDriver::Firefox::Profile.new
      profile.proxy = Selenium::WebDriver::Proxy.new(
        :http     => proxy_address,
        :ftp      => proxy_address,
        :ssl      => proxy_address
        )
      @driver = Selenium::WebDriver.for :firefox, :profile => profile
      @driver.manage.timeouts.implicit_wait = 30
      @driver.manage.timeouts.page_load = 30
      @current_proxy_index += 1
      log "Created driver with proxy #{proxy_address}"
    end
  end

  def load_doc
    @doc = Nokogiri::HTML(@driver.find_element(css:'html').attribute('outerHTML'))
  end

  def get link
    log "GET #{link}"
    @driver.navigate.to link
    load_doc
    unless proxy_ok?
      log 'proxy is not ok'
      next_proxy
      get link
    end
  rescue Exception => e
    log 'Error in get'
    if e.message =='404 Not Found' then
      log '404 Not Found'
    else
      log e.message
      log e.backtrace.inspect
    end
    next_proxy
    get link
  end

  def collect_entity start_url
    log "Starting to collect entity #{@entity_name}"
  end

  def get_tender
    log "создаю объект модели TenderInt"
    tender = TenderInt.find_or_initialize_by(:link => @driver.current_url)
    log "забираю тендер площадки #{self.class.name}, по адресу #{@driver.current_url}"
    if tender_is_empty? then
      log 'тендер пуст'
      return nil
    end
    tender.site_name = self.class.name
    log 'ссылка'
    tender.link = @driver.current_url
    tender.group = @group
    tender.source_id = @source_id
    tender.title = get_title
    tender.code = get_code
    log 'код'
    tender.start_at = get_start_at
    log 'дата начала'
    tender.start_price = get_start_price
    tender.public_at = get_public_at
    log 'дата публикации'
    tender.tender_form = get_tender_form
    log 'форма тендера'
    tender.status = get_status
    log 'статус'
    tender.customer = get_customer
    tender.customer_inn = get_customer_inn
    tender.address = get_address
    tender.status_key = get_status_key
    tender.documents = get_documents
    log 'документы'
    tender.okdps = get_okdps
    log 'тендер заполнен'
    tender.save
  end

end