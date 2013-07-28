# vim: sw=2 et

Gem::Specification.new do |s|
  s.name        = 'stcoverage'
  s.license     = 'MPL-2.0'
  s.version     = '0.1.0'
  s.authors     = ['Scott Talbot']
  s.email       = 's@chikachow.org'
  s.summary     = 'Ruby Gcov file parsing'
  s.files       = %w| LICENSE README.md lib/stcoverage.rb lib/stcoverage/stcoverage.rb lib/stcoverage/gcov_types.rb lib/stcoverage/gcov_reading.rb |
  s.homepage    = 'https://github.com/cysp/stcoverage-ruby'
end
