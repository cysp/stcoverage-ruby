# vim: et sw=2

require_relative 'gcov_types'
require 'stringio'

module GCOVReading
  def self.io_from_io_or_string(io_or_string)
    return io_or_string if io_or_string.respond_to?(:read) and io_or_string.respond_to?(:tell)
    StringIO.open(io_or_string, 'rb')
  end

  def self.read(io, length)
    val = io.read(length)
    return nil if val.nil? or val.length != length
    val
  end

  def self.read_uint32(io)
    val = io.read(4)
    return nil if val.nil? or val.length != 4
    val.unpack('V').fetch(0, 0)
  end

  def self.read_uint64(io)
    lo = io.read(4)
    return nil if lo.nil? or lo.length != 4
    lo = lo.unpack('V').fetch(0, 0)

    hi = io.read(4)
    return nil if hi.nil? or hi.length != 4
    hi = hi.unpack('V').fetch(0, 0)

    hi * 2**32 + lo
  end

  def self.read_string(io)
    length = io.read(4)
    return nil if length.nil? or length.length != 4
    length = length.unpack('V')[0] * 4

    string = io.read(length)
    return nil if string.nil? or string.length != length

    while string.chomp!("\x00")
    end

    string
  end
end

class GCOVFileReader
  def initialize(io_or_string)
    @io = GCOVReading.io_from_io_or_string(io_or_string)
  end

  def read_header
    iopos = @io.tell

    magic = GCOVReading.read(@io, 4)
    @io.seek(iopos) and return nil if magic.nil?

    version = GCOVReading.read(@io, 4)
    @io.seek(iopos) and return nil if version.nil?

    stamp = GCOVReading.read(@io, 4)
    @io.seek(iopos) and return nil if stamp.nil?

    GCOVHeader.new(magic, version, stamp)
  end

  def read_tag
    iopos = @io.tell

    tagidentifier = GCOVReading.read_uint32(@io)
    @io.seek(iopos) and return nil if tagidentifier.nil?

    tagdatalength = GCOVReading.read_uint32(@io)
    @io.seek(iopos) and return nil if tagdatalength.nil?
    tagdatalength *= 4

    tagdata = GCOVReading.read(@io, tagdatalength)
    @io.seek(iopos) and return nil if tagdata.nil?

    GCOVTag.new(tagidentifier, tagdata)
  end
end

class GCOVFunctionTagReader
  def initialize(io_or_string)
    @io = GCOVReading.io_from_io_or_string(io_or_string)
  end

  def read_function
    iopos = @io.tell

    identifier = GCOVReading.read_uint32(@io)
    @io.seek(iopos) and return nil if identifier.nil?

    scratch = GCOVReading.read_uint32(@io)
    @io.seek(iopos) and return nil if scratch.nil?

    name = GCOVReading.read_string(@io)
    @io.seek(iopos) and return nil if name.nil?

    GCOVFunction.new(identifier, name)
  end
end

class GCOVBlocksTagReader
  def initialize(io_or_string)
    @io = GCOVReading.io_from_io_or_string(io_or_string)
  end

  def read_blocks
    blocks = []

    until @io.eof?
      flags = GCOVReading.read_uint32(@io)
      break if flags.nil?

      blocks << GCOVBlock.new(flags)
    end

    blocks
  end
end

class GCOVArcsTagReader
  def initialize(io_or_string)
    @io = GCOVReading.io_from_io_or_string(io_or_string)
  end

  def read_arcs
    block_number = GCOVReading.read_uint32(@io)

    arcs = []

    until @io.eof?
      destination = GCOVReading.read_uint32(@io)
      break if destination.nil?

      flags = GCOVReading.read_uint32(@io)
      break if flags.nil?

      arcs << GCOVArc.new(destination, flags)
    end

    [block_number, arcs]
  end
end

class GCOVLinesTagReader
  def initialize(io_or_string)
    @io = GCOVReading.io_from_io_or_string(io_or_string)
  end

  def read_lines
    block_number = GCOVReading.read_uint32(@io)

    line_numbers = {}

    filename = nil
    until @io.eof?
      line_number = GCOVReading.read_uint32(@io)
      break if line_number.nil?

      if line_number == 0
        filename = GCOVReading.read_string(@io)
        break if filename.nil?
        next
      end

      line_numbers_for_file = line_numbers[filename]
      line_numbers[filename] = line_numbers_for_file = [] if line_numbers_for_file.nil?

      line_numbers_for_file << line_number
    end

    [block_number, line_numbers]
  end
end

class GCOVCountsTagReader
  def initialize(io_or_string)
    @io = GCOVReading.io_from_io_or_string(io_or_string)
  end

  def read_counts
    counts = []

    until @io.eof?
      count = GCOVReading.read_uint64(@io)
      break if count.nil?

      counts << count
    end

    counts
  end
end
