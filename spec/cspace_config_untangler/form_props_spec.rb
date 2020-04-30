require 'spec_helper'

RSpec.describe CCU::FormProps do
  before do
    stub_const('CCU::CONFIGDIR', 'spec/fixtures/files/5_2')
  end

  let(:core_profile) { CCU::Profile.new('core') }
  let(:anthro_profile) { CCU::Profile.new('anthro') }
  let(:anthro_co) { CCU::RecordType.new(anthro_profile, 'collectionobject') }
  let(:anthro_default) { anthro_co.forms['default'] }
  
  describe '.is_panel' do
    it 'true if prop represents a form panel' do
      h = anthro_default.config['children'][0]['props']
      fp = CCU::FormProps.new(anthro_default, h)
      expect(fp.is_panel).to eq(true)
    end
    it 'false if prop does not represent a form panel' do
      h = anthro_default.config['children'][0]['props']['children'][0]['props']
      fp = CCU::FormProps.new(anthro_default, h)
      expect(fp.is_panel).to eq(false)
    end
  end

  describe '.is_ext' do
    # anthro collectionobject locality
    it 'true if prop represents a form panel with same name as a profile extension' do
      h = anthro_default.config['children'][10]['props']
      fp = CCU::FormProps.new(anthro_default, h)
      expect(fp.is_ext).to eq(true)
    end
    it 'false if prop does not represent a form panel' do
      h = anthro_default.config['children'][0]['props']['children'][0]['props']
      fp = CCU::FormProps.new(anthro_default, h)
      expect(fp.is_ext).to eq(false)
    end
    it 'false if prop is a form panel that is not an extension' do
      h = anthro_default.config['children'][9]['props']
      fp = CCU::FormProps.new(anthro_default, h)
      expect(fp.is_ext).to eq(false)
    end
  end

    describe '.ns' do
    # anthro collectionobject locality
    it 'returns correct ns for a panel that is an extension' do
      h = anthro_default.config['children'][10]['props']
      fp = CCU::FormProps.new(anthro_default, h)
      expect(fp.ns).to eq('ext.locality')
    end
    it 'returns correct ns for child of panel that is an extension' do
      h = anthro_default.config['children'][10]['props']
      fp = CCU::FormProps.new(anthro_default, h)
      hh = h['children']['props']
      fpp = CCU::FormProps.new(anthro_default, hh, fp)
      expect(fp.ns).to eq('ext.locality')
    end
  end

end #RSpec
