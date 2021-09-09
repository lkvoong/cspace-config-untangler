require 'spec_helper'

RSpec.describe CCU::Vocabulary do
  let(:vocabulary){ CCU::Vocabulary.new(str) }
  let(:str){ 'relationtypetype' }

  describe '#name' do
    let(:result){ vocabulary.name }
    it 'returns name' do
      expect(result).to eq(str)
    end
  end

  describe '#type' do
    let(:result){ vocabulary.type }
    it 'returns type' do
      expect(result).to eq('vocabulary')
    end
  end

  describe '#subtype' do
    let(:result){ vocabulary.subtype }
    it 'returns subtype' do
      expect(result).to eq(str)
    end
  end  
end
