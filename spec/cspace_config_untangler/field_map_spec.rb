require 'spec_helper'

RSpec.describe CCU::FieldMap do
  before do
    stub_const('CCU::CONFIGDIR', 'spec/fixtures/files/6_0')
  end

  let(:core_profile) { CCU::Profile.new('core', rectypes: ['collectionobject']) }
  let(:co_fields) { core_profile.fields }
  let(:contentConcept) { co_fields.select{ |f| f.name == 'contentConcept' }[0] }
  let(:assocActivity) { co_fields.select{ |f| f.name == 'assocActivity' }[0] }  

  # ["authority: concept/associated", "authority: concept/material"]
  describe FieldMapper do
    context 'when no field source' do
      let(:result) { FieldMapper.new(field: assocActivity) }
      describe '#columns' do
        it 'column is the same as field name' do
          expect(result.columns).to eq(['assocActivity'])
        end
      end
    end
    
    context 'when field source is authority' do
      context 'and two authorities may be used' do
        let(:result) { FieldMapper.new(field: contentConcept) }
        describe '#columns' do
          it 'merges in column name hash as expected' do
            
          end
        end
        describe '#mappings' do
          it 'returns 2 mappings' do
            expect(result.mappings.size).to eq(2)
          end
        end
      end
    end
  end

  describe DataColumnNamer do
    context 'when source is authority' do
      context 'and two authorities may be used' do
        context 'and both are concept authorities' do
          it 'names columns using authority subtypes' do
            fieldname = 'name'
            sources = ['authority: concept/one', 'authority: concept/two']
            result = DataColumnNamer.new(fieldname: fieldname, sources: sources).result
              .map{ |k, v| v[:column_name] }
            expect(result).to eq(%w[nameOne nameTwo])
          end
        end
        context 'and one is person and one is organization' do
          it 'names columns using authority types' do
            fieldname = 'name'
            sources = ['authority: person/local', 'authority: organization/local']
            result = DataColumnNamer.new(fieldname: fieldname, sources: sources).result
              .map{ |k, v| v[:column_name] }
            expect(result).to eq(%w[namePerson nameOrganization])
          end
        end
      end
      context 'and person/ulan, person/local, org/ulan, and org/local may be used' do
        it 'names all columns using authority types and subtypes' do
          fieldname = 'name'
          sources = ['authority: person/local', 'authority: organization/local',
                     'authority: person/ulan', 'authority: organization/ulan']
          result = DataColumnNamer.new(fieldname: fieldname, sources: sources).result
            .map{ |k, v| v[:column_name] }
          expect(result).to eq(%w[namePersonLocal nameOrganizationLocal namePersonUlan nameOrganizationUlan])
        end
      end
      context 'and person/ulan, person/local, and org/local may be used' do
          it 'names columns using authority types and subtypes for person, type only for org' do
            fieldname = 'name'
            sources = ['authority: person/local', 'authority: organization/local',
                       'authority: person/ulan']
            result = DataColumnNamer.new(fieldname: fieldname, sources: sources).result
              .map{ |k, v| v[:column_name] }
            expect(result).to eq(%w[namePersonLocal nameOrganization namePersonUlan])
          end
      end
    end
  end
  
  
end #RSpec
