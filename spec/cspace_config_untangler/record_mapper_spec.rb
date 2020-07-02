require 'spec_helper'

RSpec.describe CCU::RecordMapper do
  before do
    stub_const('CCU::CONFIGDIR', 'spec/fixtures/files/6_0')
  end

  let(:anthro_profile) { CCU::Profile.new('anthro', rectypes: ['collectionobject'], structured_date_treatment: :collapse) }
  let(:rm_anthro_co) { RecordMapping.new(profile: 'anthro', rectype: 'collectionobject') }

  # ["authority: concept/associated", "authority: concept/material"]
  describe RecordMapping do
    describe '#hash' do
      it 'returns record mapping hash' do
        expect(rm_anthro_co.hash).to be_a(Hash)
      end
    end
  end

  describe NamespaceUris do
    context 'anthro' do
      context 'collectionobject' do
        let(:result) { NamespaceUris.new(profile_config: anthro_profile.config,
                                         rectype: 'collectionobject',
                                         mapper_config: rm_anthro_co.hash[:config]
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
        let(:rm_anthro_claim) { RecordMapping.new(profile: 'anthro', rectype: 'claim') }
        let(:result) { NamespaceUris.new(profile_config: anthro_profile.config,
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
        let(:rm_anthro_taxon) { RecordMapping.new(profile: 'anthro', rectype: 'taxon') }
        let(:result) { NamespaceUris.new(profile_config: anthro_profile.config,
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
