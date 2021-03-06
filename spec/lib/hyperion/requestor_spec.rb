require 'ostruct'
require 'hyperion_test'

# TODO: rename this file to something appropriate. superion became Hyperion::Requestor

class ClassWithHyperionHandlers
  include Hyperion::Requestor

  def initialize(predetermined_result)
    @predetermined_result = predetermined_result
  end

  def hyperion_handler(result)
    result.when(->{true}) { @predetermined_result }
  end
end

describe Hyperion::Requestor do
  include Hyperion::Requestor

  def arrange(method, response)
    create_route(method)
    fake_route(@route) do |request|
      @request = request
      response
    end
  end

  def arrange_timeout(method)
    create_route(method)
    fake_route(@route) { sleep 2 }
  end

  def create_route(method)
    @route = RestRoute.new(method, 'http://indigo.com/things',
                           ResponseDescriptor.new('thing', 1, :json),
                           PayloadDescriptor.new(:json))
  end

  def assert_result(expected_result)
    expect(@result).to eql expected_result
  end

  it 'makes requests' do
    arrange(:get, {'a' => 'b'})
    @result = request(@route)
    assert_result({'a' => 'b'})
  end

  it 'makes requests with additional headers' do 
    headers = {'X-my-header' => 'value'}
    arrange(:get, {'a' => 'b'})
    expect(Hyperion).to receive(:request).with(@route, body: nil, additional_headers: headers, timeout: 0)
    @result = request(@route, headers: headers)
  end

  it 'makes requests with payload bodies' do
    arrange(:put, {'a' => 'b'})
    @result = request(@route, body: {'the' => 'body'})
    assert_result({'a' => 'b'})
    expect(@request.body).to eql({'the' => 'body'})
  end

  it 'makes requests with a timeout' do
    arrange_timeout(:get)
    error = 'oops: time out'
    handlers = {HyperionStatus::TIMED_OUT => proc { raise error }}
    expect { request(@route, timeout: 1, also_handle: handlers) }.to raise_error error
  end

  it 'renders the response with the render proc' do
    arrange(:get, {'x' => 1, 'y' => 2})
    @result = request(@route, render: OpenStruct.method(:new))
    assert_result(OpenStruct.new(x: 1, y: 2))
  end

  context 'when a `hyperion_handlers` method is defined' do
    it 'takes precedence over the core handlers' do
      arrange(:get, [200, {}, nil])
      hyperion_handler_result = double
      route = @route
      @result = ClassWithHyperionHandlers.new(hyperion_handler_result).instance_eval do
        request(route)
      end
      assert_result(hyperion_handler_result)
    end
  end

  context 'when request handlers are provided' do
    it 'earlier handlers take precedence over later ones' do
      arrange(:get, [333, {}, nil])
      custom_handlers = {
          proc {|x| x.code.odd?} => 'odd',
          333 => 'got 333'
      }

      @result = request(@route, also_handle: custom_handlers)
      assert_result('odd')
    end
  end

  context 'when given a block' do
    before :each do
      arrange(:get, {'x' => 1, 'y' => 2})
      @result = request(@route, render: OpenStruct.method(:new)) do |point|
        @point = point
        :block_result
      end
    end
    it 'passes the rendered response to the block' do
      expect(@point).to be_an OpenStruct
    end
    it "returns the block's return value" do
      expect(@result).to eql :block_result
    end
  end

  it 'rejects invalid arguments' do
    arrange(:get, {'a' => 'b'})
    expect{request(:foo)}.to raise_error 'You passed me :foo, which is not a RestRoute'
    expect{request(@route, :foo)}.to raise_error 'You passed me :foo, which is not an options hash'
  end

  context 'by default' do
    context 'on a 400-level response' do

      def example(opts)
        code = ((400..499).to_a - [404]).sample
        arrange(:get, [code, {}, opts[:response]])
        expect{request(@route)}.to raise_error HyperionError, opts[:error]
      end

      context 'when the response is a properly-formed error message' do
        it 'raises an error with the response message' do
          example response: '{"message":"oops"}',
                  error: 'oops'
        end
      end
      context 'when the response is not a properly-formed error message' do
        it 'raises an error containing the route and the dumped response' do
          example response: '{"huh":"wut"}',
                  error: 'The request failed: GET http://indigo.com/things: {"huh"=>"wut"}'
        end
      end
      context 'when there is no response' do
        it 'raises an generic error message containing the route' do
          example response: nil,
                  error: 'The request failed: GET http://indigo.com/things'
        end
      end
    end

    context 'on a 404 response' do
      it 'raises an error' do
        arrange(:get, [404, {}, nil])
        expect{request(@route)}.to raise_error HyperionError, "Got HTTP 404 for #{@route}. Is the route implemented?"
      end
    end

    context 'on a 500-level response' do
      it 'raises an error' do
        arrange(:get, [(500..599).to_a.sample, {}, {'a' => 1}])
        expect{request(@route)}.to raise_error HyperionError, "#{@route}\n{\"a\"=>1}"
      end
    end

    context 'when a result falls through' do
      it 'raises an error' do
        arrange(:get, [(300..399).to_a.sample, {}, nil])
        expect{request(@route)}.to raise_error HyperionError, /response did not match any conditions/
      end
    end
  end
end
