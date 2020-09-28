require 'spec_helper'

RSpec.describe CCU::Template::CsvTemplate do

  before(:all) do
    CCU.const_set('CONFIGDIR', 'spec/fixtures/files/6_1')
    @anthro_profile = CCU::Profile.new(profile: 'anthro_4_1_0', rectypes: %w[movement])
    @anthro_movement = @anthro_profile.rectypes[0]
    @anthro_movement_template = CsvTemplate.new(profile: @anthro_profile, rectype: @anthro_movement)
  end
  describe '.csvdata' do
    it 'correctly reports faux-requiredness' do
      headers = @anthro_movement_template.csvdata[6]
      req = @anthro_movement_template.csvdata[1]
      field_index = headers.index('movementReferenceNumber')
      expect(req[field_index]).to eq('y')
    end
  end
end #RSpec
