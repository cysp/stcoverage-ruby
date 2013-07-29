# vim: et sw=2

class GCOVHeader
  MAGIC_GCNO = 'oncg'
  MAGIC_GCDA = 'adcg'
  VERSION_402 = '*204'
  STAMP_LLVM = 'MVLL'

  def initialize(magic, version, stamp)
    @magic = magic
    @version = version
    @stamp = stamp
  end

  attr_reader :magic
  attr_reader :version
  attr_reader :stamp

  def is_gcno?
    @magic == MAGIC_GCNO
  end

  def is_gcda?
    @magic == MAGIC_GCDA
  end
end

class GCOVTag
  TAG_FUNCTION = 0x01000000
  TAG_BLOCKS   = 0x01410000
  TAG_ARCS     = 0x01430000
  TAG_LINES    = 0x01450000
  TAG_COUNTER  = 0x01a10000

  def initialize(tag, data)
    @tag = tag
    @data = data
  end

  attr_reader :tag
  attr_reader :data
end

class GCOVFunction
  def initialize(identifier, name)
    @identifier = identifier
    @name = name
    @blocks = []
  end

  attr_reader :identifier
  attr_reader :name
  attr_reader :blocks

  def coverage
    @blocks.map{ |b| b.coverage }.reduce({}) do |memo, o|
      memo.merge(o) do |_, a1, a2|
        a1.merge(a2){ |_, b1, b2| b1 + b2 }
      end
    end
  end
end

class GCOVBlock
  FLAG_UNEXPECTED = 0x00000002

  def initialize(flags)
    @flags = flags
    @arcs = []
    @line_numbers = {}
  end

  attr_reader :flags
  attr_reader :arcs
  attr_reader :line_numbers

  def coverage
    count = @arcs.map{ |a| a.count }.reduce(0){ |a, e| a + e }
    coverage = {}
    @line_numbers.each do |filename, line_numbers|
      file_coverage = {}
      line_numbers.each{ |n| file_coverage[n] = (file_coverage[n] || 0) + count }
      coverage[filename] = file_coverage
    end
    coverage
  end

  def flags_set?(flags)
    (@flags & flags) == flags
  end
end

class GCOVArc
  FLAG_COMPUTEDCOUNT = 0x00000001
  FLAG_FAKE = 0x00000002

  def initialize(destination, flags)
    @destination = destination
    @flags = flags
    @count = 0
  end

  attr_reader :destination
  attr_reader :flags
  attr_accessor :count

  def flags_set?(flags)
    (@flags & flags) == flags
  end
end
