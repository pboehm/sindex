# encoding: UTF-8
require File.dirname(__FILE__) + '/test_helper.rb'
require 'fileutils'

class TestIndex < Test::Unit::TestCase

  def setup
    index_file = File.dirname(__FILE__) + '/seriesindex_example.xml'

    @tmp_directory = '/tmp/'

    @series_index = Sindex::SeriesIndex.new(index_file: index_file)
  end

  def test_instantiating
    index = Sindex::SeriesIndex.new()

    assert_instance_of Sindex::SeriesIndex, index
    assert_instance_of Hash, index.series_data
    assert_equal index.empty?, true
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
    filename = @tmp_directory + 'dumped_index.xml'
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
end
