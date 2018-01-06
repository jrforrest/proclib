require 'open3'
require 'thread'

require 'proclib/version'
require 'proclib/event_emitter'
require 'proclib/process'
require 'proclib/ssh_process'
require 'proclib/process_group'
require 'proclib/executor'

module Proclib
  module Methods
    def run(cmd,
      tag: nil,
      log_to_console: false,
      capture_output: true,
      env: {},
      on_output: nil,
      cwd: nil,
      host: nil
    )
      raise(ArgumentError, "env must be a Hash") unless env.kind_of?(Hash)

      runnable = if cmd.kind_of? String
        if host.nil?
          Process.new(cmd, tag: tag || cmd[0..20], env: env, run_dir: cwd)
        else
          SSHProcess.new(cmd, tag: tag || cmd[0..20], env: env, run_dir: cwd, host: host)
        end
      elsif cmd.kind_of?(Hash)
        processes = cmd.map do |(k,v)|
          if host.nil?
            Process.new(cmd, tag: tag || cmd[0..20], env: env, run_dir: cwd)
          else
            SSHProcess.new(cmd, tag: tag || cmd[0..20], env: env, run_dir: cwd, host: host)
          end
        end

        ProcessGroup.new(processes)
      else
        raise ArgumentError, "Unexpected type for `cmd`: #{cmd.class}.  \n"\
          "Expected String or Hash"
      end

      unless on_output.nil? || on_output.kind_of?(Proc) || on_ouptut.kind_of?(Lambda)
        raise ArgumentError, "Expected :on_output to be a proc or lambda if given"
      end

      executor = Executor.new(runnable,
        log_to_console: log_to_console,
        on_output: on_output,
        cache_output: capture_output)

      executor.run_sync
    end
  end

  class << self
    include Methods
  end
end
