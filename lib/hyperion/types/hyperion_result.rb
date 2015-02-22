class HyperionResult
  attr_reader :route, :status, :code, :body

  module Status
    include Enum
    SUCCESS = 'success'
    TIMED_OUT = 'timed_out'
    NO_RESPONSE = 'no_response'
    BAD_ROUTE = 'bad_route'
    CLIENT_ERROR = 'client_error'
    SERVER_ERROR = 'server_error'
    CHECK_CODE = 'check_code'
  end

  # @param status [HyperionResult::Status]
  # @param code [Integer] the HTTP response code
  # @param body [Object, Hash<String,Object>] the deserialized response body.
  #   The type is determined by the content-type.
  #   JSON is deserialized to a Hash<String, Object>
  # Contract ValidEnum[Status], Or[And[Integer, Pos], nil], Any => Any
  def initialize(route, status, code=nil, body=nil)
    @route, @status, @code, @body = route, status, code, body
  end

  def to_s
    case status
      when Status::SUCCESS
        "Success: #{route.to_s}"
      when Status::TIMED_OUT
        "Timed out: #{route.to_s}"
      when Status::NO_RESPONSE
        "No response: #{route.to_s}"
      else
        "HTTP #{code}: #{route.to_s}"
    end
  end
end