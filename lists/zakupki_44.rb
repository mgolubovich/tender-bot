#class WebBot
def source_id; '5339108d1d0aab8c0a000001' end
def group; '44' end

def proxy_ok?
  if at_xpath("//*[contains(text(),'Перейти на главную страницу')]") or 
    at_css("link[href*='/epz/order/css/printForm.css']") or 
    at_xpath("//*[contains(text(),'Реестр закупок и заказов')]")or 
    at_xpath("//*[contains(text(),'Закупка')]")
    true
  else
    false
  end
end

def get_last_ids
  log 'Открываем основной список zakupki'
  get('http://zakupki.gov.ru/epz/order/quicksearch/search.html?searchString=')
  log 'Берем верхний id zakupki'
  get @driver.find_element(xpath:'//a[contains(@href,"44/view/doc")]').attribute('href')
  link = 'http://zakupki.gov.ru/epz/order/printForm/view.html?printFormId='
  last_id = @driver.find_element(css:'a.printForm').attribute('href').gsub(/\D/,'')
  log("Получен id #{last_id}")
  {last_id:(last_id.to_i + 100), link:link}
end

def get_title
  at_xpath('//*[text()="Наименование объекта закупки"]/following::*[1]').content.gsub(/\t/, '').gsub(/\n/, '').strip
end

def get_code
  at_xpath('//*[text()="Номер извещения"]/following::*[1]').content.strip if at_xpath('//*[text()="Номер извещения"]/following::*[1]')
end

def get_start_at
  if at_xpath('//*[text()="Дата и время окончания подачи заявок"]/following::*[1]') && at_xpath('//*[text()="Дата и время окончания подачи заявок"]/following::*[1]').content != '' then
    puts start_at_uf = at_xpath('//*[text()="Дата и время окончания подачи заявок"]/following::*[1]').content[0..21].gsub(/[^0-9.: ]/,  '')
    DateTime.strptime(start_at_uf + ' +0400', '%d.%m.%Y %H:%M %z')
  elsif at_xpath('//*[text()="Срок предоставления"]/following::*[1]')
    if at_xpath('//*[text()="Срок предоставления"]/following::*[1]').content[/по (.*)\(/, 1]
      p start_at_uf = at_xpath('//*[text()="Срок предоставления"]/following::*[1]').content[/по (.*)\(/, 1].gsub(' ', '')
      return nil if start_at_uf == ''
      DateTime.strptime(start_at_uf, '%d.%m.%Y')
    end
  #elsif at_xpath('//*[text()="Закупка у единственного поставщика"]')
  #  @driver.execute_script("navigateFromTab('/purchase/info/documents.html');")

  else
    nil
  end
end

def get_start_price
  at_xpath('//*[contains(text(), "Начальная (максимальная) цена контракта")]/following::*[1]').content.gsub(/[^0-9.]/,'').strip if at_xpath('//*[contains(text(), "Начальная (максимальная) цена контракта")]/following::*[1]')
end

def get_public_at
  if at_xpath('//*[text()="Дата и время публикации извещения (по местному времени организации, осуществляющей закупку)"]/following::*[1]') then
    p public_at_uf = at_xpath('//*[text()="Дата и время публикации извещения (по местному времени организации, осуществляющей закупку)"]/following::*[1]').content
    DateTime.strptime(public_at_uf, '%d.%m.%Y')
  elsif at_xpath('//*[text()="Срок предоставления"]/following::*[1]')
    p public_at_uf = at_xpath('//*[text()="Срок предоставления"]/following::*[1]').content[/с(.*)по/, 1].gsub(' ', '')
    return nil if public_at_uf == ''
    DateTime.strptime(public_at_uf, '%d.%m.%Y')
  else
    nil
  end
end

def get_tender_form
  tender_form_xpath = '//*[text()="Способ определения поставщика (подрядчика, исполнителя)"]/following::*[1]'
  at_xpath(tender_form_xpath).content.strip[0..99]
end

def get_status
  return nil unless get_start_at
  if get_start_at >= DateTime.current then
    'Прием заявок'
  else
    'Завершен'
  end
end

def get_status_key
  return nil unless get_start_at
  if get_start_at >= DateTime.current then
    1
  else
    3
  end
end

def get_customer
  at_xpath('//*[text()="Организация, осуществляющая закупку"]/following::*[1]').content if at_xpath('//*[text()="Организация, осуществляющая закупку"]/following::*[1]')
  at_xpath('//*[text()="Закупку осуществляет"]/following::*[1]').content if at_xpath('//*[text()="Закупку осуществляет"]/following::*[1]')
end

def get_customer_inn
  nil
  #if at_xpath('(//*[text()="ИНН \ КПП"]/following::*)[1]')
    #at_xpath('(//*[text()="ИНН \ КПП"]/following::*)[1]').content
end

def get_okdps
  return nil unless at_xpath('//td[text()="Код по ОКПД"]/ancestor::tbody[1]/tr[3]/td[2]')
  okdp_key = @driver.find_element(xpath: '//td[text()="Код по ОКПД"]/ancestor::tbody[1]/tr[3]/td[2]').text.strip
  log 'взят ключ'
  okdp_title = @driver.find_element(xpath: '//td[text()="Код по ОКПД"]/ancestor::tbody[1]/tr[3]/td[1]').text.strip
  okdps = {}
  okdps[okdp_key] = okdp_title
  log okdps.to_s
  okdps.to_json
end

def get_documents
  nil
end

def get_address
  at_xpath('//*[text()="Почтовый адрес"]/following::*[1]').content if at_xpath('//*[text()="Почтовый адрес"]/following::*[1]')
end

def tender_is_empty?
  true if at_xpath('//b[starts-with(text(),"Общая информация")]') == nil
end

#end