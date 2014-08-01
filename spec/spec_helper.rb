require 'blender'

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
  end
  config.backtrace_exclusion_patterns = []
end
