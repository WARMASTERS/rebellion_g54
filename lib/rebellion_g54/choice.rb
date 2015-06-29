module RebellionG54; class Choice
  attr_reader :description
  def initialize(description, &block)
    @description = description
    @block = block
  end

  def is_action?
    # This relies on a very shaky assumption, but it's true so far...
    !@block.parameters.empty?
  end

  # Expected by Decision::Base#take_choice to return [Boolean(success), String(error_message)]
  def call(args)
    @block.call(args)
  end
end; end
