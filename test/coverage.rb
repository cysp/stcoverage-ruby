# vim: et sw=2

begin
  require 'simplecov'

  if ENV['COVERALLS_REPO_TOKEN'] || ENV['TRAVIS']
    begin
      require 'coveralls'
      SimpleCov.formatter = Coveralls::SimpleCov::Formatter
    rescue LoadError
    end
  end

  SimpleCov.start do
    add_filter '/test/'
  end
rescue LoadError
end
