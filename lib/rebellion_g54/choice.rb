module RebellionG54; class Choice
  attr_reader :description
  def initialize(description, &block)
    @description = description
    @block = block
  end

  def needs_args?
    !@block.parameters.empty?
  end

  # Expected by Decision::Base#take_choice to return [Boolean(success), String(error_message)]
  def call(args)
    @block.call(args)
  end
end; end
