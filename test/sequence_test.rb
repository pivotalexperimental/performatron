require File.dirname(__FILE__) + "/test_helper"

class SequenceTest < ActiveSupport::TestCase
  def setup
    Performatron::Sequence.loaded_sequences = {}
  end

  def test_new_sequences_are_added_to_loaded_scenarios
    assert Performatron::Sequence.loaded_sequences.empty?
    seq = Performatron::Sequence.new("test")
    assert Performatron::Sequence.loaded_sequences.values.include?(seq)
  end
end