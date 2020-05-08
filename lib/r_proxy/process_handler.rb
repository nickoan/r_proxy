module RProxy
  class ProcessHandler < EventMachine::ProcessWatch

    def initialize(pids, config, socket, pid)
      @pids = pids
      @id = pid
      @config = config
      @socket = socket
      @logger = config.logger
    end

    def process_exited

      @pids.delete(@id)
      timestamp = Time.now.to_i

      pid = Process.fork do
        begin
          @logger.info("r_proxy rebuild new instance replace @#{timestamp}....") if @logger
          RProxy::ProxyServer.new(@socket, @config).run!
        rescue Interrupt
          @logger.info("r_proxy TPC server instance @#{timestamp} closed now....") if @logger
        rescue => e
          @logger.error("instance @#{timestamp}, error: #{e.message}, #{e.backtrace}") if @logger
          exit(false)
        end
      end

      Process.detach(pid)
      @pids << pid

      EventMachine.watch_process(pid, RProxy::ProcessHandler,
                                 @pids,
                                 @config,
                                 @socket,
                                 pid)
      close_connection
    end
  end
end