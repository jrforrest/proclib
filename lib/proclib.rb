require 'proclib/version'
require 'proclib/executor'
require 'proclib/invocation'

module Proclib
  def self.run(cmd,
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
      cwd: cwd,
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
end
