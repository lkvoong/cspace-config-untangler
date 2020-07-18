require 'spec_helper'

RSpec.describe CCU::RecordType do

  before(:all) do
    CCU.const_set('CONFIGDIR', 'spec/fixtures/files/6_0')
    @core_profile = CCU::Profile.new(profile: 'core', rectypes: ['collectionobject'])
    @anthro_profile = CCU::Profile.new(profile: 'anthro', rectypes: ['collectionobject'])
    @bg_profile = CCU::Profile.new(profile: 'botgarden', rectypes: ['collectionobject'])
    @core_co = @core_profile.rectypes[0]
    @anthro_co = @anthro_profile.rectypes[0]
    @bg_co = @bg_profile.rectypes[0]
  end
  describe '.new' do
    it 'creates CCU::RecordType object' do
      expect(@core_co).to be_instance_of(CCU::RecordType)
    end
  end

  describe '.panels' do
    it 'returns array' do
      expect(@anthro_co.panels).to be_instance_of(Array)
    end
    it 'includes all panel names for rectype' do
      p = ['id', 'desc', 'content', 'textInscript', 'nonTextInscript', 'prod', 'hist', 'assoc', 'owner',
           'viewer', 'reference', 'collect', 'hierarchy', 'bio', 'commingledRemains', 'locality',
           'culturalCare', 'georefDetail', 'nagpraCompliance'].sort
      expect(@anthro_co.panels.sort).to eq(p)
    end
  end

  describe '.input_tables' do
    it 'returns hash' do
      expect(@anthro_co.input_tables).to be_instance_of(Hash)
    end
    it 'keys are the panel names for rectype' do
      p = ['age', 'assocEvent', 'ownershipExchange', 'behrensmeyer', 'depth', 'elevation',
           'distanceAboveSurface', 'nagpraReportFiled', 'taxonName', 'taxonIdent', 'taxonReference'].sort
      expect(@anthro_co.input_tables.keys.sort).to eq(p)
    end
  end

  describe '.forms' do
    it 'returns hash' do
        expect(@anthro_co.forms).to be_instance_of(Hash)
      end
      it 'hash keys are the form names' do
        a = %w[default inventory photo].sort
        expect(@anthro_co.forms.keys.sort).to eq(a)
      end
      
      it 'hash values are CCU::Form objects' do
        expect(@anthro_co.forms['default']).to be_instance_of(CCU::Form)
      end
    end
end #RSpec
