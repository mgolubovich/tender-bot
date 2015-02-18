class WebBot
def source_id; '5370b311a4c6e92e86000001' end

def group; :'44' end

def proxy_ok?
  #byebug
  if at_css('purchname') or at_xpath('//purchID')
    true
  else
    false
  end
end

def get_last_ids
  log 'Открываем основной список sberbankast'
  get 'http://www.sberbank-ast.ru/purchaseList.aspx'#, :proxy => 'http://77.222.137.6:3128'))
  #inner_xml = Nokogiri::XML(@doc.at_css('#phWorkZone_xmlData').content, nil, 'UTF-8')
  log ('Берем первый верхний id sberbankast')
  last_id = at_xpath('//purchID').content
  log("Получен первый id #{last_id}")
  link = 'http://www.sberbank-ast.ru/purchaseview.aspx?id='
  {last_id:(last_id.to_i + 100), link:link}
end

def load_doc
  #byebug
  @doc = Nokogiri::XML(@driver.find_element(css:'#phWorkZone_xmlData').attribute('outerHTML'), nil, 'UTF-8')
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
end