module Sindex

  class XmlDTDError < Exception
  end

  class XmlMalformedError < Exception
    attr_accessor :errors
  end

end
