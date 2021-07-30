require 'spec_helper'

RSpec.describe CCU::FieldMap do
  before(:all) do
    CCU.const_set('CONFIGDIR', 'spec/fixtures/files/6_0')
  @core_profile = CCU::Profile.new(profile: 'core', rectypes: ['collectionobject', 'concept', 'movement'], structured_date_treatment: :collapse)
  @fields = @core_profile.fields
  @currentLocation = @fields.select{ |f| f.rectype.name == 'movement' && f.name == 'currentLocation' }[0]
  @contentConcept = @fields.select{ |f| f.rectype.name == 'collectionobject' && f.name == 'contentConcept' }[0]
  @assocActivity = @fields.select{ |f| f.rectype.name == 'collectionobject' && f.name == 'assocActivity' }[0]
  @assocStructuredDateGroup = @fields.select{ |f| f.rectype.name == 'collectionobject' && f.name == 'assocStructuredDateGroup' }[0]
  @ageUnit = @fields.select{ |f| f.rectype.name == 'collectionobject' && f.name == 'ageUnit' }[0]
  @ageQualifier = @fields.select{ |f| f.rectype.name == 'collectionobject' && f.name == 'ageQualifier' }[0]
  @termPrefForLang = @fields.select{ |f| f.rectype.name == 'concept' && f.name == 'termPrefForLang' }[0]

  @anthro_profile = CCU::Profile.new(profile: 'anthro', rectypes: ['collectionobject'], structured_date_treatment: :collapse)
  @afields = @anthro_profile.fields
  @bupper = @afields.select{ |f| f.rectype.name == 'collectionobject' && f.name == 'behrensmeyerUpper' }[0]

  @botgarden_profile = CCU::Profile.new(profile: 'botgarden', rectypes: ['collectionobject'], structured_date_treatment: :collapse)
  @bg_fields = @botgarden_profile.fields
  @fruitsDec = @bg_fields.select{ |f| f.rectype.name == 'collectionobject' && f.name == 'fruitsDec' }[0]
  @accessionUseType = @bg_fields.select{ |f| f.rectype.name == 'collectionobject' && f.name == 'accessionUseType' }[0]
  end
  
  # ["authority: concept/associated", "authority: concept/material"]
  describe FieldMapping do
    context 'core profile' do
      context 'contentConcept' do
        let(:mappings) { FieldMapper.new(field: @contentConcept).mappings }
        it 'mappings have source_type = authority' do
          result = mappings.map{ |m| m.source_type }
          expect(result).to eq(%w[authority authority authority])
        end
        it 'mappings datacolumns = contentConceptConceptAssociated contentConceptConceptMaterial' do
          result = mappings.map{ |m| m.datacolumn }.sort
            expect(result).to eq(%w[contentConceptConceptAssociated contentConceptConceptMaterial contentConceptRefname])
        end

        describe '.to_h' do
          it 'gets all attributes' do
            hash = mappings[0].to_h
            expect(hash.key?(:datacolumn)).to be true
          end
        end
      end

      context 'currentLocation' do
        let(:mappings) { FieldMapper.new(field: @currentLocation).mappings }
        it 'mappings have source_type = authority' do
          result = mappings.map{ |m| m.source_type }
          expect(result).to eq(%w[authority authority authority authority])
        end
        it 'mappings datacolumns = currentLocationLocationLocal currentLocationLocationOffsite currentLocationOrganizationLocal currentLocationRefname' do
          result = mappings.map{ |m| m.datacolumn }.sort
          expect(result).to eq(%w[currentLocationLocationLocal currentLocationLocationOffsite currentLocationOrganizationLocal currentLocationRefname])
        end

        describe '.to_h' do
          it 'gets all attributes' do
            hash = mappings[0].to_h
            expect(hash.key?(:datacolumn)).to be true
          end
        end
      end
    end
  end
  
  describe FieldMapper do
    context 'when no field source' do
      let(:result) { FieldMapper.new(field: @assocActivity) }
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
      let(:result) { FieldMapper.new(field: @ageUnit) }
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
        let(:result) { FieldMapper.new(field: @ageQualifier) }
        describe '#get_data_columns' do
          it 'column is the same as field name' do
            expect(result.hash.map{ |src, h| h[:column_name] }).to eq(['ageQualifier', 'ageQualifierRefname'])
          end
        end
        describe '#mappings' do
          it 'returns 2 mappings' do
            expect(result.mappings.size).to eq(2)
          end
        end
        describe '#get_transforms' do
          it 'creates transform hash as expected' do
            rh = result.hash.map{ |src, h| h[:transforms] }
            expected = [
              { vocabulary: 'agequalifier' },
              {}
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
        let(:result) { FieldMapper.new(field: @contentConcept) }
        describe '#get_data_columns' do
          it 'merges in column name hash as expected' do
            expect(result.hash.map{ |src, h| h[:column_name] }).to eq(%w[contentConceptConceptAssociated contentConceptConceptMaterial contentConceptRefname])
          end
        end
        describe '#mappings' do
          it 'returns 3 mappings' do
            expect(result.mappings.size).to eq(3)
          end
        end
        describe '#get_transforms' do
          it 'creates transform hashes as expected' do
            rh = result.hash.map{ |src, h| h[:transforms] }
            expected = [
              { authority:  %w[conceptauthorities concept] },
              { authority:  %w[conceptauthorities material_ca] },
              {}
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
      let(:result) { FieldMapper.new(field: @assocStructuredDateGroup) }
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
      let(:result) { FieldMapper.new(field: @termPrefForLang) }
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
      let(:result) { FieldMapper.new(field: @bupper) }
      describe '#get_transforms' do
        it 'creates transform hashes as expected' do
          rh = result.hash.map{ |src, h| h[:transforms] }
          expected = [
            { special: %w[behrensmeyer_translate],
             vocabulary: 'behrensmeyer' },
            {}
          ]
          expect(rh).to eq(expected)
        end
      end
    end
  end

  describe AuthorityConfigLookup do
    context 'when given profile=core and authority=concept/material' do
      let(:result) { AuthorityConfigLookup.new(profile: @contentConcept.profile,
                                               authority: 'authority: concept/material').result }
      it 'returns [conceptauthorities, material_ca]' do
        expect(result).to eq(%w[conceptauthorities material_ca])
      end
    end
    context 'when given profile=core and authority=person/ulan' do
      let(:result) { AuthorityConfigLookup.new(profile: @contentConcept.profile,
                                               authority: 'authority: person/ulan').result }
      it 'returns [personauthorities, ulan_pa]' do
        expect(result).to eq(%w[personauthorities ulan_pa])
      end
    end
  end

  describe DataColumnNamer do
    let(:fieldname){ 'name' }
    let(:xform_sources){ sources.map{ |source| AuthoritySource.new(source) } }
    let(:result){ DataColumnNamer.new(fieldname: fieldname, sources: xform_sources).result.values }
    
    context 'when source is authority' do
      context 'and two authorities may be used' do
        context 'and both are concept authorities' do
          let(:sources){ ['authority: concept/one', 'authority: concept/two'] }
          it 'names columns using authority subtypes' do
            expect(result).to eq(%w[nameConceptOne nameConceptTwo])
          end
        end
        
        context 'and one is person and one is organization' do
          let(:sources){ ['authority: person/local', 'authority: organization/local'] }
          it 'names columns using authority types' do
            expect(result).to eq(%w[namePersonLocal nameOrganizationLocal])
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
          expect(result).to eq(%w[namePersonLocal nameOrganizationLocal namePersonUlan])
        end
      end
    end
  end  
end #RSpec
