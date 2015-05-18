require 'rebellion_g54/role'

module RebellionG54; class Card
  attr_reader :id, :role

  def initialize(id, role)
    @id = id
    @role = role
  end

  def to_s
    Role.to_s(@role)
  end

  def eql?(card)
    self.class.equal?(card.class) && @id == card.id
  end

  alias == eql?
end; end
