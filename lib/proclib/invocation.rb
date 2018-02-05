require 'pathname'

require 'proclib/errors'

require 'proclib/commands/local'
require 'proclib/commands/ssh'

require 'net/ssh'

module Proclib
  class Invocation
    Invalid = Class.new(Error)

    def initialize(cmd,
      tag: nil,
      env: {},
      cwd: nil,
      ssh: nil
    )
      @cmd = cmd
      @tag = tag
      @env = env
      @cwd = cwd
      @ssh = ssh
    end

    def commands
      if validated_cmd.is_a?(String)
        [ make_command(validated_cmd) ]
      else
        validated_cmd.map do |tag, cmdline|
          make_command(cmdline, tag: tag)
        end
      end
    end

    private

    def make_command(cmdline, tag: nil)
      command_class.new(**command_args)
    end

    def command_args
      @command_args ||= {
        tag: @tag,
        env: validated_env,
        run_dir: validated_cwd,
        cmdline: validated_cmd
      }.tap do |args|
        args[:ssh_session] = validated_ssh if !validated_ssh.nil?
      end
    end

    def command_class
      if validated_ssh.nil?
        Commands::Local
      else
        Commands::Ssh
      end
    end

    def validated_env
      if !@env.kind_of?(Hash)
        raise Invalid, "`env` must be a Hash if given"
      end

      @env.each do |args|
        args.each do |v|
          unless [String, Symbol].any? {|c| v.kind_of?(c) }
            raise Invalid, "`env` must be a hash in the form of "\
              "[String|Symbol] => [String|Symbol] if given"
          end
        end
      end
    end

    def validated_cwd
      return nil if @cwd.nil?

      @validated_cwd ||= @cwd.tap do |cwd|
        unless [Pathname, String].any? {|c| cwd.kind_of?(c) }
          raise Invalid, "`cwd` must be a Pathname or String if given"
        end
      end
    end

    def validated_ssh
      return if @ssh.nil?
      return @ssh if @ssh.kind_of?(Net::SSH::Connection::Session)

      @validated_ssh ||= begin
        %i(host user).each do |k|
          if @ssh[k].nil?
            raise Invalid, ":ssh options must contain key `#{k}` if given"
          end
        end

        @validated_ssh
      end
    end

    def validated_cmd
      @validated_cmd ||= begin
        if ![String, Hash].any?{|c| @cmd.kind_of?(c)}
          raise Invalid, "Expected cmd to be either a String or a Hash"
        end

        if @cmd.kind_of?(Hash)
          @cmd.each do |key, value|
            if ! [String, Symbol].include?(key) or !value.kind_of?(String)
              raise Invalid, "If cmd is a list of commands it must be in "\
                "the form of `[String|Symbol] => String`"
            end
          end
        end

        @cmd
      end
    end
  end
end
