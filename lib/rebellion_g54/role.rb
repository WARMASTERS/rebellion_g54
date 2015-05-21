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
    crime_boss: [:force, true].freeze,
    communist: [:special_interests, true].freeze,
    customs_officer: [:special_interests, true].freeze,
    director: [:communications, false].freeze,
    farmer: [:finance, false].freeze,
    foreign_consular: [:special_interests, true].freeze,
    general: [:force, false].freeze,
    guerrilla: [:force, false].freeze,
    intellectual: [:special_interests, false].freeze,
    judge: [:force, false].freeze,
    lawyer: [:special_interests, false].freeze,
    mercenary: [:force, true].freeze,
    missionary: [:special_interests, true].freeze,
    newscaster: [:communications, false].freeze,
    peacekeeper: [:special_interests, false].freeze,
    politician: [:special_interests, false].freeze,
    priest: [:special_interests, false].freeze,
    producer: [:communications, true].freeze,
    protestor: [:special_interests, true].freeze,
    reporter: [:communications, false].freeze,
    speculator: [:finance, true].freeze,
    spy: [:finance, false].freeze,
    writer: [:communications, true].freeze,
  }.freeze
end; end
