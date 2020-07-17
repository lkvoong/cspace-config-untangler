require 'spec_helper'

RSpec.describe CCU::FieldMap do
  before do
    stub_const('CCU::CONFIGDIR', 'spec/fixtures/files/6_0')
  end

  let(:core_profile) { CCU::Profile.new('core', rectypes: ['collectionobject', 'concept'], structured_date_treatment: :collapse) }
  let(:fields) { core_profile.fields }
  let(:contentConcept) { fields.select{ |f| f.rectype.name == 'collectionobject' && f.name == 'contentConcept' }[0] }
  let(:assocActivity) { fields.select{ |f| f.rectype.name == 'collectionobject' && f.name == 'assocActivity' }[0] }
  let(:assocStructuredDateGroup) { fields.select{ |f| f.rectype.name == 'collectionobject' && f.name == 'assocStructuredDateGroup' }[0] }
  let(:ageUnit) { fields.select{ |f| f.rectype.name == 'collectionobject' && f.name == 'ageUnit' }[0] }
  let(:ageQualifier) { fields.select{ |f| f.rectype.name == 'collectionobject' && f.name == 'ageQualifier' }[0] }
  let(:termPrefForLang) { fields.select{ |f| f.rectype.name == 'concept' && f.name == 'termPrefForLang' }[0] }

  let(:anthro_profile) { CCU::Profile.new('anthro', rectypes: ['collectionobject'], structured_date_treatment: :collapse) }
  let(:afields) { anthro_profile.fields }
  let(:bupper) { afields.select{ |f| f.rectype.name == 'collectionobject' && f.name == 'behrensmeyerUpper' }[0] }

  let(:botgarden_profile) { CCU::Profile.new('botgarden', rectypes: ['collectionobject'], structured_date_treatment: :collapse) }
  let(:bg_fields) { botgarden_profile.fields }
  let(:fruitsDec) { bg_fields.select{ |f| f.rectype.name == 'collectionobject' && f.name == 'fruitsDec' }[0] }
  let(:accessionUseType) { bg_fields.select{ |f| f.rectype.name == 'collectionobject' && f.name == 'accessionUseType' }[0] }
  
  # ["authority: concept/associated", "authority: concept/material"]
  describe FieldMapping do
    context 'core profile' do
      context 'contentConcept' do
        let(:mappings) { FieldMapper.new(field: contentConcept).mappings }
        it 'mappings have source_type = authority' do
          result = mappings.map{ |m| m.source_type }
          expect(result).to eq(%w[authority authority])
        end
        it 'mappings datacolumns = contentConceptAssociated contentConceptMaterial' do
          result = mappings.map{ |m| m.datacolumn }.sort
            expect(result).to eq(%w[contentConceptAssociated contentConceptMaterial])
        end
      end
    end
  end
  
  describe FieldMapper do
    context 'when no field source' do
      let(:result) { FieldMapper.new(field: assocActivity) }
      describe '#get_data_columns' do
        it 'column is the same as field name' do
          expect(result.hash.map{ |src, h| h[:column_name] }).to eq(['assocActivity'])
        end
      end
      describe '#mappings' do
        it 'returns 1 mapping' do
          expect(result.mappings.size).to eq(1)
        end
      end
      describe '#source_type' do
        it 'returns na' do
          expect(result.source_type).to eq('na')
        end
      end
    end

    context 'when field source is option list' do
      let(:result) { FieldMapper.new(field: ageUnit) }
      describe '#get_data_columns' do
        it 'column is the same as field name' do
          expect(result.hash.map{ |src, h| h[:column_name] }).to eq(['ageUnit'])
        end
      end
      describe '#mappings' do
        it 'returns 1 mapping' do
          expect(result.mappings.size).to eq(1)
        end
      end
      describe '#source_type' do
        it 'returns optionlist' do
          expect(result.source_type).to eq('optionlist')
        end
      end
    end

    context 'when field source is vocabulary' do
      context 'we assume only one vocabulary source per field' do
        let(:result) { FieldMapper.new(field: ageQualifier) }
        describe '#get_data_columns' do
          it 'column is the same as field name' do
            expect(result.hash.map{ |src, h| h[:column_name] }).to eq(['ageQualifier'])
          end
        end
        describe '#mappings' do
          it 'returns 1 mapping' do
            expect(result.mappings.size).to eq(1)
          end
        end
        describe '#get_transforms' do
          it 'creates transform hash as expected' do
            rh = result.hash.map{ |src, h| h[:transforms] }
            expected = [
              { vocabulary: 'agequalifier' }
            ]
            expect(rh).to eq(expected)
          end
        end
        describe '#source_type' do
          it 'returns vocabulary' do
            expect(result.source_type).to eq('vocabulary')
          end
        end
      end
    end

    context 'when field source is authority' do
      context 'and two authorities may be used' do
        let(:result) { FieldMapper.new(field: contentConcept) }
        describe '#get_data_columns' do
          it 'merges in column name hash as expected' do
            expect(result.hash.map{ |src, h| h[:column_name] }).to eq(%w[contentConceptAssociated contentConceptMaterial])
          end
        end
        describe '#mappings' do
          it 'returns 2 mappings' do
            expect(result.mappings.size).to eq(2)
          end
        end
        describe '#get_transforms' do
          it 'creates transform hashes as expected' do
            rh = result.hash.map{ |src, h| h[:transforms] }
            expected = [
              { authority:  %w[conceptauthorities concept] },
              { authority:  %w[conceptauthorities material_ca] }
            ]
            expect(rh).to eq(expected)
          end
        end
        describe '#source_type' do
          it 'returns authority' do
            expect(result.source_type).to eq('authority')
          end
        end
      end
    end

    context 'when stuctured date field' do
      let(:result) { FieldMapper.new(field: assocStructuredDateGroup) }
      describe '#get_data_columns' do
        it 'merges in column name hash as expected' do
          expect(result.hash.map{ |src, h| h[:column_name] }).to eq(%w[assocStructuredDateGroup])
        end
      end
      describe '#mappings' do
        it 'returns 1 mappings' do
          expect(result.mappings.size).to eq(1)
        end
      end
      describe '#get_transforms' do
        it 'creates transform hashes as expected' do
          rh = result.hash.map{ |src, h| h[:transforms] }
          expected = [
            {},
          ]
          expect(rh).to eq(expected)
        end
      end
      describe '#source_type' do
        it 'returns authority' do
          expect(result.source_type).to eq('na')
        end
      end
    end

    context 'when boolean field' do
      let(:result) { FieldMapper.new(field: termPrefForLang) }
      describe '#get_transforms' do
        it 'creates transform hashes as expected' do
          rh = result.hash.map{ |src, h| h[:transforms] }
          expected = [
            { special: %w[boolean] },
          ]
          expect(rh).to eq(expected)
        end
      end
    end

    context 'when behrensmeyer field' do
      let(:result) { FieldMapper.new(field: bupper) }
      describe '#get_transforms' do
        it 'creates transform hashes as expected' do
          rh = result.hash.map{ |src, h| h[:transforms] }
          expected = [
            { special: %w[behrensmeyer_translate],
              vocabulary: 'behrensmeyer' },
          ]
          expect(rh).to eq(expected)
        end
      end
    end
  end

  describe AuthorityConfigLookup do
    context 'when given profile=core and authority=concept/material' do
      let(:result) { AuthorityConfigLookup.new(profile: contentConcept.profile,
                                               authority: 'authority: concept/material').result }
      it 'returns [conceptauthorities, material_ca]' do
        expect(result).to eq(%w[conceptauthorities material_ca])
      end
    end
    context 'when given profile=core and authority=person/ulan' do
      let(:result) { AuthorityConfigLookup.new(profile: contentConcept.profile,
                                               authority: 'authority: person/ulan').result }
      it 'returns [personauthorities, ulan_pa]' do
        expect(result).to eq(%w[personauthorities ulan_pa])
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
              .map{ |k, v| v }
            expect(result).to eq(%w[nameOne nameTwo])
          end
        end
        context 'and one is person and one is organization' do
          it 'names columns using authority types' do
            fieldname = 'name'
            sources = ['authority: person/local', 'authority: organization/local']
            result = DataColumnNamer.new(fieldname: fieldname, sources: sources).result
              .map{ |k, v| v }
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
            .map{ |k, v| v }
          expect(result).to eq(%w[namePersonLocal nameOrganizationLocal namePersonUlan nameOrganizationUlan])
        end
      end
      context 'and person/ulan, person/local, and org/local may be used' do
          it 'names columns using authority types and subtypes for person, type only for org' do
            fieldname = 'name'
            sources = ['authority: person/local', 'authority: organization/local',
                       'authority: person/ulan']
            result = DataColumnNamer.new(fieldname: fieldname, sources: sources).result
              .map{ |k, v| v }
            expect(result).to eq(%w[namePersonLocal nameOrganization namePersonUlan])
          end
      end
    end
  end
  
  
end #RSpec
