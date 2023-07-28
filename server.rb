require 'socket'
require './message.rb'

class Server
  def initialize(port)
    @server = TCPServer.new(port)
    @connection_manager = connection_manager
  end

  def run!
    loop do
      client = @server.accept

      Ractor.new(client, @connection_manager) do |c, connection_manager|
        loop do
          connection_manager.send(:increment)
          result = connection_manager.take
          break if result == :ready
        end

        connection_manager.send(:decrement)

        loop do
          data = c.readpartial(1024)
          message = ISO8583::Message.new data
          message.parse
        end
      rescue EOFError
        c.close
      end
    end
  end

  private

  def connection_manager
    Ractor.new do
      max_workers = 10
      workers = 0
      loop do
        message = Ractor.receive
        case message
        when :increment
          workers += 1
        when :decrement
          workers -= 1
          workers = 0 if workers < 0
        end

        if workers < max_workers
          Ractor.yield :ready
        else
          Ractor.yield :wait
        end
      end
    end
  end
end