require "kevins_propietary_brain/version"

module KevinsPropietaryBrain
## All Brains must be put in the PlayerBrain module to allow them to be picked up by the game initalizer
  class Brain
    # Pick some number of emoji to represent your brain.
    # by convention, all brain emoji end with `:neckbeard:`.
    # The list of supported emojis can be found
    # here: http://www.emoji-cheat-sheet.com/
    def self.emoji
      ':octopus::neckbeard:'
    end

    attr_accessor :player, :role
    attr_reader :sheriff_shooters

    def initialize
      @events = []
      @sheriff_shooters = []
    end

    # you have the option of picking from many cards, pick the best one.
    def pick(number, *cards)
      ordered = cards.flatten.map do |card|
        i = card_preference.map { |preference| card.type == preference }.index(true)
        {card: card, index: i}
      end
      ordered.sort_by { |h| h[:index] || 99 }.first(number).map {|h| h[:card] }
    end
    def card_preference
      [Card.wells_fargo_card, Card.stage_coach_card, Card.jail_card, Card.barrel_card,
        Card.beer_card, Card.indians_card, Card.gatling_card, Card.scope_card, Card.mustang_card,
        Card.missed_card, Card.bang_card, Card.revcarbine_card, Card.remington_card, Card.winchester_card,
        Card.volcanic_card, Card.panic_card, Card.cat_balou_card]
    end
    #After instantiation the Game will pass the brain two characters from the characters in the models/characters folder, the choose_character method must return one of the two characters.
    def choose_character(character_1, character_2)
      (character_preference & [character_1, character_2]).first
    end
    def character_preference
      [:PaulRegretPlayer,:JourdonnaisPlayer,:RoseDoolanPlayer,
       :VeraCusterPlayer,:BlackJackPlayer,:BartCassidyPlayer,
       :SidKetchumPlayer,:SlabTheKillerPlayer,:JesseJonesPlayer,
       :LuckyDukePlayer,:SuzyLafayettePlayer,:WillyTheKidPlayer,
       :VultureSamPlayer,:CalamityJanetPlayer,:PedroRamirezPlayer,:KitCarlsonPlayer,
       :ElGringoPlayer,]
    end

    #This method is called on your brain when you are the target of a card that has a bang action (a missable attack). Your brain is given the card that attacked them.  The method should return a card from your hand
    def target_of_bang(card, targetter, missed_needed)
      player.tap_badge("annoyedly")
      if player.hand.count{ |x| x.type == Card.missed_card } >= missed_needed
        player.hand.select{|x| x.type == Card.missed_card}.first(missed_needed)
      else
        []
      end
    end
    def target_of_indians(card, targetter)
      player.tap_badge("menacingly")
      player.from_hand(Card.bang_card)
    end
    def target_of_duel(card, targetter)
      player.from_hand(Card.bang_card)
    end

    #This method is called if your hand is over the hand limit, it returns the card that you would like to discard.
    # Returning nil or a card you don't have is a very bad idea. Bad things will happen to you.
    def discard
      ordered = player.hand.map do |card|
        i = card_preference.map { |preference| card.type == preference }.index(true)
        {card: card, index: i}
      end
      ordered.sort_by { |h| h[:index] || 99 }.last.try(:fetch, :card)
    end

    #This is the method that is called on your turn.
    def play
      bangs_played = 0
      while !player.hand.find_all(&:draws_cards?).empty?
        player.hand.find_all(&:draws_cards?).each {|card| player.play_card(card)}
      end
      play_guns
      player.hand.each do |card|
        target = find_target(card)
        next if skippable?(card, target, bangs_played)
        bangs_played += 1 if card.type == Card.bang_card
        player.play_card(card, target, :hand)
      end
    end

    def draw_choice(choices)
      choices.last
    end

    private
    def over_bang_limit?(n)
      return false if player.character == "Character::WillyTheKidPlayer"
      return false if player.in_play.detect{ |x| x.type == Card.volcanic_card }
      return false if n < 1
      true
    end

    def skippable?(card, target, bangs_played)
      missed = card.type == Card.missed_card
      unjailable = card.type == Card.jail_card && target.sheriff?
      too_many_bangs = card.type == Card.bang_card && over_bang_limit?(bangs_played)
      !target || missed || unjailable || too_many_bangs
    end

    def find_target(card)
      if role == 'sheriff'
        find_target_for_sheriff(card)
      elsif role == 'outlaw'
        find_target_for_outlaw(card)
      elsif role == 'renegade'
        find_target_for_renegade(card)
      elsif role == 'deputy'
        weakest_non_sheriff_in_range_of(card)
      end
    end

    def find_target_for_renegade(card)
      if player.players.size > 1
        weakest_non_sheriff_in_range_of(card)
      else
        sheriff
      end
    end

    def find_target_for_outlaw(card)
      player.players_in_range_of(card).include?(sheriff) ? sheriff : weakest_player_in_range_of(card)
    end

    def find_target_for_sheriff(card)
      players_in_range = player.players_in_range_of(card)
      weakest_players = players_in_range.sort_by { |player| player.health }
      (weakest_players & sheriff_shooters).first || weakest_players.first
    end

    def weakest_non_sheriff_in_range_of(card)
      players_in_range = player.players_in_range_of(card)
      weakest_players = players_in_range.sort_by { |player| player.health }
      weakest_players.find { |player| !player.sheriff? }
    end

    def weakest_player_in_range_of(card)
      in_range = player.players_in_range_of(card)
      in_range.min_by { |p| p.health } || in_range.first
    end

    def sheriff
      player.players.find(&:sheriff?)
    end

    def play_guns
      guns = player.hand.find_all(&:gun?)
      return if guns.empty?
      longest_ranged_gun = guns.max { |gun| gun.range }
      player.play_card(longest_ranged_gun) if should_play_gun?(longest_ranged_gun)
    end

    def should_play_gun?(longest_ranged_gun)
      existing_gun = player.in_play.find(&:gun?)
      return true unless existing_gun
      longest_ranged_gun && longest_ranged_gun.range > existing_gun.range
    end
  end
end
