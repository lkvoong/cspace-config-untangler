require 'spec_helper'

RSpec.describe CCU::Authority do
  let(:authority){ CCU::Authority.new(str) }
  let(:str){ 'concept/associated' }

  describe '#name' do
    let(:result){ authority.name }
    it 'returns name' do
      expect(result).to eq(str)
    end
  end

  describe '#type' do
    let(:result){ authority.type }
    it 'returns type' do
      expect(result).to eq('concept')
    end
  end

  describe '#subtype' do
    let(:result){ authority.subtype }
    it 'returns subtype' do
      expect(result).to eq('associated')
    end
  end  
end
