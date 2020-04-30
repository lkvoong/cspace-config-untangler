require 'spec_helper'

RSpec.describe CCU::Profile do
  before do
    stub_const('CCU::CONFIGDIR', 'spec/fixtures/files/5_2')
  end

  let(:core_profile) { CCU::Profile.new('core') }
  let(:anthro_profile) { CCU::Profile.new('anthro') }
  let(:core_rectypes) { ['acquisition', 'authority', 'citation', 'collectionobject', 'concept', 'conditioncheck', 'conservation', 'exhibition', 'group', 'intake', 'loanin', 'loanout', 'location', 'media', 'movement', 'objectexit', 'organization', 'person', 'place', 'relation', 'uoc', 'valuation', 'work'] }
  let(:core_authorities) { %w[citation/local citation/worldcat concept/activity concept/associated concept/ethculture concept/material concept/nomenclature location/local location/offsite organization/local organization/ulan person/local person/ulan place/local place/tgn work/cona work/local] }
  let(:core_option_lists) { ['dimensions', 'measurementUnits', 'searchResultPagePageSizes', 'searchPanelPageSizes', 'booleans', 'yesNoValues', 'dateQualifiers', 'departments', 'loanPurposes', 'accountStatuses', 'acquisitionMethods', 'citationTermStatuses', 'ageUnits', 'collections', 'contentObjectTypes', 'forms', 'inscriptionTypes', 'measuredParts', 'measurementMethods', 'nameCurrencies', 'nameLevels', 'nameSystems', 'nameTypes', 'numberTypes', 'objectComponentNames', 'objectStatuses', 'ownershipAccessLevels', 'ownershipCategories', 'ownershipExchangeMethods', 'phases', 'positions', 'recordStatuses', 'scripts', 'sexes', 'technicalAttributes', 'technicalAttributeMeasurements', 'technicalAttributeMeasurementUnits', 'titleTypes', 'objectParentTypes', 'objectChildTypes', 'conceptTermStatuses', 'conceptTermTypes', 'conceptHistoricalStatuses', 'objectAuditCategories', 'completenessLevels', 'conditions', 'conservationTreatmentPriorities', 'hazards', 'conditionCheckMethods', 'conditionCheckReasons', 'salvagePriorityCodes', 'emailTypes', 'telephoneNumberTypes', 'faxNumberTypes', 'webAddressTypes', 'addressTypes', 'addressCountries', 'exhibitionConsTreatmentStatuses', 'exhibitionMountStatuses', 'entryReasons', 'locationTermTypes', 'locationTermStatuses', 'mediaTypes', 'locationFitnesses', 'moveReasons', 'moveMethods', 'invActions', 'invFreqs', 'exitReasons', 'exitMethods', 'orgTermTypes', 'orgTermStatuses', 'personTermStatuses', 'personTermTypes', 'salutations', 'personTitles', 'genders', 'placeTermTypes', 'placeTermStatuses', 'placeHistoricalStatuses', 'placeTypes', 'coordinateSystems', 'spatialRefSystems', 'localityUnits', 'geodeticDatums', 'geoRefProtocols', 'geoRefVerificationStatuses', 'reportMimeTypes', 'valueTypes', 'vocabTermStatuses', 'workTermStatuses'].sort }
  
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
      expect(core_profile.rectypes.sort).to eq(core_rectypes)
    end
  end

  describe '.extensions' do
    it 'returns array' do
      expect(core_profile.extensions).to be_instance_of(Array)
    end

    it 'cleans rectype list' do
      expect(core_profile.extensions.sort).to eq(%w[address contact dimension structuredDate])
    end
  end

  describe '.authorities' do
    it 'returns array' do
      expect(core_profile.authorities).to be_instance_of(Array)
    end

    it 'returns expected authorities' do
      expect(core_profile.authorities.sort).to eq(core_authorities.sort)
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
  
end #RSpec
