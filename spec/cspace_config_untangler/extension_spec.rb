require 'spec_helper'

RSpec.describe CCU::Extension do
  before(:all) do
    CCU.const_set('CONFIGDIR', 'spec/fixtures/files/6_0')
    @core_profile = CCU::Profile.new(profile: 'core', rectypes: ['collectionobject'])
    @anthro_profile = CCU::Profile.new(profile: 'anthro', rectypes: ['collectionobject', 'claim'])
  end
  
  describe '.new' do
    it 'creates CCU::Extension object' do
      expect(CCU::Extension.new(@core_profile, 'address')).to be_instance_of(CCU::Extension)
    end

    it 'determines extension type: generic' do
      expect(CCU::Extension.new(@core_profile, 'address').type).to eq('generic')
    end
    it 'determines extension type: rectype specific' do
      expect(CCU::Extension.new(@anthro_profile, 'nagpra').type).to eq('rectype specific')
    end
    it 'determines extension type: subrecord' do
      expect(CCU::Extension.new(@anthro_profile, 'contact').type).to eq('subrecord')
    end
    
    it 'sets empty rectypes array when type: generic' do
      expect(CCU::Extension.new(@core_profile, 'address').rectypes).to eq([])
    end
    it 'records affected rectypes when type: rectype specific' do
      expect(CCU::Extension.new(@anthro_profile, 'nagpra').rectypes).to eq(%w[claim collectionobject])
    end
  end

end #RSpec
