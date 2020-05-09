require 'socket'

module RProxy
  class MasterProcess

    attr_reader :config

    def initialize
      @config = RProxy::Config.new
      @pids = []
    end

    def set(name, value)
      @config.send("#{name}=", value)
    end

    def run!
      at_exit { stop_all_process }
      @logger = @config.logger
      begin
        start_r_proxy
      rescue Interrupt
        @logger.info('existing all process....') if @logger
        EventMachine.stop_event_loop if EventMachine.reactor_running?
      rescue => e
        @logger.info("master process exit with #{e.message}, #{e.backtrace}") if @logger
        EventMachine.stop_event_loop if EventMachine.reactor_running?
      end
    end

    private

    def stop_all_process
      @pids.each do |pid|
        next unless pid
        Process.kill("TERM", pid)
      end
    end

    def start_r_proxy

      instance_amount = @config.instances
      server = TCPServer.new(@config.host, @config.port)
      instance_amount.times do
        pid =  Process.fork do
          timestamp = (Time.now.to_f * 1000).round
          begin
            @logger.info("r_proxy @#{timestamp} process start....") if @logger
            RProxy::ProxyServer.new(server, @config, timestamp).run!
          rescue Interrupt
            @logger.info("r_proxy TPC server instance @#{timestamp} closed now....") if @logger
          rescue => e
            @logger.error("instance @#{timestamp}, error: #{e.message}, #{e.backtrace}") if @logger
            exit!(false)
          end
        end

        Process.detach(pid)
        @pids << pid
        sleep(0.1)
      end

      EventMachine.kqueue=(true)
      EventMachine.run do
        @pids.each do |pid|
          EventMachine.watch_process(pid,
                                     RProxy::ProcessHandler,
                                     @pids,
                                     @config,
                                     server,
                                     pid)
        end
      end
    end
  end
end