module Proclib
  class SshSession
    attr_reader :ssh_opts

    def initialize(ssh_opts)
      @ssh_opts = ssh_opts.clone
    end

    def run(cmd,
      tag: nil,
      log_to_console: false,
      capture_output: true,
      env: {},
      on_output: nil,
      cwd: nil,
      ssh: nil
    )

      inv = Invocation.new(cmd,
        tag: tag,
        env: env,
        ssh: session,
        cwd: cwd)

      executor = Executor.new(inv.commands,
        log_to_console: log_to_console,
        cache_output: capture_output
      ).tap do |ex|
        ex.on_output(&on_output) unless on_output.nil?
      end

      executor.run_sync
    rescue Invocation::Invalid => e
      raise ArgumentError, e.message
    end

    private

    def ssh_params
      %i(host user).map {|i| ssh_opts.delete(i)}.compact
    end

    def session
      @session ||= Net::SSH.start(*ssh_params, ssh_opts)
    end
  end
  private_constant :SshSession
end
