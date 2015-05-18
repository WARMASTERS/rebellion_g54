module RebellionG54; class Role
  def self.to_s(role_sym)
    role_sym.to_s.upcase.gsub('_', ' ')
  end

  def self.to_class_name(role_sym)
    role_sym.to_s.split('_').map(&:capitalize).join
  end

  # Role => [group, advanced?]
  ALL = {
    banker: [:finance, false].freeze,
    customs_officer: [:special_interests, true].freeze,
    director: [:communications, false].freeze,
    guerrilla: [:force, false].freeze,
    lawyer: [:special_interests, false].freeze,
    peacekeeper: [:special_interests, false].freeze,
    politician: [:special_interests, false].freeze,
  }.freeze
end; end
