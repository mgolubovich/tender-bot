
set_source_id '5370b311a4c6e92e86000001'
byebug
group =:'44'

def proxy_ok?
  at_css('a#linkToDefault')
end

def get_last_ids
  log 'Открываем основной список sberbankast'
  get 'http://www.sberbank-ast.ru/purchaseList.aspx'#, :proxy => 'http://77.222.137.6:3128'))
  #inner_xml = Nokogiri::XML(@doc.at_css('#phWorkZone_xmlData').content, nil, 'UTF-8')
  log ('Берем первый верхний id sberbankast')
  last_id = at_css("a[href*='purchaseview.aspx']")[:href].gsub(/\D/,'')
  log("Получен первый id #{last_id}")
  link = 'http://www.sberbank-ast.ru/purchaseview.aspx?id='
  {last_id:(last_id.to_i + 7), link:link}
end


def get_title
  at_css("td[content='leaf:purchname']").content.strip
end

def get_code
  at_css("td[content='leaf:purchCode']").content.strip
end

def get_start_at
  raw_xpath = "//td[contains(text(), 'Дата и время окончания срока подачи заявок')]/following::td[1]"
  raw_data = at_xpath(raw_xpath).content.match(/(\d\d\.\d\d\.\d\d\d\d)(.)(\d\d:\d\d)/)[0].gsub(/(\d\d\.\d\d\.\d\d\d\d)(.)(\d\d:\d\d)/, '\1 \3')
  byebug
  DateTime.strptime(raw_data,'%d.%m.%Y %H:%M')
end

def get_start_price
  at_css("span[content='leaf:purchAmount']").content.strip.tr(' ', '').to_f
end

def get_public_at
  DateTime.strptime(at_css("td[content='leaf:chngdate']").content.match(/(\d\d\.\d\d\.\d\d\d\d)(.)(\d\d:\d\d)/)[0].gsub(/(\d\d\.\d\d\.\d\d\d\d)(.)(\d\d:\d\d)/, '\1 \3'), '%d.%m.%Y %H:%M')
end

def get_tender_form
  'Открытый аукцион в электронной форме'
end

def get_customer
  at_css("td[content='leaf:orgname']").content.strip
end

def get_address
  at_css("td[content='leaf:orgFactAddress']").content.strip
end

def get_customer_inn
  nil
end

def get_documents
  documents = {}
  css("span[content='leaf:fileName']").each_index do |i|
    documents[css("span[content='leaf:fileName']")[i].content] = css("a[content='leaf:url']")[i].content
  end
  documents.to_json
end

def get_okdps
  okdps = {}
  css("span[content='leaf:code']").each_index do |i|
    documents[css("span[content='leaf:code']")[i].content] = css("span[content='leaf:name']")[i].content
  end
  okdps.to_json
end

def tender_is_empty?
  if at_css("td[content='leaf:purchname']") == nil or at_css("td[content='leaf:purchname']").content == ''
    true
  else
    false
  end
end
