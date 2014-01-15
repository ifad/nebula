Dir[File.expand_path('../../lib/nebula/**/*.rb', __FILE__)].each { |f| require f }

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  # allows it { expects(blah).to...
  config.include(Module.new do
    def self.included(base)
      base.class_eval { alias_method :expects, :expect }
    end
  end)

  config.after(:each) do
    Nebula::Node.destroy_all
  end

  # test database
  Nebula.database = {
    dbname:   'nebula_test',
    user:     'nebula',
    password: 'nebula'
  }
end
