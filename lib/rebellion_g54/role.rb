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
    capitalist: [:finance, true].freeze,
    customs_officer: [:special_interests, true].freeze,
    director: [:communications, false].freeze,
    farmer: [:finance, false].freeze,
    general: [:force, false].freeze,
    guerrilla: [:force, false].freeze,
    intellectual: [:special_interests, false].freeze,
    judge: [:force, false].freeze,
    lawyer: [:special_interests, false].freeze,
    newscaster: [:communications, false].freeze,
    peacekeeper: [:special_interests, false].freeze,
    politician: [:special_interests, false].freeze,
    priest: [:special_interests, false].freeze,
    reporter: [:communications, false].freeze,
    spy: [:finance, false].freeze,
  }.freeze
end; end
