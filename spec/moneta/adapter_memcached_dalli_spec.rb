# Generated by generate-specs.rb
require 'helper'

describe_moneta "adapter_memcached_dalli" do
  def new_store
    Moneta::Adapters::MemcachedDalli.new(:namespace => "adapter_memcached_dalli")
  end

  def load_value(value)
    Marshal.load(value)
  end

  include_context 'setup_store'
  it_should_behave_like 'expires'
  it_should_behave_like 'increment'
  it_should_behave_like 'null_stringkey_stringvalue'
  it_should_behave_like 'persist_stringkey_stringvalue'
  it_should_behave_like 'returndifferent_stringkey_stringvalue'
  it_should_behave_like 'store_stringkey_stringvalue'
end
