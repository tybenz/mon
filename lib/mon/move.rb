module Mon
  class Move
    CRITICAL_MULTIPLIER = 2

    attr_reader :name

    def initialize(row)
      @name         = row[:identifier].upcase
      @attack_class = row[:damage_class_id]
      @type         = row[:type_id]

      # TODO: Figure out why some moves power are nil
      @power = row[:power] || 10
    end

    # http://bulbapedia.bulbagarden.net/wiki/Damage
    def damage(attacker, defender)
      if Pokedex.immune?(@type, defender.types)
        @efficacy = 0
      else
        calculate(attacker, defender)
      end
    end

    def super_effective?
      @efficacy > 1
    end

    def not_effective?
      @efficacy < 1
    end

    def critical?
      @critical == CRITICAL_MULTIPLIER
    end

    private

      def calculate(attacker, defender)
        # STAB is the same-type attack bonus. This is equal to 1.5 if the attack is of the same type as the user, and 1 if otherwise.
        stab = attacker.types.include?(@type) ? 1.5 : 1

        # Type can be either 0, 0.25, 0.5, 1, 2, or 4 depending on the type of attack and the type of the defending Pokémon.
        # Multiple types are multiplied with each other.
        @efficacy = Pokedex.move_efficacies(@type, defender.types).inject(1) do |total, move_efficacy|
          total *= (move_efficacy / 100.0)
        end

        # Critical is 2 for a critical hit in Generations I-V, 1/16 chance
        @critical = rand(16) == 0 ? CRITICAL_MULTIPLIER : 1

        modifier = stab * @efficacy * @critical * rand(0.85..1)

        (
          (
            ((2 * attacker.level + 10) / 250.0) *
            (attacker.attack_for(@attack_class) / defender.defense_for(@attack_class).to_f) *
            @power +
            2
          ) * modifier
        ).floor
      end
  end
end
