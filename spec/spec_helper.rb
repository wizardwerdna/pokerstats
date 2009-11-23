$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'pokerstats'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  
end

Spec::Matchers.define :be_hash_similar_with do |expected|
  match do |actual|
      @errors = []
      for key in (expected.keys + actual.keys).uniq
          @errors << {:expected => expected[key], :actual => actual[key], :key => key} unless expected[key] == actual[key]
      end
      @errors.empty?
  end
  failure_message_for_should do |hash|
    @errors.collect{|each| "expected #{each[:key].inspect} to be #{each[:expected].inspect}, but got #{each[:actual].inspect}"}.join(";\n")
  end
  failure_message_for_should_not do |hash|
    "the two elements are hash_similar"
  end
  description do
    "have the same values for corresponding keys"
  end
end
