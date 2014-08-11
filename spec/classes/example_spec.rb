require 'spec_helper'

describe 'PUP1244' do
  context 'supported operating systems' do
    ['Debian', 'RedHat'].each do |osfamily|
      describe "PUP1244 class without any parameters on #{osfamily}" do
        let(:params) {{ }}
        let(:facts) {{
          :osfamily => osfamily,
        }}

        it { should compile.with_all_deps }

        it { should contain_class('PUP1244::params') }
        it { should contain_class('PUP1244::install').that_comes_before('PUP1244::config') }
        it { should contain_class('PUP1244::config') }
        it { should contain_class('PUP1244::service').that_subscribes_to('PUP1244::config') }

        it { should contain_service('PUP1244') }
        it { should contain_package('PUP1244').with_ensure('present') }
      end
    end
  end

  context 'unsupported operating system' do
    describe 'PUP1244 class without any parameters on Solaris/Nexenta' do
      let(:facts) {{
        :osfamily        => 'Solaris',
        :operatingsystem => 'Nexenta',
      }}

      it { expect { should contain_package('PUP1244') }.to raise_error(Puppet::Error, /Nexenta not supported/) }
    end
  end
end
