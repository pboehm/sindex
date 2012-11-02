module Sindex

  class Series

    attr_accessor :episodes, :receive_updates

    def initialize(receive_updates=true)
      @episodes = {}
      @receive_updates=receive_updates
    end

    # Public: determines if thos series contains episode in the
    # supplied language
    #
    #   :language - language-symbol :de/:en/...
    def has_episodes_in_language?(language)
      ! @episodes[language].nil?
    end

    # Public: Adds an existing episode to the list of episodes
    #
    #   :filename - the filename to the episode
    #   :language - language in which the episode was watched :de/:en
    #
    def add_episode(filename, language=:de, all_before=false)
      if id = SeriesIndex.extract_episode_identifier(filename)

        if @episodes[language].nil?
          @episodes[language] = {}
        end

        # mark all previous episodes as watched if `all_before`
        if all_before
          ids = build_up_ids_before_another_id(id)
          for virtual_id in ids
            @episodes[language][virtual_id] = :virtual
          end
        end

        @episodes[language][id] = filename
      end
    end

    # Public: Is Episode already watched
    #
    #   :episode_data - data that hoölds the episode identifier
    #   :language - the language in which the episode is available :de/:en
    def is_episode_existing?(episode_data, language=:de)

      # if we are not interested in updates this method responds
      # always with true
      return true unless @receive_updates

      if id = SeriesIndex.extract_episode_identifier(episode_data)
        if not @episodes[language].nil?
          return @episodes[language].has_key? id
        end
      end

      false
    end

    private

    # Private: buils up a list of strings that are IDs [season]_[episode]
    # smaller than the supplied id
    #
    # Returns list of strings in the structure above
    def build_up_ids_before_another_id(id)
      if md = id.match(/^(\d+)_(\d+)$/)
        season = md[1].to_i
        episode = md[2].to_i
        virtual_ids= []

        1.upto(season).each do |s|
          episode_range = (1..50).to_a
          if s == season
            episode_range = (1...episode).to_a
          end

          episode_range.each do |e|
            virtual_ids << "%d_%d" % [s, e]
          end
        end

        return virtual_ids
      else
        raise AttributeError, "the supplied id was not an id"
      end
    end
  end
end
