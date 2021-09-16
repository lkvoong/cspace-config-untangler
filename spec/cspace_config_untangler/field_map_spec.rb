require 'spec_helper'

RSpec.describe CCU::FieldMap do
  let(:generator){ Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes, release: release) }
  let(:profilename){ 'core' }
  let(:rectypes){ ['collectionobject', 'concept', 'movement'] }
  let(:release){ '6_0' }
  let(:profile){ generator.profile }
  let(:field){ generator.field(fieldrec, fieldname) }
  let(:mapper){ FieldMapper.new(field: field)}
  let(:mappings) { mapper.mappings }

  let(:authority_obj){ CCU::ValueSources::Authority.new(auth_str) }

  before(:context) do
    CCU.config.configdir = File.join(fixtures, 'files', '6_0')
  @core_profile = CCU::Profile.new(profile: 'core', rectypes: ['collectionobject', 'concept', 'movement'], structured_date_treatment: :collapse)
  @fields = @core_profile.fields
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
        let(:fieldrec){ 'collectionobject' }
        let(:fieldname){ 'contentConcept' }
        it 'mappings have source_type = authority' do
          result = mappings.map{ |m| m.source_type }
          expect(result).to eq(%w[authority authority refname])
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
        let(:fieldrec){ 'movement' }
        let(:fieldname){ 'currentLocation' }
        it 'mappings have source_type = authority' do
          result = mappings.map{ |m| m.source_type }
          expect(result).to eq(%w[authority authority authority refname])
        end
        it 'mappings datacolumns = currentLocationLocationLocal currentLocationLocationOffsite currentLocationOrganizationLocal currentLocationRefname' do
          result = mappings.map{ |m| m.datacolumn }.sort
          expect(result).to eq(%w[currentLocationLocationLocal currentLocationLocationOffsite currentLocationOrganizationLocal
                                  currentLocationRefname])
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
      let(:fieldrec){ 'collectionobject' }
      let(:fieldname){ 'assocActivity' }

      describe '#get_data_columns' do
        it 'column is the same as field name' do
          expect(mapper.hash.map{ |src, h| h[:column_name] }).to eq(['assocActivity'])
        end
      end
      describe '#mappings' do
        it 'returns 1 mapping' do
          expect(mapper.mappings.size).to eq(1)
        end
      end
      describe '#source_type' do
        it 'returns na' do
          expect(mapper.source_type).to eq('na')
        end
      end
    end

    context 'when field source is option list' do
      let(:fieldrec){ 'collectionobject' }
      let(:fieldname){ 'ageUnit' }

      describe '#get_data_columns' do
        it 'column is the same as field name' do
          expect(mapper.hash.map{ |src, h| h[:column_name] }).to eq(['ageUnit'])
        end
      end
      describe '#mappings' do
        it 'returns 1 mapping' do
          expect(mapper.mappings.size).to eq(1)
        end
      end
      describe '#source_type' do
        it 'returns optionlist' do
          expect(mapper.source_type).to eq('optionlist')
        end
      end
    end

    context 'when field source is vocabulary' do
      context 'we assume only one vocabulary source per field' do
      let(:fieldrec){ 'collectionobject' }
      let(:fieldname){ 'ageQualifier' }

        describe '#get_data_columns' do
          it 'column is the same as field name' do
            expect(mapper.hash.map{ |src, h| h[:column_name] }).to eq(['ageQualifier', 'ageQualifierRefname'])
          end
        end
        describe '#mappings' do
          it 'returns 2 mappings' do
            expect(mapper.mappings.size).to eq(2)
          end
        end
        describe '#get_transforms' do
          it 'creates transform hash as expected' do
            rh = mapper.hash.map{ |src, h| h[:transforms] }
            expected = [
              { vocabulary: 'agequalifier' },
              {}
            ]
            expect(rh).to eq(expected)
          end
        end
        describe '#source_type' do
          it 'returns vocabulary' do
            expect(mapper.source_type).to eq('vocabulary')
          end
        end
      end
    end

    context 'when field source is authority' do
      context 'and two authorities may be used' do
        let(:fieldrec){ 'collectionobject' }
        let(:fieldname){ 'contentConcept' }

        describe '#get_data_columns' do
          it 'merges in column name hash as expected' do
            expect(mapper.hash.map{ |src, h| h[:column_name] }).to eq(%w[contentConceptConceptAssociated contentConceptConceptMaterial contentConceptRefname])
          end
        end
        describe '#mappings' do
          it 'returns 3 mappings' do
            expect(mapper.mappings.size).to eq(3)
          end
        end
        describe '#get_transforms' do
          it 'creates transform hashes as expected' do
            rh = mapper.hash.map{ |src, h| h[:transforms] }
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
            expect(mapper.source_type).to eq('authority')
          end
        end
      end
    end

    context 'when stuctured date field' do
        let(:fieldrec){ 'collectionobject' }
        let(:fieldname){ 'assocStructuredDateGroup' }

      describe '#get_data_columns' do
        it 'merges in column name hash as expected' do
          expect(mapper.hash.map{ |src, h| h[:column_name] }).to eq(%w[assocStructuredDateGroup])
        end
      end
      describe '#mappings' do
        it 'returns 1 mappings' do
          expect(mapper.mappings.size).to eq(1)
        end
      end
      describe '#get_transforms' do
        it 'creates transform hashes as expected' do
          rh = mapper.hash.map{ |src, h| h[:transforms] }
          expected = [
            {},
          ]
          expect(rh).to eq(expected)
        end
      end
      describe '#source_type' do
        it 'returns authority' do
          expect(mapper.source_type).to eq('na')
        end
      end
    end

    context 'when boolean field' do
      let(:fieldrec){ 'concept' }
      let(:fieldname){ 'termPrefForLang' }

      describe '#get_transforms' do
        it 'creates transform hashes as expected' do
          rh = mapper.hash.map{ |src, h| h[:transforms] }
          expected = [
            { special: %w[boolean] },
          ]
          expect(rh).to eq(expected)
        end
      end
    end

    context 'when behrensmeyer field' do
      let(:profilename){ 'anthro' }
      let(:fieldrec){ 'collectionobject' }
      let(:fieldname){ 'behrensmeyerUpper' }

      describe '#get_transforms' do
        it 'creates transform hashes as expected' do
          rh = mapper.hash.map{ |src, h| h[:transforms] }
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

end #RSpec
