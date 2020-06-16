require 'spec_helper'

RSpec.describe CCU::Profile do
  before do
    stub_const('CCU::CONFIGDIR', 'spec/fixtures/files/6_0')
  end

  let(:core_profile) { CCU::Profile.new('core') }
  let(:anthro_profile) { CCU::Profile.new('anthro') }
  let(:bonsai_profile) { CCU::Profile.new('bonsai') }
  let(:core_rectypes) { ['acquisition', 'citation', 'collectionobject', 'concept', 'conditioncheck', 'conservation', 'exhibition', 'group', 'intake', 'loanin', 'loanout', 'location', 'media', 'movement', 'objectexit', 'organization', 'person', 'place', 'uoc', 'valuation', 'work'] }
  let(:core_authorities) { %w[citation/local citation/worldcat concept/activity concept/associated concept/ethculture concept/material concept/nomenclature location/local location/offsite organization/local organization/ulan person/local person/ulan place/local place/tgn work/cona work/local] }
  let(:core_option_lists) { ['dimensions', 'measurementUnits', 'searchResultPagePageSizes', 'searchPanelPageSizes', 'booleans', 'yesNoValues', 'dateQualifiers', 'departments', 'loanPurposes', 'accountStatuses', 'acquisitionMethods', 'citationTermStatuses', 'ageUnits', 'collections', 'contentObjectTypes', 'forms', 'inscriptionTypes', 'measuredParts', 'measurementMethods', 'nameCurrencies', 'nameLevels', 'nameSystems', 'nameTypes', 'numberTypes', 'objectComponentNames', 'objectStatuses', 'ownershipAccessLevels', 'ownershipCategories', 'ownershipExchangeMethods', 'phases', 'positions', 'recordStatuses', 'scripts', 'sexes', 'technicalAttributes', 'technicalAttributeMeasurements', 'technicalAttributeMeasurementUnits', 'titleTypes', 'objectParentTypes', 'objectChildTypes', 'conceptTermStatuses', 'conceptTermTypes', 'conceptHistoricalStatuses', 'objectAuditCategories', 'completenessLevels', 'conditions', 'conservationTreatmentPriorities', 'hazards', 'conditionCheckMethods', 'conditionCheckReasons', 'salvagePriorityCodes', 'emailTypes', 'telephoneNumberTypes', 'faxNumberTypes', 'webAddressTypes', 'addressTypes', 'addressCountries', 'exhibitionConsTreatmentStatuses', 'exhibitionMountStatuses', 'entryReasons', 'locationTermTypes', 'locationTermStatuses', 'mediaTypes', 'locationFitnesses', 'moveReasons', 'moveMethods', 'invActions', 'invFreqs', 'exitReasons', 'exitMethods', 'orgTermTypes', 'orgTermStatuses', 'personTermStatuses', 'personTermTypes', 'salutations', 'personTitles', 'genders', 'placeTermTypes', 'placeTermStatuses', 'placeHistoricalStatuses', 'placeTypes', 'coordinateSystems', 'spatialRefSystems', 'localityUnits', 'geodeticDatums', 'geoRefProtocols', 'geoRefVerificationStatuses', 'reportMimeTypes', 'valueTypes', 'vocabTermStatuses', 'workTermStatuses'].sort }
  let(:core_vocabs) { %w[acousticalproperties additionalprocesses additionalproperties addresstype agentinfotype agequalifier castingprocesses citationtermflag citationtermtype collectionmethod concepttermflag concepttype conditioncheckmethod conditioncheckreason conditionfitness conservationstatus contactrole contactstatus currency datecertainty dateera datequalifier deaccessionapprovalgroup deaccessionapprovalstatus deformingprocesses disposalmethod dtstest dtstest1 dtstest2 durabilityproperties ecologicalcertifications electricalproperties energyunits entrymethod examinationphase exhibitionpersonrole exhibitionreferencetype exhibitionstatus exhibitiontype hygrothermalproperties hygrothermalpropertyunits inventorystatus joiningprocesses languages lifecyclecomponents loanoutstatus locationtermflag locationtype machiningprocesses materialform materialformtype materialproductionrole materialresource materialtermflag materialtype materialuse mechanicalproperties mechanicalpropertyunits moldingprocesses opticalproperties organizationtype orgtermflag otherpartyrole persontermflag persontermtype placetermflag publishto rapidprototypingprocesses recycledcontentqualifiers relationtypetype resourceidtype sensorialproperties smartmaterialproperties surfacingprocesses taxontermflag taxontype treatmentpurpose uocauthorizationstatuses uoccollectiontypes uocmaterialtypes uocmethods uocprojectid uocstaffroles uocsubcollections uocuserroles uocusertypes workcreatortype workpublishertype worktermflag worktype].sort }
  
  describe '.new' do
    it 'creates CCU::Profile object' do
      expect(core_profile).to be_instance_of(CCU::Profile)
    end
  end

  describe '.config' do
    it 'returns hash' do
      expect(core_profile.config).to be_instance_of(Hash)
    end

    it 'hash for core 5.2 has 28 keys' do
      expect(core_profile.config.keys.length).to eq(28)
    end
  end

  describe '.rectypes' do
    it 'returns array' do
      expect(core_profile.rectypes).to be_instance_of(Array)
    end

    it 'cleans rectype list' do
      expect(core_profile.rectypes.map{ |rt| rt.name }.sort).to eq(core_rectypes)
    end
  end

  describe '.extensions' do
    it 'returns array' do
      expect(core_profile.extensions).to be_instance_of(Array)
    end

    it 'cleans extension list' do
      expect(core_profile.extensions.sort).to eq(%w[address blob contact dimension structuredDate])
    end
  end

  describe 'apply_panel_override' do
    it 'gets panel message overrides from profile level' do
      msg = anthro_profile.messages['panel.collectionobject.reference']['fullName']
      expect(msg).to eq('Bibliographic Reference Information')
    end
  end
  
  describe 'apply_overrides' do
    it 'gives living plant extension messages ext prefix instead of conservation_livingplant' do
      expect(bonsai_profile.messages.has_key?('field.ext.livingplant.pestOrDiseaseObserved')).to be true
    end
  end

  describe 'apply_field_override' do
    it 'gets field message overrides from profile level' do
      msg = bonsai_profile.messages['field.conservation_common.conservator']['name']
      expect(msg).to eq('Performed by')
    end
  end


  describe '.authorities' do
    context 'when all rectypes requested' do
    it 'returns array' do
      expect(core_profile.authorities).to be_instance_of(Array)
    end

    it 'returns expected authorities' do
      expect(core_profile.authorities.sort).to eq(core_authorities.sort)
    end
    end
    context 'when only collectionobject requested' do
      it 'returns expected authorities' do
        p = CCU::Profile.new('core', rectypes: ['collectionobject'])
        expect(p.authorities.sort).to eq(core_authorities.sort)
      end
    end
  end

  describe '.option_lists' do
    it 'returns array' do
      expect(core_profile.option_lists).to be_instance_of(Array)
    end

    it 'returns expected option_lists' do
      expect(core_profile.option_lists.sort).to eq(core_option_lists.sort)
    end
  end

  describe '#extensions_for' do
    let (:result) { anthro_profile.extensions_for('collectionobject') }
    it 'returns hash' do
      expect(result).to be_instance_of(Hash)
    end
    it 'keys are the extension names' do
      a = %w[address dimension structuredDate annotation culturalcare locality naturalhistory nagpra].sort
      expect(result.keys.sort).to eq(a)
    end
  end

  describe 'vocabularies' do
    it 'returns array of vocabularies' do
      expect(core_profile.vocabularies.sort).to eq(core_vocabs)
    end
  end
end #RSpec
