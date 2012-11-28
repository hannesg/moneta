# Generated file
require 'helper'
require 'fileutils'

begin

  describe "adapter_rugged" do

    before do
      @dir = File.join(make_tempdir, "adapter_rugged")
      @store = Juno::Adapters::Rugged.new(:dir => @dir)
    end

    after do
      @store.close.should == nil if @store
      FileUtils.rm_rf(@dir)
    end

    it_should_behave_like 'null_stringkey_stringvalue'
    it_should_behave_like 'store_stringkey_stringvalue'
    it_should_behave_like 'returndifferent_stringkey_stringvalue'

    describe "basic concurrency" do

      before do
        @other_store = Juno::Adapters::Rugged.new(:dir => @dir)
      end

      it "should find a value set externally" do
        @other_store['key'] = 'value'
        @store['key'].should == 'value'
      end

      it "should not find a value deleted externally" do
        @store['key'] = 'value'
        @other_store.delete('key')
        @store.key?('key').should be_false
      end

    end

  end

rescue LoadError => ex
  puts "Test adapter_rugged not executed: #{ex.message}"
rescue Exception => ex
  puts "Test adapter_rugged not executed: #{ex.message}"
end
