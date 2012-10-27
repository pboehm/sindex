module Sindex

  class Series

    attr_accessor :de_episodes, :en_episodes

    def initialize
      @de_episodes = {}
      @en_episodes = {}
    end

    def has_german_episodes?
      ! @de_episodes.empty?
    end

    def has_english_episodes?
      ! @en_episodes.empty?
    end

    # Public: Adds an existing episode to the list of episodes
    #
    #   :filename - the filename to the episode
    #   :language - language in which the episode was watched :de/:en
    #
    def add_episode(filename, language=:de)
      if id = SeriesIndex.extract_episode_identifier(filename)
        if language == :de
          @de_episodes[id] = filename
        else
          @en_episodes[id] = filename
        end
      end
    end

    # Public: Is Episode already watched
    #
    #   :episode_data - data that hoölds the episode identifier
    #   :language - the language in which the episode is available :de/:en
    def is_episode_existing?(episode_data, language=:de)
      if id = SeriesIndex.extract_episode_identifier(episode_data)
        if language == :de
          return @de_episodes.has_key? id
        else
          return @en_episodes.has_key? id
        end
      end

    end

  end
end
