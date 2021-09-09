require 'spec_helper'

RSpec.describe CCU::Forms::Properties do
  before(:context){ CCU.const_set('CONFIGDIR', 'spec/fixtures/files/6_0') }
  
  let(:profile){ CCU::Profile.new(profile: 'anthro', rectypes: ['collectionobject']) }
  let(:object){ profile.rectypes[0] }
  let(:form){ object.forms['default'] }
  let(:props){ CCU::Forms::Properties.new(form, fieldhash) }
  
  describe '.is_panel' do
    context 'when prop represents a form panel' do
      let(:fieldhash){ form.config['children'][0]['props'] }
      it 'returns true' do
        expect(props.is_panel).to eq(true)
      end
    end
    context 'when prop does not represent a form panel' do
      let(:fieldhash){ form.config['children'][0]['props']['children'][0]['props'] }
      it 'returns false' do
        expect(props.is_panel).to eq(false)
      end
    end
  end

  describe '.is_ext' do
    context 'when prop represents a form panel with same name as a profile extension (anthro collectionobject locality)' do
      let(:fieldhash){ form.config['children'][10]['props'] }
      it 'returns true' do
        expect(props.is_ext).to eq(true)
      end
    end

    context 'when prop does not represent a form panel' do
      let(:fieldhash){ form.config['children'][0]['props']['children'][0]['props'] }
      it 'returns false' do
        expect(props.is_ext).to eq(false)
      end
    end

    context 'when prop is a form panel that is not an extension' do
      let(:fieldhash){ form.config['children'][9]['props'] }
      it 'returns false' do
        expect(props.is_ext).to eq(false)
      end
    end
  end

  describe '.ns' do
    # anthro collectionobject locality
    context 'with panel that is an extension' do
      let(:fieldhash){ form.config['children'][10]['props'] }
      it 'returns correct ns' do
        expect(props.ns).to eq('ns2:collectionobjects_common')
      end
    end

    context 'with child of panel that is an extension' do
      let(:fieldhash){ form.config['children'][10]['props'] }
      it 'returns correct ns' do
        field_props = props
        child_hash = fieldhash['children']['props']
        child_props = CCU::Forms::Properties.new(form, child_hash, field_props)
        expect(child_props.ns).to eq('ns2:collectionobjects_anthro')
      end
    end
  end
end
