# vim : et sw=2

require 'test/unit'

require 'stcoverage/gcov_reading'

class TestGcovReading < Test::Unit::TestCase
  def test_simple
    cov = Stcoverage.new
    assert_not_nil(cov)
    assert_equal({}, cov.coverage)
  end

  def test_init_with_files
    cov = Stcoverage.new('bleh')
    assert_not_nil(cov)
    assert_equal({}, cov.coverage)

    cov = Stcoverage.new(['foo'])
    assert_not_nil(cov)
    assert_equal({}, cov.coverage)

    cov = Stcoverage.new(['foo', 'bar'])
    assert_not_nil(cov)
    assert_equal({}, cov.coverage)
  end

  def test_loading
    cov = Stcoverage.new
    assert(cov.add_gcno_file('test/f/foo.gcno'))
    assert_equal(['foo'], cov.functions.map{ |f| f.name })
    assert_equal(1, cov.functions[0].blocks.count)
    assert_equal(1, cov.functions[0].blocks[0].arcs.count)
    assert_equal({'foo.c' => [1]}, cov.functions[0].blocks[0].line_numbers)
    assert_equal({'foo.c' => {1 => 0}}, cov.coverage)
    assert(cov.add_gcda_file('test/f/foo.gcda'))
    assert_equal({'foo.c' => {1 => 1}}, cov.coverage)
    assert(cov.add_gcda_file('test/f/foo.gcda'))
    assert_equal({'foo.c' => {1 => 2}}, cov.coverage)
  end
end
