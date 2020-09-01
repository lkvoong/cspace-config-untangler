require 'spec_helper'

RSpec.describe CCU::RecordMapper do
  before(:all) do
    CCU.const_set('CONFIGDIR', 'spec/fixtures/files/6_0')
    @anthro_profile = CCU::Profile.new(profile: 'anthro',
                                       rectypes: ['collectionobject', 'claim', 'taxon'],
                                       structured_date_treatment: :collapse)
    @anthro_co = @anthro_profile.rectypes.select{ |rt| rt.name == 'collectionobject' }.first
    @anthro_claim = @anthro_profile.rectypes.select{ |rt| rt.name == 'claim' }.first
    @anthro_taxon = @anthro_profile.rectypes.select{ |rt| rt.name == 'taxon' }.first
    @rm_anthro_co = RecordMapping.new(profile: @anthro_profile, rectype: @anthro_co)
  end

  describe RecordMapping do
    describe '#hash' do
      it 'returns record mapping hash' do
        expect(@rm_anthro_co.hash).to be_a(Hash)
      end
    end

    describe '#ensure_unique_datacolumns' do
      context 'anthro profile' do
        context 'collectionobject recordtype' do
          before(:all) do
            @mappings = @rm_anthro_co.mappings
          end
          context 'fieldname = sex' do
            it 'columnnames: sex, commingledRemainsGroup_sex' do
              result = @mappings.select{ |m| m.fieldname == 'sex' }.map{ |m| m.datacolumn }.sort
              expect(result).to eq(%w[commingledRemainsGroup_sex sex])
            end
          end
          context 'fieldname = reference' do
            # does NOT change datacolumn values, as one field's use of multiple authorities
            #  has already caused all datacolumn values to be different
            it 'columnnames: ' do
              result = @mappings.select{ |m| m.fieldname == 'reference' }.map{ |m| m.datacolumn }.sort
              expect(result).to eq(%w[reference referenceLocal referenceWorldcat])
            end
          end
          context 'fieldname = fieldLocVerbatim' do
            it 'columnnames: ' do
              result = @mappings.select{ |m| m.fieldname == 'fieldLocVerbatim' }.map{ |m| m.datacolumn }.sort
              expect(result).to eq(%w[fieldLocVerbatim localityGroup_fieldLocVerbatim])
            end
          end
        end
      end
    end
  end

  describe NamespaceUris do
    context 'anthro' do
      context 'collectionobject' do
        let(:result) { NamespaceUris.new(profile_config: @anthro_profile.config,
                                         rectype: 'collectionobject',
                                         mapper_config: @rm_anthro_co.hash[:config]
                                        ).hash }

        let(:expected) { {
          'collectionobjects_common' => 'http://collectionspace.org/services/collectionobject',
          'collectionobjects_culturalcare' => 'http://collectionspace.org/services/collectionobject/domain/collectionobject',
          'collectionobjects_annotation' => 'http://collectionspace.org/services/collectionobject/domain/annotation',
          'collectionobjects_nagpra' => 'http://collectionspace.org/services/collectionobject/domain/nagpra',
          'collectionobjects_anthro' => 'http://collectionspace.org/services/collectionobject/domain/anthro',
          'collectionobjects_naturalhistory_extension' => 'http://collectionspace.org/services/collectionobject/domain/naturalhistory_extension'
        } }

        it 'generates hash correctly' do
          expected.keys.each{ |k| expect(result[k]).to eq(expected[k]) }
        end
      end

      context 'claim' do
        let(:rm_anthro_claim) { RecordMapping.new(profile: @anthro_profile, rectype: @anthro_claim) }
        let(:result) { NamespaceUris.new(profile_config: @anthro_profile.config,
                                         rectype: 'claim',
                                         mapper_config: rm_anthro_claim.hash[:config]
                                        ).hash }

        let(:expected) { {
          'claims_nagpra' => 'http://collectionspace.org/services/claim/domain/nagpra',
          'claims_common' => 'http://collectionspace.org/services/claim'
        } }

        it 'generates hash correctly' do
          expected.keys.each{ |k| expect(result[k]).to eq(expected[k]) }
        end
      end
      
      context 'taxon' do
        let(:rm_anthro_taxon) { RecordMapping.new(profile: @anthro_profile, rectype: @anthro_taxon) }
        let(:result) { NamespaceUris.new(profile_config: @anthro_profile.config,
                                         rectype: 'taxon',
                                         mapper_config: rm_anthro_taxon.hash[:config]
                                        ).hash }

        let(:expected) { {
          'taxon_common' => 'http://collectionspace.org/services/taxonomy'
        } }

        it 'generates hash correctly' do
          expected.keys.each{ |k| expect(result[k]).to eq(expected[k]) }
        end
      end
    end
  end
end #RSpec
