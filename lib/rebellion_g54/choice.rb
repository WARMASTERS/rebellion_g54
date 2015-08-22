module RebellionG54; class Choice
  attr_reader :description
  attr_reader :args
  attr_reader :available
  attr_reader :why_unavailable
  alias_method :available?, :available

  def initialize(description, args = [], &block)
    @description = description
    @args = args.freeze
    @block = block
    @available = true
    @why_unavailable = nil
  end

  def is_action?
    # This relies on a very shaky assumption, but it's true so far...
    !@block.parameters.empty?
  end

  # Expected by Decision::Base#take_choice to return [Boolean(success), String(error_message)]
  def call(args)
    raise "#{description} is unavailable because #{@why_unavailable}" unless @available
    @block.call(args)
  end

  def unavailable!(reason)
    @why_unavailable = reason
    @available = false
  end
end; end
