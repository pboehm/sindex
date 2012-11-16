require File.join(File.dirname(__FILE__), "test_helper.rb")

class TestData

  TESTFILE_DIRECTORY = File.join(File.dirname(__FILE__), 'tmp')
  SERIES_STORAGE_DIR = File.join(TESTFILE_DIRECTORY, 'series')

  EPISODES = {
    :chuck => { :filename => "S04E11 - Pilot.avi",
                :series => "Chuck",
                :data => { :from => '1_1', :to => '4_10' }
    },
    :tbbt  => { :filename => "S05E06 - Pilot.avi",
                :series => "The Big Bang Theory",
                :data => { :from => '1_1', :to => '5_9',
                           :exclude => ['5_5', '5_6', '5_7', '5_8', ] }
    },
    :crmi  => { :filename => "S01E04 - Pilot.avi",
                :series => "Criminal Minds",
                :data => { :from => '1_1', :to => '1_3' }
    },
    :seap  => { :filename => "S01E04 - Pilot.avi",
                :series => "Sea Patrol",
                :data => { :from => '1_1', :to => '1_3' }
    },
    :drhou => { :filename => "S05E01 - First Episode.avi",
                :series => "Dr House",
                :data => { :from => '1_1', :to => '4_20' }
    },
    :spook => { :filename => "S10E01 - First Episode.avi",
                :series => "Spooks",
                :data => { :from => '1_1', :to => '9_20' }
    },
    :numbe => { :filename => "S04E31 - High Episode.avi",
                :series => "Numb3rs",
                :data => { :from => '1_1', :to => '4_30' }
    },
  }

  # create test data
  def self.create
    _create_directories
    EPISODES.each do |key,value|
      create_series(value[:series], value[:data])
    end
  end

  # remove files
  def self.clean
    remove_series_dir
  end

  class << self

    # this method creates a directory structure for a given
    # series with the opportunity to exclude some episodes
    def create_series(seriesname, options={})
      default = { :from => '1_0', :to => '1_0',
                  :max => 30, :exclude => [] }
      options = default.merge(options)

      series_dir = File.join(SERIES_STORAGE_DIR, seriesname)
      _create_dir(series_dir)

      from = _split_entry(options[:from])
      to   = _split_entry(options[:to])

      for season in from[0]..to[0]

        season_dir = File.join(series_dir, "Staffel %02d" % season)
        _create_dir(season_dir)

        episodes = (season == to[0]) ? to[1] : options[:max]

        for episode in 1..episodes.to_i

          # check for excludes
          definition = "%d_%d" % [ season, episode ]
          next if options[:exclude].include? definition

          # build and create file
          file = "S%02dE%02d - Episode %02d.mkv" % [ season, episode,episode ]
          episode_file = File.join(season_dir, file)
          _create_file(episode_file)
        end
      end

    end

    # remove testfile directory
    def remove_series_dir
      if File.directory?(SERIES_STORAGE_DIR)
        FileUtils.remove_dir(SERIES_STORAGE_DIR)
      end
    end

    def _split_entry(definition)
      definition.split(/_/)
    end

    def _create_directories
      _create_dir TESTFILE_DIRECTORY
      _create_dir SERIES_STORAGE_DIR
    end

    def _create_dir(dir)
      FileUtils.mkdir(dir) unless File.directory?(dir)
    end

    def _create_file(file)
      FileUtils.touch(file) unless File.file?(file)
    end
  end

end
