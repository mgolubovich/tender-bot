module Dsl
  def log msg
    @logger.info msg
    puts Time.new.strftime"%Y-%m-%d_%H-%M-%S" + '  ' + msg
  end

  def field(name, &block)
    @field_value = nil
    log "Start to take field #{name}"
    result = yield
    if field_not_empty
      @fields[name] = @field_value
      log "Collected #{@field_value}" 
    elsif !field_not_empty and result
      log "Value preseted to #{result}"
      @fields[name] = result
    else
      log "Got empty value"
    end
    @field_value = nil
  end

  def field_not_empty
    if @field_value
      if @field_value.kind_of?(Array)
        if @field_value.empty?
          true
        else
          false
        end
      elsif @field_value.kind_of?(Nokogiri::XML::NodeSet) or @field_value.kind_of?(Nokogiri::XML::Node)
        content
        true
      else
        true
      end
    else
      false
    end
  end

  def at_css(selector, attribute = nil)
    @field_value = @doc.at_css(selector).content if @doc.at_css(selector)
    @field_value = @field_value[attribute] if attribute and @field_value
  end

  def css(selector, attribute = nil)
    @field_value = @doc.css(selector) if @doc.css(selector)
  end

  def at_xpath(selector, attribute = nil)
    @field_value = @doc.at_xpath(selector) if @doc.at_xpath(selector)
  end

  def xpath(selector, attribute = nil)
    @field_value = @doc.xpath(selector) if @doc.xpath(selector)
  end

  def attribute
    if @field_value.kind_of?(Array)
      @field_value = @field_value.map { |f| f[attribute].strip if f[attribute] } if @field_value
    else
      @field_value = @field_value[attribute] if @field_value  
    end
  end

  def content
    if @field_value.kind_of?(Array)
      @field_value = @field_value.map { |f| f.content.strip if f.content } if @field_value
    else
      @field_value = @field_value.content.strip if @field_value  
    end
  end

  def gsub(regexp, replacement)
    @field_value.gsub(regexp, replacement) if @field_value and @field_value.kind_of? String
  end

end