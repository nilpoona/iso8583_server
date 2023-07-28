require 'socket'

mti = '0100'
bitmap = '7200000000000000'

field2 = '16' + '4111111111111111'  # '16' is the length of the PAN (Primary Account Number)
field3 = '123456'  # Processing Code
field4 = '000000001000'  # Transaction Amount
field7 = '0723093012'  # Transmission Date & Time

message = mti + bitmap + field2 + field3 + field4 + field7

client = TCPSocket.new('localhost', 12345)
client.write(message)
client.close