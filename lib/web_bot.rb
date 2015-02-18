require_relative 'dsl'
require_relative 'work_type_processor'

class WebBot
  #include Dsl
  extend Forwardable
  def_delegators(:@doc, :css, :at_css, :xpath, :at_xpath)

  def load_doc
    @doc = Nokogiri::HTML(@driver.find_element(css:'html').attribute('outerHTML'))
  end

  def initialize entity_name
    @entity_name = entity_name
    load "./entities/#{entity_name}.rb"
    load_entity_config
    #p @source_name
    #load "./sources/#{@source_name}.rb"
    #load "/#{list_file}.rb"
    @logger = Logger.new("logs/#{entity_name}.log", 10, 60 * 1024 * 1024)
    update_proxy_list
    next_proxy
  end

  def load_entity_config
    config = YAML.load_file("./entities/#{@entity_name}.yml")
    @source_id = config['source_id']
    @group = config['group'].to_sym
  end

  def run minutes
    log "Start running bot for #{minutes} minutes minimum"
    run_until = (DateTime.now + minutes.minutes).to_datetime
    log run_until.to_s
    ids = get_last_ids
    last_id = ids[:last_id]
    link = ids[:link]
    while run_until > DateTime.now do
      begin
        get link + last_id.to_s
        get_tender(last_id)
        last_id -= 1
      rescue
        last_id -= 1
        next
      end
    end
    @driver.quit if @driver
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
    if @driver 
      @driver.quit
      @driver = nil
    end
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
      @driver.manage.timeouts.implicit_wait = 20
      @driver.manage.timeouts.page_load = 20
      @current_proxy_index += 1
      log "Created driver with proxy #{proxy_address}"
    end
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

  def get_tender(id_by_source)
    if tender_is_empty? then
      log 'тендер пуст'
      return nil
    end
    log "забираю тендер площадки #{@entity_name}: #{get_code}, по адресу #{@driver.current_url}"
    tender = Tender.find_or_create_by(code_by_source: get_code, source_id: @source_id)
    tender.source_link = @driver.current_url
    log "ссылка #{tender.source_link}"
    tender.id_by_source = id_by_source
    tender.group = @group
    log "group #{tender.group}"
    tender.title = get_title
    log "title #{tender.title}"
    tender.start_at = get_start_at
    log "дата начала #{tender.start_at.to_s}"
    tender.start_price = get_start_price
    log "start_price #{tender.start_price.to_s}"
    tender.published_at = get_public_at
    log "дата публикации #{tender.published_at.to_s}"
    tender.tender_form = get_tender_form
    log "форма тендера #{tender.tender_form}"
    tender.customer_name = get_customer
    log "customer_name #{tender.customer_name}"
    tender.customer_inn = get_customer_inn
    log "customer_inn #{tender.customer_inn}"
    tender.customer_address = get_address
    log "address #{tender.customer_address}"
    if get_documents
      mysql_doc = JSON.parse(get_documents)
      documents = []
      mysql_doc.each_pair do |title, link|
        documents << {"doc_title" => title, "doc_link" => link}
      end
      tender.documents = documents
    end
    log 'документы'
    if get_okdps
      mysql_okdps = JSON.parse(get_okdps)
      work_type = []
      mysql_okdps.each_pair do |code, title|
        work_type << {"code" => code, "title" => title}
      end
      tender.work_type = work_type
    end
    log 'work_type'
    tender.external_work_type = WorkTypeProcessor.new(tender.work_type).process
    log 'тендер заполнен'
    tender.save
    log "external_db_id #{tender.external_db_id}"
  end

end