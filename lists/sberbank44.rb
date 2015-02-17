
  def get_last_ids
    info 'Открываем основной список sberbankast'
    doc = Nokogiri::HTML(open('http://www.sberbank-ast.ru/purchaseList.aspx', :read_timeout => 5 * 60))#, :proxy => 'http://77.222.137.6:3128'))
    inner_xml = Nokogiri::XML(doc.at_css('#phWorkZone_xmlData')['value'], nil, 'UTF-8')
    info ('Берем первый верхний id sberbankast')
    last_id = inner_xml.at_xpath('//purchID').content
    info("Получен первый id #{last_id}")
    link = 'http://www.sberbank-ast.ru/purchaseview.aspx?id='
    [[last_id.to_i, link]]
  end
  
  def get_last_ids_m
    link = 'http://www.sberbank-ast.ru/purchaseview.aspx?id='
    [[2848047, link]]
  end

  def get link
	  sleep 1
    doc = Nokogiri::HTML(open(link, :read_timeout => 5 * 60))#, :proxy => 'http://69.197.148.18:3127'))
    #doc = super link
    @doc = Nokogiri::XML(doc.at_css('#phWorkZone_xmlData').content, nil, 'UTF-8')
  rescue
    retry
  end

  def get_title
    at_css('purchname').content.strip
  end

  def get_code
    at_css('purchcode').content.strip
  end

  def get_start_at
    p DateTime.strptime(at_css('RequestDate').content.strip + ' ' + at_css('RequestDateTime').content.strip + ' +0400', '%d.%m.%Y %H:%M %z')
    DateTime.strptime(at_css('RequestDate').content.strip + ' ' + at_css('RequestDateTime').content.strip + ' +0400', '%d.%m.%Y %H:%M %z')
  end

  def get_start_price
    at_css('purchamount').content.strip.tr(' ', '')
  end

  def get_public_at
    p DateTime.strptime(at_css('PublicDate').content.strip + ' +0400', '%d.%m.%Y %H:%M %z')
    DateTime.strptime(at_css('PublicDate').content.strip + ' +0400', '%d.%m.%Y %H:%M %z')
  end

  def get_tender_form
    'Открытый аукцион в электронной форме'
  end

  def get_status
    if at_css('purchstate').content.strip == 'public' or at_css('purchstate').content.strip == 'requests'
      'Прием заявок'
    elsif at_css('purchstate').content.strip == 'closed'
      'Завершен'
    elsif at_css('purchstate').content.strip == 'canceled'
      'Отменен'
    else
      'Прием заявок'
    end
  end

  def get_status_key
    if at_css('purchstate').content.strip == 'public' or at_css('purchstate').content.strip == 'requests'
      1
    elsif at_css('purchstate').content.strip == 'closed'
      3
    elsif at_css('purchstate').content.strip == 'canceled'
      4
    else
      1
    end
  end

  def get_customer
    at_css('custorgname').content.strip
  end

  def get_address
    at_css('purchdescr').content.strip
  end

  def get_customer_inn
    at_css('orginn').content.strip
  end

  def get_documents
    documents = {}
    css('documentMeta').each do |document|
      documents[document.at_css('fileName').content] = document.at_css('url').content
    end
    documents.to_json
  end

  def get_okdps
    okdps = {}
    css('product').each do |product|
      okdps[product.at_css('code').content] = product.at_css('name').content
    end
    okdps.to_json
  end

  def tender_is_empty?
    if at_css('purchname') == nil or at_css('purchname').content == ''
      true
    else
      false
    end
  end

  def get_tender(link)
    info "создаю объект модели TenderInt"
    tender = TenderInt.new
    info "забираю тендер площадки #{self.class.name}, по адресу #{link}"
    begin
      get link
    rescue Exception => e
      if e.message =='404 Not Found' then
        info '404 тендер пуст'
        return nil
      else
        info e.message
        info e.backtrace.inspect
        return nil
      end
    end
    if tender_is_empty? then
      info 'тендер пуст'
      return nil
    end
    tender.site_name = self.class.name
    tender.site_id = @site_id_hash[self.class.name]
    info 'ссылка'
    tender.link = link
    tender.title = get_title
    tender.code = get_code
    tender.group = '44'
    tender.source_id = '5370b311a4c6e92e86000001'
    info 'код'
    tender.start_at = get_start_at
    info 'дата начала'
    tender.start_price = get_start_price
    tender.public_at = get_public_at
    info 'дата публикации'
    tender.tender_form = get_tender_form
    info 'форма тендера'
    tender.status = get_status
    info 'статус'
    tender.customer = get_customer
    tender.customer_inn = get_customer_inn
    tender.address = get_address
    tender.status_key = get_status_key
    tender.documents = get_documents
    info 'документы'
    tender.okdps = get_okdps
    info 'тендер заполнен'
    tender
  end

  def collect_tenders_up(amount)
    ids = get_last_ids
    ids.each do |last_id, link|
      last_id.upto(last_id + amount) do |id|
        tender = get_tender(link + id.to_s)
        save_tender(tender) if tender
      end
    end
  end

end

sber = Sberbank.new
#while true
  sber.collect_tenders 400000
#end


