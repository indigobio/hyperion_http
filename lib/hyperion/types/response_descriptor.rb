require 'hyperion/headers'

class ResponseDescriptor
  # Describes properties of an acceptable response

  include Hyperion::Headers

  attr_reader :type, :version, :format

  # @param type [String]
  # @param version [Integer]
  # @param format [Symbol] :json
  def initialize(type, version, format)
    @type, @version, @format = type, version, format
  end

  def as_json(*_args)
    {
        'type' => type,
        'version' => version,
        'format' => format.to_s
    }
  end

  def to_s
    short_mimetype(self)
  end
end

