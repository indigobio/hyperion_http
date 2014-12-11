require 'spec_helper'

class Hyperion
  describe Formats do
    include Formats

    describe '#write' do
      it 'writes json' do
        expect(write({'a' => 1}, :json)).to be_json_eql '{"a":1}'
      end
    end

    describe '#read' do
      it 'read json' do
        expect(read('{"a":1}', :json)).to eql({'a' => 1})
      end
    end
  end
end