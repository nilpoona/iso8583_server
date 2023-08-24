require 'socket'
require './message.rb'
require 'ractor/tvar'

class Server
  def initialize(port)
    @port = port
    @server = TCPServer.new(port)
    @connection_manager = connection_manager
  end

  def run!
    p "Server is running on port :#{@port}"

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
    tv = Ractor::TVar.new(0)
    Ractor.new tv do |tv|
      max_connections = 10
      loop do
        message = Ractor.receive
        Ractor.atomically do
          case message
          when :increment
            tv.value += 1
          when :decrement
            tv.value -= 1
            tv.value = 0 if tv.value < 0
          end
        end

        if tv.value < max_connections
          Ractor.yield :ready
        else
          Ractor.yield :wait
        end
      end
    end
  end
end