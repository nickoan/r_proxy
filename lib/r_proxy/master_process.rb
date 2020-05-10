require 'socket'

module RProxy
  class MasterProcess

    attr_reader :config

    def initialize
      @config = RProxy::Config.new
      @pids = []
      @watchers = []
      @watcher_status = true
      @mutex = Mutex.new
    end

    def set(name, value)
      @config.send("#{name}=", value)
    end

    def run!
      Signal.trap("TERM") { exit }
      at_exit { stop_all_process }
      @logger = @config.logger
      begin
        start_r_proxy
      rescue Interrupt
        exit
      rescue => e
        @logger.info("master process error: #{e.message}, #{e.backtrace}") if @logger
        exit
      end
    end

    private

    def stop_all_process
      @watcher_status = false
      @pids.each do |pid|
        next unless pid
        Process.kill("TERM", pid)
      end
      sleep(1)
      @logger.info('all process exited....') if @logger
    end


    def spawn_sub_process(server)
      pid =  Process.fork do
        timestamp = (Time.now.to_f * 1000).round
        begin
          @logger.info("r_proxy @#{timestamp} process start....") if @logger
          RProxy::ProxyServer.new(server, @config, timestamp).run!
        rescue Interrupt, SystemExit
          @logger.info("r_proxy TPC server instance @#{timestamp} closed now....") if @logger
        rescue => e
          @logger.error("instance @#{timestamp}, error: #{e.message}, #{e.backtrace}") if @logger
          exit(false)
        end
      end
      pid
    end

    def exec_with_watcher(server)
      @watchers << Thread.fork do
        while @watcher_status
          pid = spawn_sub_process(server)
          push_pids(pid)
          Process.waitpid(pid, 0)
          remove_pid(pid)
        end
      end
    end

    def push_pids(pid)
      @mutex.synchronize do
        @pids << pid
      end
    end

    def remove_pid(pid)
      @mutex.synchronize do
        @pids.delete(pid)
      end
    end

    def start_r_proxy
      instance_amount = @config.instances
      server = TCPServer.new(@config.host, @config.port)
      instance_amount.times do
        exec_with_watcher(server)
        sleep(0.1)
      end
      sleep
    end
  end
end