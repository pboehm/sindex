require 'nokogiri'

module Sindex

  class SeriesIndex

    attr_reader :options, :series_data

    # Public: instantiate a new series_index
    #
    # options  - Options (default: {})
    #                :files  - Array of series indizes
    #
    def initialize(options = {})
      @options = {files: [], }.merge(options)

      @series_data = Hash.new
      @options[:files].each do |file|
        @series_data.merge!(parse_file(file))
      end

    end

    # Public: checks if there are entries in the index
    #
    # Returns true if there no entries loaded
    def empty?
      @series_data.length == 0
    end

    # Public: Check if a supplied episode is in the index
    #
    # series_name - Name of the series in the index
    # episode_text - episode data
    #
    # Returns true if the episode is existing, false otherwise
    def episode_existing?(series_name, episode_text)
      series_name.downcase!

      if @series_data[series_name]

          if id = SeriesIndex.extract_episode_identifier(episode_text)
            if @series_data[series_name][id]
              return true
            end
          end
      end

      return false
    end

    # Public: checks if the seriesname in the supplied data is in the index
    #
    # episode_text  - data that contains the episode information
    #
    # Returns true if the series is in the index, false otherwise
    def is_series_in_index?(episode_text)

      if series_name = SeriesIndex.extract_seriesname(episode_text)
        if @series_data[series_name.downcase]
          return true
        end
      end

      return false
    end

    # Public: tries to extract the seriesname from supplied data
    #
    # data - data that holds the episode information
    #
    # Returns the seriesname or nil if there is no seriesname
    def self.extract_seriesname(data)
      if md = data.match(/(.+?)S\d+E\d+/)
        return md[1].gsub(/\./, " ").strip
      end
      nil
    end

    # Public: tries to extract the episode identifier from the episode data
    #
    # data - data that holds the episode information
    #
    # Returns the identifier xx_xx or nil if there is no identifier
    def self.extract_episode_identifier(data)
      if md = data.match(/S(\d+)E(\d+)/i)
        return "%s_%s" % [md[1].to_i, md[2].to_i]
      end
      nil
    end

    private

    # Internal: parse this file to a hash indexed by seriesname
    #
    #  file - path to the xml file
    #
    # Returns a Hash indexed by seriesname with Hashes as values
    #
    #     hash = {
    #       "Chase": {
    #          "1_1": "S01E01 - test.avi",
    #       }
    #     }
    def parse_file(file)

      series_data = Hash.new

      content = File.open(file, "r").read
      doc = Nokogiri::XML(content)

      doc.css("serienindex > directory").each do |series_node|

        title = series_node[:name]
        next unless title && title.match(/\w+/)

        title.downcase!

        series = Hash.new
        series_node.css("file").each do |file_node|

          filename = file_node[:name]
          next unless filename

          if id = SeriesIndex.extract_episode_identifier(filename)
            series[id] = filename
          end
        end

        series_data[title] = series
      end

      series_data
    end

  end

end
