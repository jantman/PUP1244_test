require 'spec_helper_acceptance'

describe 'PUP-1244 tests' do

  context 'puppet is working' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do
      pp = <<-EOS
      warning('foo')
      EOS

      # Run it twice and test for idempotency
      expect(apply_manifest_bundler(pp, opts={:debug => true}).exit_code).to_not eq(1)
      expect(apply_manifest_bundler(pp, opts={:debug => true}).exit_code).to eq(0)
    end
  end

  context 'install specific pg libs version RPM' do
    it 'should work with no errors' do
      pp = <<-EOS
      package { 'postgresql93-libs-9.3.3-1PGDG.rhel6.x86_64': ensure => present, }
      EOS

      # Run it twice and test for idempotency
      expect(apply_manifest_bundler(pp).exit_code).to_not eq(1)
      expect(apply_manifest_bundler(pp).exit_code).to eq(0)
    end
    describe package('postgresql93-libs') do
      it { should be_installed }
    end
    describe command('rpm -q postgresql93-libs-9.3.3-1PGDG.rhel6.x86_64') do
      it { should return_exit_status 0 }
    end
  end

  describe 'update pg libs RPM to 9.3.4' do
    it 'should work with no errors' do
      pp = <<-EOS
      package { 'postgresql93-libs-9.3.4': ensure => present, }
      EOS

      # Run it twice and test for idempotency
      expect(apply_manifest_bundler(pp).exit_code).to_not eq(1)
      expect(apply_manifest_bundler(pp).exit_code).to eq(0)
    end
    describe package('postgresql93-libs') do
      it { should be_installed }
    end
    describe command('rpm -q postgresql93-libs-9.3.4-1PGDG.rhel6.x86_64') do
      it { should return_exit_status 0 }
    end
  end

  describe 'update pg libs RPM to latest' do
    it 'should work with no errors' do
      pp = <<-EOS
      package { 'postgresql93-libs': ensure => latest, }
      EOS

      # Run it twice and test for idempotency
      expect(apply_manifest_bundler(pp).exit_code).to_not eq(1)
      expect(apply_manifest_bundler(pp).exit_code).to eq(0)
    end
    describe package('postgresql93-libs') do
      it { should be_installed }
    end
    describe command('rpm -q postgresql93-libs-9.3.5-1PGDG.rhel6.x86_64') do
      it { should return_exit_status 0 }
    end
  end
end
