# encoding: UTF-8
require File.dirname(__FILE__) + '/test_helper.rb'
require 'fileutils'
require 'nokogiri'
require 'tempfile'

class TestIndex < Test::Unit::TestCase

  STANDARD_SINDEX_PATH = File.dirname(__FILE__) + '/seriesindex_example.xml'
  STANDARD_SINDEX_CONTENT = File.open(STANDARD_SINDEX_PATH).read

  def setup

    @tempfile = Tempfile.new('seriesindex')
    @tempfile.puts(STANDARD_SINDEX_CONTENT)
    @tempfile.flush

    @series_index = Sindex::SeriesIndex.new(index_file: @tempfile.path)
  end

  def test_instantiating
    index = Sindex::SeriesIndex.new()

    assert_instance_of Sindex::SeriesIndex, index
    assert_instance_of Hash, index.series_data
    assert_equal index.empty?, true
  end

  def test_that_the_path_of_DTD_file_has_been_updated
    content = File.open(@tempfile.path).read
    assert_equal content.match(/^.*DOCTYPE.*\"res\/seriesindex.xml\".*$/), nil
  end

  def test_parsing_a_valid_series_index
    assert_not_nil @series_index.series_data['Community']

    series = @series_index.series_data['Community']
    assert_equal series.has_episodes_in_language?(:de), true
    assert_not_nil series.episodes[:de]['1_1']
    assert_nil series.episodes[:de]['11_11']

    series = @series_index.series_data['Shameless US']
    assert_equal series.has_episodes_in_language?(:de), true
    assert_equal series.has_episodes_in_language?(:en), true
  end

  def test_that_series_aliases_take_place
    assert_equal @series_index.is_series_in_index?("Comm", true), true
    assert_equal @series_index.is_series_in_index?("unity", true), true
    assert_equal @series_index.is_series_in_index?("NoCommunity", true), false

    assert_equal @series_index.is_series_in_index?("shameless uS", true), true
  end

  def test_series_is_watched_in_a_specific_language
    assert_equal @series_index.is_series_in_this_language?("Community", :de), true
    assert_equal @series_index.is_series_in_this_language?("Community", :en), false

    assert_equal @series_index.is_series_in_this_language?("Shameless US", :de), true
    assert_equal @series_index.is_series_in_this_language?("Shameless US", :en), true
  end

  def test_check_for_episode_existance
    assert_equal true, @series_index.episode_existing?("Shameless US",
      "Shameless.US.S01E01.Just.Like.The.Pilgrims.Intended.German")

    assert_equal false, @series_index.episode_existing?("Shameless US",
      "Shameless.US.S01E09.Just.Like.The.Pilgrims.Intended.German")

    assert_equal true, @series_index.episode_existing?("Shameless US",
      "Shameless.US.S01E09.Just.Like.The.Pilgrims.Intended.German", :en)

    assert_equal true, @series_index.episode_existing?("Community",
        "Community.S01E01.Bankgeheimnis.DL.German.HDTV.XviD-GDR")

    assert_equal false, @series_index.episode_existing?("Community",
        "Community.S01E31.Bankgeheimnis.DL.German.HDTV.XviD-GDR")
  end

  def test_that_an_index_can_be_dumped_right
    filename = Tempfile.new('dumped_index').path
    @series_index.dump_index_to_file(filename)

    index = Sindex::SeriesIndex.new(index_file: filename)
    assert_equal index.is_series_in_index?("Community", true), true

    assert_equal false, index.episode_existing?("Shameless US",
      "Shameless.US.S01E09.Just.Like.The.Pilgrims.Intended.German")

    assert_equal true, index.episode_existing?("Shameless US",
      "Shameless.US.S01E09.Just.Like.The.Pilgrims.Intended.German", :en)
  end

  def test_that_the_receive_updates_flag_is_used
    assert_equal @series_index.series_data["Prison Break"].receive_updates, false

    # when the receive_updates flag  is set to false
    # :episode_existing? returns always true
    assert_equal true, @series_index.episode_existing?("Prison Break",
        "Prison.Break.S01E31.Bankgeheimnis.DL.German.HDTV.XviD-GDR")
  end

  def test_that_the_all_before_flag_is_interpreted
    assert_equal true, @series_index.episode_existing?("The Big Bang Theory",
        "Thee.Big.Bang.Theory.S01E31.Bankgeheimnis.DL.German.HDTV.XviD-GDR")
  end

  def test_that_the_all_before_flag_is_also_written_to_dumped_index
    filename = Tempfile.new('dumped_index').path
    @series_index.dump_index_to_file(filename)

    doc = Nokogiri::XML(File.read(filename))
    elems = doc.css('series[name="The Big Bang Theory"] > episodes > episode[all_before="true"]')
    assert_equal false, elems.empty?
  end

  def test_that_you_can_add_new_episodes_to_the_index
    assert_equal @series_index.episode_existing?("Shameless US",
        "Shameless.US.S01E09.German"), false

    @series_index.add_episode_to_index("Shameless US", "S01E09 - Episode.mkv")

    assert_equal @series_index.episode_existing?("Shameless US",
        "Shameless.US.S01E09.German"), true
  end
end

class TestIndexParsedFromDir < Test::Unit::TestCase
  def setup
    TestData.create
  end

  def teardown
    TestData.clean
  end

  def test_that_an_error_is_raised_if_the_directory_does_not_exist
    index = Sindex::SeriesIndex.new()
    assert_raise ArgumentError do
      index.build_up_index_from_directory('/this/should/not/exist')
    end
  end

  def test_that_the_index_holds_the_right_number_of_series
    index = Sindex::SeriesIndex.new()
    index.build_up_index_from_directory(TestData::SERIES_STORAGE_DIR)
    assert_equal index.empty?, false
    assert_equal 7, index.series_data.length
    assert_equal true, index.is_series_in_index?("The Big Bang Theory")
    assert_equal true, index.is_series_in_index?("Criminal Minds")
  end

  def test_that_episodes_from_directory_are_in_index
    index = Sindex::SeriesIndex.new()
    index.build_up_index_from_directory(TestData::SERIES_STORAGE_DIR)

    assert_equal true, index.episode_existing?("Criminal Minds", "S01E01")
    assert_equal false, index.episode_existing?("Criminal Minds", "S01E04")

    assert_equal true, index.episode_existing?("Chuck", "S01E01")
    assert_equal false, index.episode_existing?("Chuck", "S01E31")
  end

  def test_that_episodes_are_in_index_in_the_supplied_language
    index = Sindex::SeriesIndex.new()
    index.build_up_index_from_directory(TestData::SERIES_STORAGE_DIR, :en)

    assert_equal true, index.episode_existing?("Criminal Minds", "S01E01", :en)
    assert_equal false, index.episode_existing?("Criminal Minds", "S01E04", :en)
  end
end
