require 'spec_helper_acceptance'

describe 'PUP-1244 tests' do

  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do
      pp = <<-EOS
      warning('foo')
      EOS

      # Run it twice and test for idempotency
      expect(apply_manifest_bundler(pp).exit_code).to_not eq(1)
      expect(apply_manifest_bundler(pp).exit_code).to eq(0)
    end

  end
end
