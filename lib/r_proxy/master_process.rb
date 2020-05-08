require 'socket'

module RProxy
  class MasterProcess

    attr_reader :config

    def initialize
      @config = RProxy::Config.new
      @logger = @config.logger
      @pids = []
    end

    def run!
      begin
        start_r_proxy
      rescue Interrupt
        @logger.info('existing all process....') if @logger
        EventMachine.stop_event_loop
      rescue => e
        @logger.log("master process exit with #{e.message}") if @logger
        EventMachine.stop_event_loop
      ensure
        stop_all_process
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

      @pids << instance_amount.times do
        timestamp = Time.now.to_i
        Process.fork do
          begin
            @logger.info("r_proxy @#{i} process start....") if @logger
            RProxy::ProxyServer.new(server, @config).run!
          rescue Interrupt
            @logger.info("r_proxy TPC server instance @#{timestamp} closed now....") if @logger
          rescue => e
            @logger.error("instance @#{timestamp}, error: #{e.message}")
            exit!(false)
          end
        end
      end

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