require 'socket'
require './message.rb'

class Server
  def initialize(port)
    @server = TCPServer.new(port)
  end

  def run!
    loop do
      client = @server.accept

      Ractor.new(client) do |c|
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
end