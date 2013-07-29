# vim: et sw=2

if ENV['COVERALLS_REPO_TOKEN'] || ENV['TRAVIS']
  begin
    require 'coveralls'
    Coveralls.wear!
  rescue LoadError
  end
end
