module RebellionG54; class Role
  def self.to_s(role_sym)
    role_sym.to_s.upcase.gsub('_', ' ')
  end

  def self.to_class_name(role_sym)
    role_sym.to_s.split('_').map(&:capitalize).join
  end

  # Role => [group, advanced?]
  ALL = {
    banker: [:finance, false],
    capitalist: [:finance, true],
    crime_boss: [:force, true],
    communist: [:special_interests, true],
    customs_officer: [:special_interests, true],
    director: [:communications, false],
    farmer: [:finance, false],
    foreign_consular: [:special_interests, true],
    general: [:force, false],
    guerrilla: [:force, false],
    intellectual: [:special_interests, false],
    judge: [:force, false],
    lawyer: [:special_interests, false],
    mercenary: [:force, true],
    missionary: [:special_interests, true],
    newscaster: [:communications, false],
    peacekeeper: [:special_interests, false],
    politician: [:special_interests, false],
    priest: [:special_interests, false],
    producer: [:communications, true],
    protestor: [:special_interests, true],
    reporter: [:communications, false],
    speculator: [:finance, true],
    spy: [:finance, false],
    writer: [:communications, true],

    # Anarchy
    paramilitary: [:force, true],
    plantation_owner: [:finance, true],
  }.freeze

  ALL.values.each(&:freeze)
end; end
