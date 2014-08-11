# -*- coding: utf-8 -*-
require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'

hosts.each do |host|
  # Install Puppet from my fork
  on host, "yum -y install rubygems git ruby-devel"
  on host, "gem install bundler"
  on host, "git clone https://github.com/jantman/puppet.git"
  on host, "cd puppet && git checkout origin/PUP-1244_puppet4 && bundle install --path .bundle/gems/"
  on host, 'for i in /root/puppet/bin/*; do ln -s $i /usr/local/bin/; done'
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    hosts.each do |host|
      on host, puppet('module', 'install', 'puppetlabs-stdlib'), { :acceptable_exit_codes => [0,1] }
    end
  end
end

# copied from lib/beaker/dsl/helpers.rb and slightly modified for bundler
      # Runs 'puppet apply' on a remote host, piping manifest through stdin
      #
      # @param [Host] host The host that this command should be run on
      #
      # @param [String] manifest The puppet manifest to apply
      #
      # @!macro common_opts
      # @option opts [Boolean]  :parseonly (false) If this key is true, the
      #                          "--parseonly" command line parameter will
      #                          be passed to the 'puppet apply' command.
      #
      # @option opts [Boolean]  :trace (false) If this key exists in the Hash,
      #                         the "--trace" command line parameter will be
      #                         passed to the 'puppet apply' command.
      #
      # @option opts [Array<Integer>] :acceptable_exit_codes ([0]) The list of exit
      #                          codes that will NOT raise an error when found upon
      #                          command completion.  If provided, these values will
      #                          be combined with those used in :catch_failures and
      #                          :expect_failures to create the full list of
      #                          passing exit codes.
      #
      # @option opts [Hash]     :environment Additional environment variables to be
      #                         passed to the 'puppet apply' command
      #
      # @option opts [Boolean]  :catch_failures (false) By default `puppet
      #                         --apply` will exit with 0, which does not count
      #                         as a test failure, even if there were errors or
      #                         changes when applying the manifest. This option
      #                         enables detailed exit codes and causes a test
      #                         failure if `puppet --apply` indicates there was
      #                         a failure during its execution.
      #
      # @option opts [Boolean]  :catch_changes (false) This option enables
      #                         detailed exit codes and causes a test failure
      #                         if `puppet --apply` indicates that there were
      #                         changes or failures during its execution.
      #
      # @option opts [Boolean]  :expect_changes (false) This option enables
      #                         detailed exit codes and causes a test failure
      #                         if `puppet --apply` indicates that there were
      #                         no resource changes during its execution.
      #
      # @option opts [Boolean]  :expect_failures (false) This option enables
      #                         detailed exit codes and causes a test failure
      #                         if `puppet --apply` indicates there were no
      #                         failure during its execution.
      #
      # @option opts [Boolean]  :future_parser (false) This option enables
      #                         the future parser option that is available
      #                         from Puppet verion 3.2
      #                         By default it will use the 'current' parser.
      #
      # @option opts [Boolean]  :noop (false) If this option exists, the
      #                         the "--noop" command line parameter will be
      #                         passed to the 'puppet apply' command.
      #
      # @option opts [String]   :modulepath The search path for modules, as
      #                         a list of directories separated by the system
      #                         path separator character. (The POSIX path separator
      #                         is ‘:’, and the Windows path separator is ‘;’.)
      #
      # @param [Block] block This method will yield to a block of code passed
      #                      by the caller; this can be used for additional
      #                      validation, etc.
      #
      def apply_manifest_bundler_on(host, manifest, opts = {}, &block)
        if host.is_a?(Array)
          return host.map do |h|
            apply_manifest_on(h, manifest, opts, &block)
          end
        end

        on_options = {}
        on_options[:acceptable_exit_codes] = Array(opts[:acceptable_exit_codes])

        puppet_apply_opts = {}
        puppet_apply_opts[:verbose] = nil
        puppet_apply_opts[:parseonly] = nil if opts[:parseonly]
        puppet_apply_opts[:trace] = nil if opts[:trace]
        puppet_apply_opts[:parser] = 'future' if opts[:future_parser]
        puppet_apply_opts[:modulepath] = opts[:modulepath] if opts[:modulepath]
        puppet_apply_opts[:noop] = nil if opts[:noop]

        # From puppet help:
        # "... an exit code of '2' means there were changes, an exit code of
        # '4' means there were failures during the transaction, and an exit
        # code of '6' means there were both changes and failures."
        if [opts[:catch_changes],opts[:catch_failures],opts[:expect_failures],opts[:expect_changes]].compact.length > 1
          raise(ArgumentError,
                'Cannot specify more than one of `catch_failures`, ' +
                '`catch_changes`, `expect_failures`, or `expect_changes` ' +
                'for a single manifest')
        end

        if opts[:catch_changes]
          puppet_apply_opts['detailed-exitcodes'] = nil

          # We're after idempotency so allow exit code 0 only.
          on_options[:acceptable_exit_codes] |= [0]
        elsif opts[:catch_failures]
          puppet_apply_opts['detailed-exitcodes'] = nil

          # We're after only complete success so allow exit codes 0 and 2 only.
          on_options[:acceptable_exit_codes] |= [0, 2]
        elsif opts[:expect_failures]
          puppet_apply_opts['detailed-exitcodes'] = nil

          # We're after failures specifically so allow exit codes 1, 4, and 6 only.
          on_options[:acceptable_exit_codes] |= [1, 4, 6]
        elsif opts[:expect_changes]
          puppet_apply_opts['detailed-exitcodes'] = nil

          # We're after changes specifically so allow exit code 2 only.
          on_options[:acceptable_exit_codes] |= [2]
        else
          # Either use the provided acceptable_exit_codes or default to [0]
          on_options[:acceptable_exit_codes] |= [0]
        end

        # Not really thrilled with this implementation, might want to improve it
        # later.  Basically, there is a magic trick in the constructor of
        # PuppetCommand which allows you to pass in a Hash for the last value in
        # the *args Array; if you do so, it will be treated specially.  So, here
        # we check to see if our caller passed us a hash of environment variables
        # that they want to set for the puppet command.  If so, we set the final
        # value of *args to a new hash with just one entry (the value of which
        # is our environment variables hash)
        if opts.has_key?(:environment)
          puppet_apply_opts['ENV'] = opts[:environment]
        end

        file_path = host.tmpfile('apply_manifest.pp')
        create_remote_file(host, file_path, manifest + "\n")

        if host[:default_apply_opts].respond_to? :merge
          puppet_apply_opts = host[:default_apply_opts].merge( puppet_apply_opts )
        end

        cmd_line = puppet_bundler('apply', file_path, puppet_apply_opts)
        cl = cmd_line.cmd_line(host)
        on host, "cd /root/puppet && #{cl}", on_options, &block
      end

      # Runs 'puppet apply' on default host, piping manifest through stdin
      # @see #apply_manifest_on
      def apply_manifest_bundler(manifest, opts = {}, &block)
        apply_manifest_bundler_on(default, manifest, opts, &block)
      end

module Beaker
  module DSL
    module Wrappers
      # This is hairy and because of legacy code it will take a bit more
      # work to disentangle all of the things that are being passed into
      # this catchall param.
      #
      # @api dsl
      def puppet_bundler(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        options['ENV'] ||= {}
        options['ENV'] = options['ENV'].merge( Command::DEFAULT_GIT_ENV )
        # we assume that an invocation with `puppet()` will have it's first argument
        # a face or sub command
        cmd = "bundle exec puppet #{args.shift}"
        Command.new( cmd, args, options )
      end
    end
  end
end
