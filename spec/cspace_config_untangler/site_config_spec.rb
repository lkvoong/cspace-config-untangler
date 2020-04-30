require 'spec_helper'

RSpec.describe CCU::SiteConfig do
  let(:core_config) { CCU::SiteConfig.new('core') }
  let(:coredev_config) { CCU::SiteConfig.new('core', dev = 'true') }
  let(:ohc_config) { CCU::SiteConfig.new('ohc') }
  let(:ohcdev_config) { CCU::SiteConfig.new('ohc', dev = 'true') }
  
  describe '.new' do
    it 'creates CCU::SiteConfig object' do
      expect(core_config).to be_instance_of(CCU::SiteConfig)
    end

    it 'sets url_base for non-dev' do
      expect(core_config.url_base).to eq('https://core.collectionspace.org')
    end
    it 'sets url_base for dev' do
      expect(coredev_config.url_base).to eq('https://core.dev.collectionspace.org')
    end
    it 'sets url_base for ohc non-dev' do
      expect(ohc_config.url_base).to eq('https://cspace.ohiohistory.org')
    end
    it 'sets url_base for ohc dev' do
      expect(ohcdev_config.url_base).to eq('https://ohc.lyrtech.org')
    end
  end

  describe '.rest' do
    it 'returns XML response as string' do
      expect(core_config.rest('/vocabularies/')).to be_instance_of(String)
    end
    it 'fails gracefully' do
      expect(core_config.rest('/vocabulary/')).to be_nil
    end
  end

end #RSpec
