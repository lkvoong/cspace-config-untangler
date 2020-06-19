require 'spec_helper'

RSpec.describe CCU::Field do
  before do
    stub_const('CCU::CONFIGDIR', 'spec/fixtures/files/6_0')
  end

  let(:core_profile) { CCU::Profile.new('core', rectypes: ['collectionobject']) }
  let(:co_fields) { core_profile.fields }
  let(:contentConcept) { co_fields.select{ |f| f.name == 'contentConcept' }[0] }
  #  let(:anthro_profile) { CCU::Profile.new('anthro') }
  #  let(:anthro_co) { CCU::RecordType.new(anthro_profile, 'collectionobject') }
  #  let(:anthro_default) { anthro_co.forms['default'] }

  describe CCU::Field do
    describe '#value_source' do
      # tested in field_definition_spec
      # this just copies from the field_definition
    end
  end
  
  
end #RSpec
