# Generated by generate-specs.rb
require 'helper'

describe_moneta "adapter_sequel" do
  def new_store
    Moneta::Adapters::Sequel.new(:db => (defined?(JRUBY_VERSION) ? "jdbc:sqlite:" : "sqlite:") + File.join(make_tempdir, "adapter_sequel"))
  end

  def load_value(value)
    Marshal.load(value)
  end

  include_context 'setup_store'
  it_should_behave_like 'increment'
  it_should_behave_like 'null_stringkey_stringvalue'
  it_should_behave_like 'persist_stringkey_stringvalue'
  it_should_behave_like 'returndifferent_stringkey_stringvalue'
  it_should_behave_like 'store_stringkey_stringvalue'
end
