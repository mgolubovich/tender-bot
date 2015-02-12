@source_name = 'zakupki'
@group = '223'

def get_last_ids
	log 'Открываем основной список zakazrf'
	get('http://zakupki.gov.ru/223/purchase/public/notification/search.html?purchaseStages=PLACEMENT_COMPLETE&purchaseStages=APPLICATION_FILING&purchaseStages=COMMISSION_ACTIVITIES&activeTab=0')
	info 'Берем верхний id zakupki'
	last_id = @driver.find_element(xpath:'//a[contains(@href,"common-info.html?noticeId")]').attribute('href')[40..-1].gsub(/\D/, '')
	info("Получен id #{last_id}")
	link = 'http://zakupki.gov.ru/223/purchase/public/purchase/info/common-info.html?noticeId='
	[[last_id.to_i, link]]
end

def get_title
	at_xpath('//*[text()="Наименование закупки"]/following::*[1]').content.gsub(/\t/, '').gsub(/\n/, '').strip
end

def get_code
  at_xpath('//*[text()="Номер извещения"]/following::*[1]').content.strip
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
  @driver.execute_script("navigateFromTab('/purchase/info/lot-list.html');")
  begin
    return nil if @driver.find_element(xpath: '/html/body/div[3]/div/div/div[2]/div/div/div/table/tbody/tr/td[4]').text.length > 40
    @driver.find_element(xpath: '/html/body/div[3]/div/div/div[2]/div/div/div/table/tbody/tr/td[4]').text.gsub(/[^0-9,]/, '').gsub(',', '.').to_f
  rescue
    nil
  end
end

def get_public_at
  if at_xpath('//*[text()="Дата публикации извещения"]/following::*[1]') then
    p public_at_uf = at_xpath('//*[text()="Дата публикации извещения"]/following::*[1]').content
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
  tender_form_xpath = '//*[text()="Способ размещения закупки"]/following::*[1]'
  at_xpath(tender_form_xpath).content.strip[0..99]
end

def get_status
  nil
end

def get_status_key
  nil
end

def get_customer
  at_xpath('//*[text()="Заказчик"]/following::a[1]').content
end

def get_customer_inn
  nil
#if at_xpath('(//*[text()="ИНН \ КПП"]/following::*)[1]')
  #at_xpath('(//*[text()="ИНН \ КПП"]/following::*)[1]').content
end

def get_okdps
  @driver.execute_script("navigateFromTab('/purchase/info/lot-list.html');")
  info 'перешел на лоты'
  okdp_key = @driver.find_element(xpath: '/html/body/div[3]/div/div/div[2]/div/div/div/table/tbody/tr/td[5]').text.strip[0..6]
  info 'взят ключ'
  okdp_title = @driver.find_element(xpath: '/html/body/div[3]/div/div/div[2]/div/div/div/table/tbody/tr/td[5]').text.strip[7..-1]
  okdps = {}
  okdps[okdp_key] = okdp_title
  info okdps.to_s
  okdps.to_json
end

def get_documents
  nil
end

def get_address
  at_xpath('//*[text()="Почтовый адрес"]/following::*[1]').content
end

def tender_is_empty?
  true if at_xpath('//*[text()="Наименование закупки"]/following::*[1]') == nil
end
