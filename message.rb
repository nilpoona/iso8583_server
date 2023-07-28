module ISO8583
  class Message
    attr_reader :mti, :bitmap, :fields

    def initialize(data)
      @data = data
      @fields = {}
    end

    def parse
      # MTI is a 4-digit number
      @mti = @data[0..3]
      puts "MTI: #{@mti}"

      # The bitmap is the next 16 bytes (64 bits) or 32 bytes (128 bits)
      bitmap_hex = @data[4..19]
      @bitmap = [bitmap_hex].pack('H*').unpack('B*').first # Convert bitmap to binary
      puts "Bitmap: #{@bitmap}"

      data_fields = nil
      if @bitmap[0] == '1'
        secondary_bitmap_hex = @data[20..39]
        secondary_bitmap = [secondary_bitmap_hex].pack('H*').unpack('B*').first
        puts "Secondary Bitmap: #{secondary_bitmap}"
        data_fields = @data[40..-1]
      else
        data_fields = @data[20..-1]
      end

      start_index = 0
      (1..9).each do |i|
        if @bitmap[i] == '1'
          case i+1
          when 2  # LLVAR
            length = data_fields[start_index..start_index+1].to_i
            start_index += 2
          when 3, 7
            length = 6 if i+1 == 3
            length = 10 if i+1 == 7
          else
            length = 12 if [4, 5, 6].include?(i+1)
            length = 8 if [8, 9, 10].include?(i+1)
          end
          @fields["field#{i+1}"] = data_fields[start_index..start_index+length-1]
          start_index += length
        end
      end
      p @fields
    end
  end
end