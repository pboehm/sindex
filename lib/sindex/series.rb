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
    def add_episode(filename, language=:de)
      if id = SeriesIndex.extract_episode_identifier(filename)

        if @episodes[language].nil?
          @episodes[language] = {}
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

  end
end
