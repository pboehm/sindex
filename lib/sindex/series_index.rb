require 'nokogiri'

module Sindex

  class SeriesIndex

    attr_reader :options, :series_data, :index_file

    # Public: instantiate a new series_index
    #
    # options  - Options (default: {})
    #     :index_file - Path to the index file, should be supplied
    #
    def initialize(options = {})
      @options = {index_file: nil, }.merge(options)

      @index_file = @options[:index_file]
      @series_data = {}
      @series_aliases = {}

      if @index_file and File.file? @index_file
        parse_file(@index_file)
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
    def episode_existing?(series_name, episode_text, language=:de)

      series_name = series_name_in_index(series_name)

      if series_name and series = @series_data[series_name]
        return series.is_episode_existing?(episode_text, language)
      end

      false
    end

    # Public: checks if the seriesname in the supplied data is in the
    # index or an alias to a series
    #
    # episode_text  - data that contains the episode information
    # clean         - does the episode_data contains already the series name
    #
    # Returns true if the series is in the index, false otherwise
    def is_series_in_index?(episode_text, clean=false)

      if not clean and series_name = SeriesIndex.extract_seriesname(episode_text)
        episode_text = series_name
      end

      ! series_name_in_index(episode_text).nil?
    end

    class << self

      # Public: tries to extract the seriesname from supplied data
      #
      # data - data that holds the episode information
      #
      # Returns the seriesname or nil if there is no seriesname
      def extract_seriesname(data)
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
      def extract_episode_identifier(data)
        if md = data.match(/S(\d+)E(\d+)/i)
          return "%s_%s" % [md[1].to_i, md[2].to_i]
        end
        nil
      end

    end

    private

    # Internal: finds the seriesname for the supplied name in index
    #
    # It is used to apply an alias for series and finds the real series name
    #
    # Returns the seriesname in index or nil if it does not exist
    def series_name_in_index(name)

      @series_data.each do |key, val|
        if key.match(/#{name}/i)
          return key
        end
      end

      @series_aliases.each do |key, val|
        if key.match(/#{name}/i)
          return val
        end
      end

      nil
    end

    # Internal: parse this file to a hash indexed by seriesname
    #
    #  file - path to the xml file
    #
    def parse_file(file)

      doc = open_xml_file(file)

      doc.css("seriesindex > series").each do |series|

        series_name = series[:name]
        next unless series_name and series_name.match(/\w+/)

        s = Series.new()

        series.css('episodes').each do |episodes|
          language = episodes['lang'].match(/de/) ? :de : :en

          episodes.css('episode').each do |episode|
            episode['name'] || next

            s.add_episode(episode['name'], language)
          end
        end

        @series_data[series_name] = s

        # apply aliases
        series.css("alias").each do |series_alias|
          if series_alias['to'] and series_alias['to'].match(/\w+/)
            alias_name = series_alias['to']
            @series_aliases[alias_name] = series_name
          end
        end
      end

    end

    # Internal: wrapper around opening a xml file in Nokogiri with
    # external DTD definition
    #
    #   file - path to xml file
    #
    # returns Nokogiri XML Document
    def open_xml_file(file)
      options = Nokogiri::XML::ParseOptions::DEFAULT_XML |
                  Nokogiri::XML::ParseOptions::DTDLOAD

      doc = Nokogiri::XML::Document.parse(File.read(file), nil, nil, options)
      doc.external_subset || raise(XmlDTDError, "DTD could not be processed")

      errors = doc.external_subset.validate(doc)

      if not errors.empty?
        error = XmlMalformedError.new
        error.errors = errors
        raise error
      end

      doc
    end

  end

end
