require 'proclib/version'
require 'proclib/executor'
require 'proclib/invocation'

module Proclib
  def self.run(cmd,
    tag: nil,
    log_to_console: false,
    capture_output: true,
    env: {},
    stdin: nil,
    on_output: nil,
    cwd: nil,
    ssh: nil
  )
    inv = Invocation.new(cmd,
      tag: tag,
      env: env,
      cwd: cwd,
      stdin: stdin,
      ssh: ssh)

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

  def self.ssh_session(user:, host:, password: nil, port: nil, paranoid: nil)
    ssh_opts = { user: user, host: host }
    ssh_opts[:port] = port unless port.nil?
    ssh_opts[:paranoid] = paranoid unless paranoid.nil?
    ssh_opts[:password] = password unless password.nil?

    SshSession.new(ssh_opts)
  end
end
