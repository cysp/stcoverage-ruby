# vim : et sw=2

require 'test/unit'

require 'stcoverage/stcoverage'

class TestInstantiation < Test::Unit::TestCase
  def test_simple
    cov = Stcoverage.new
    assert_not_nil(cov)
  end

  def test_files
    cov = Stcoverage.new('bleh')
    assert_not_nil(cov)

    cov = Stcoverage.new(['foo'])
    assert_not_nil(cov)

    cov = Stcoverage.new(['foo', 'bar'])
    assert_not_nil(cov)

    cov = Stcoverage.new(['foo', 'foo.gcno', 'bar', 'bar.gcda'])
    assert_not_nil(cov)
  end
end
