# vim: et sw=2

require_relative 'gcov_reading'
require 'stringio'

class Stcoverage
  def self.coverage(files = nil)
    c = self.new(files)
    yield c if block_given?
    c.coverage
  end

  def initialize(files = nil)
    @functions = []

    unless files.nil?
      files = [*files]
      files.select{ |x| x.end_with?('.gcno') }.each{ |f| add_gcno_file(f) }
      files.select{ |x| x.end_with?('.gcda') }.each{ |f| add_gcda_file(f) }
    end
  end

  attr_reader :functions

  def add_gcno_file(fname)
    io = open(fname, 'rb') or return false
    add_gcno_io(io)
  end

  def add_gcno_io(io)
    reader = GCOVFileReader.new(io)

    header = reader.read_header
    return false if header.nil? or not header.is_gcno?
    return false unless supported_version?(header.version)

    function = nil
    success = true

    until io.eof?
      tag = reader.read_tag
      break if tag.nil?

      case tag.tag
      when 0
      when GCOVTag::TAG_FUNCTION
        r = GCOVFunctionTagReader.new(tag.data)
        function = r.read_function
        (success = false) and break if function.nil?
        @functions << function
      when GCOVTag::TAG_BLOCKS
        r = GCOVBlocksTagReader.new(tag.data)
        blocks = r.read_blocks
        (success = false) and break if blocks.nil?
        function.blocks.concat(blocks)
      when GCOVTag::TAG_ARCS
        r = GCOVArcsTagReader.new(tag.data)
        block_number, arcs = r.read_arcs
        (success = false) and break if block_number.nil?
        block = function.blocks[block_number]
        block.arcs.concat(arcs) unless block.nil?
      when GCOVTag::TAG_LINES
        r = GCOVLinesTagReader.new(tag.data)
        block_number, line_numbers = r.read_lines
        (success = false) and break if block_number.nil?
        block = function.blocks[block_number]
        block.line_numbers.merge!(line_numbers){ |_, v1, v2| v1 + v2 } unless block.nil?
      end
    end

    success
  end

  def add_gcda_file(fname)
    io = open(fname, 'rb') or return false
    add_gcda_io(io)
  end

  def add_gcda_io(io)
    reader = GCOVFileReader.new(io)

    header = reader.read_header
    return false if header.nil? or not header.is_gcda?
    return false unless supported_version?(header.version)

    function = nil
    success = true

    until io.eof?
      tag = reader.read_tag
      break if tag.nil?

      case tag.tag
      when 0
      when GCOVTag::TAG_FUNCTION
        r = GCOVFunctionTagReader.new(tag.data)
        functionref = r.read_function
        functions = @functions.select{ |candidate| candidate.identifier == functionref.identifier }
        (success = false) and break unless functions.count == 1
        function = functions.first
      when GCOVTag::TAG_COUNTER
        r = GCOVCountsTagReader.new(tag.data)
        counts = r.read_counts
        function.blocks.each do |block|
          block.arcs.each do |arc|
            unless arc.flags_set?(GCOVArc::FLAG_COMPUTEDCOUNT)
              count = counts.shift
              arc.count += count unless count.nil?
            end
          end
        end
      end
    end

    success
  end

  def coverage
    @functions.map{ |f| f.coverage }.reduce({}) do |memo, o|
      memo.merge(o) do |_, a1, a2|
        a1.merge(a2){ |_, b1, b2| b1 + b2 }
      end
    end
  end

  private

  def supported_version?(version)
    case version
    when GCOVHeader::VERSION_402
      true
    else
      false
    end
  end
end
