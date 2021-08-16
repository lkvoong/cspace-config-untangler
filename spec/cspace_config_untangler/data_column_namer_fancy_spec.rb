require 'spec_helper'

require 'cspace_config_untangler/field_map/data_column_namer_fancy'

RSpec.describe DataColumnNamerFancy do
  let(:fieldname){ 'name' }
  let(:xform_sources){ sources.map{ |source| AuthoritySource.new(source) } }
  let(:result){ DataColumnNamerFancy.new(fieldname: fieldname, sources: xform_sources).result.values }
  
  context 'when source is authority' do
    context 'and two authorities may be used' do
      context 'and both are concept authorities' do
        let(:sources){ ['authority: concept/one', 'authority: concept/two'] }
        it 'names columns using authority subtypes' do
          expect(result).to eq(%w[nameOne nameTwo])
        end
      end
      
      context 'and one is person and one is organization' do
        let(:sources){ ['authority: person/local', 'authority: organization/local'] }
        it 'names columns using authority types' do
          expect(result).to eq(%w[namePerson nameOrganization])
        end
      end
    end
    
    context 'and person/ulan, person/local, org/ulan, and org/local may be used' do
      let(:sources) do
        ['authority: person/local', 'authority: organization/local',
         'authority: person/ulan', 'authority: organization/ulan']
      end
      it 'names all columns using authority types and subtypes' do
        expect(result).to eq(%w[namePersonLocal nameOrganizationLocal namePersonUlan nameOrganizationUlan])
      end
    end
    
    context 'and person/ulan, person/local, and org/local may be used' do
      let(:sources){ ['authority: person/local', 'authority: organization/local', 'authority: person/ulan'] }
      it 'names columns using authority types and subtypes for person, type only for org' do
        expect(result).to eq(%w[namePersonLocal nameOrganization namePersonUlan])
      end
    end
  end
end
