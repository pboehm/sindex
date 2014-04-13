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

    # Public: Check if the series is watched in this specified language
    #
    # series_name - Name of the series in the index
    # language - either :de or :en
    #
    # Returns true if the series is watched in the supplied language
    def is_series_in_this_language?(series_name, language=:de)

      series_name = series_name_in_index(series_name)

      if series_name and series = @series_data[series_name]
        return series.has_episodes_in_language?(language)
      end

      false
    end

    # Public: Builds up an index from a directory full of series
    #
    #  :directory - path to the directory that holds the series
    #  :language - the language symbol which the episodes in the directory have
    #
    def build_up_index_from_directory(directory, language=:de)
      raise ArgumentError, "you have not supplied an existing directory" unless
        File.directory? directory

        Dir.chdir(directory)

        Dir['*'].sort.each do |directory|
          next unless File.directory? directory

          series = Series.new

          Dir["#{directory}/**/*"].sort.each do |episode|
            next unless File.file? episode
            basename_episode = File.basename(episode)

            next unless SeriesIndex.extract_episode_identifier(basename_episode)
            next unless basename_episode.match(/\.(mkv|mov|avi|flv|mp4|mpg|wmv)$/)

            series.add_episode(basename_episode, language)
          end

          @series_data[directory] = series
        end

    end

    # Public: Dumps the in-memory version of the index back to a xml file
    #
    #   :filename - path to file in which the index should be dumped
    def dump_index_to_file(filename)

      tree = build_up_xml_tree_from_index

      File.open(filename, "w") do |f|
        f.write(tree);
      end
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


    # Public: Adds episode to index
    #
    #   :series_name
    #   :episode
    #   :language
    def add_episode_to_index(series_name, episode, language=:de)

      series_name = series_name_in_index(series_name)

      if series_name and series = @series_data[series_name]
        series.add_episode(episode, language)
      end
    end


    # Public: Adds a new series to the index with an S01E00 episode
    def add_new_series_to_index(series_name)
      raise ArgumentError, "series (#{ series_name }) is already in index" if
          is_series_in_index?(series_name)

      series = Sindex::Series.new
      series.add_episode("S01E00 - some really cool episode name.mkv")

      @series_data[series_name] = series
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


      # Public: tries to match the suppplied seriesname pattern
      #         agains the series
      #
      # seriesname     - the seriesname that comes from the index
      # series_pattern - the series_name that has to be checked
      #                  agains the seriesname
      # fuzzy          - does a fuzzy match against the series
      #
      # Returns true if it matches otherwise false
      def does_the_series_match?(seriesname, series_pattern, fuzzy=false)

        if seriesname.match(/#{series_pattern}/i)
          # if pattern matches the series directly
          return true

        elsif fuzzy
          # start with a pattern that includes all words from
          # series_pattern and if this does not match, it cuts
          # off the first word and tries to match again
          #
          # if the pattern contains one word and if this
          # still not match, the last word is splitted
          # characterwise, so that:
          #  crmi ==> Criminal Minds
          name_words = series_pattern.split(/ /)
          word_splitted = false

          while ! name_words.empty?

            pattern = name_words.join('.*')
            return true if seriesname.match(/#{pattern}/i)

            # split characterwise if last word does not match
            if name_words.length == 1 && ! word_splitted
              name_words = pattern.split(//)
              word_splitted = true
              next
            end

            # if last word was splitted and does not match than break
            # and return empty resultset
            break if word_splitted

            name_words.delete_at(0)
          end
        end

        false
      end

    end

    private

    # Private: this methode places the information from index into a
    # new XML tree
    #
    # Returns XML tree
    def build_up_xml_tree_from_index

      builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.seriesindex {
          @series_data.sort.map do |seriesname, data|
            attrs = {:name => seriesname}
            attrs[:receive_updates] = false unless data.receive_updates

            xml.series(attrs) {

              # write alias definition if there are any
              @series_aliases.select { |al,re| re == seriesname }.each do |_alias,real|
                xml.alias(:to => _alias)
              end

              # write the different episodes
              data.episodes.each do |language, episodes|
                add_all_before_flag=false

                xml.episodes(:lang => language) {
                  episodes.each do |episode_id, filename|

                    # only dump real episodes not virtual episodes that are
                    # added because of the `all_before`-flag
                    if filename == :virtual
                      add_all_before_flag=true
                      next
                    end

                    args = {:name => filename}
                    if add_all_before_flag
                      args[:all_before] = true
                      add_all_before_flag=false
                    end

                    xml.episode(args)
                  end
                }
              end
            }
          end
        }
      end

      builder.to_xml
    end

    # Internal: finds the seriesname for the supplied name in index
    #
    # It is used to apply an alias for series and finds the real series name
    #
    # Returns the seriesname in index or nil if it does not exist
    def series_name_in_index(name)

      escaped = Regexp.escape(name)

      matching_series = @series_data.keys.grep(/^#{ escaped }$/i).first
      return matching_series if matching_series

      @series_aliases.each do |key, val|
        if key.match(/^#{ escaped }$/i)
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

        s.receive_updates = false if series[:receive_updates].match(/false/i)

        series.css('episodes').each do |episodes|
          language = episodes['lang'].to_sym

          episodes.css('episode').each do |episode|
            episode['name'] || next

            # process `all_before` flag
            all_before=false
            if episode['all_before'] && episode['all_before'].match(/true/i)
              all_before=true
            end

            s.add_episode(episode['name'], language, all_before)
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
      xml_content = add_dtd_reference(File.read(file).lines)

      options = Nokogiri::XML::ParseOptions::DEFAULT_XML |
                  Nokogiri::XML::ParseOptions::DTDLOAD

      doc = Nokogiri::XML::Document.parse(xml_content, nil, nil, options)
      doc.external_subset || raise(XmlDTDError, "DTD could not be processed")

      errors = doc.external_subset.validate(doc)

      if not errors.empty?
        error = XmlMalformedError.new
        error.errors = errors
        raise error
      end

      doc
    end

    # Internal: fixes the path that points to the dtd file in the seriesindex
    def add_dtd_reference(content)
      dtd_path = File.expand_path(
        File.join(File.dirname(__FILE__), '../../res/seriesindex.dtd'))

      content.delete_if {|line| line.match(/^.*DOCTYPE/) }
      content.insert(1, '<!DOCTYPE seriesindex SYSTEM "' + dtd_path +'">')

      content.join("\n")
    end
  end
end
