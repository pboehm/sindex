# encoding: UTF-8
require File.dirname(__FILE__) + '/test_helper.rb'

class TestInterface < Test::Unit::TestCase

  def setup
    files = [ File.dirname(__FILE__) + '/seriesindex_example.xml' ]

    @series_index = Sindex::SeriesIndex.new(files: files)
  end

  def test_instantiating
    index = Sindex::SeriesIndex.new()
    assert_instance_of Sindex::SeriesIndex, index
  end

  def test_parse_seriesindex
    assert_equal 13, @series_index.series_data["chase"].length

    assert_equal "S01E04 - Blutiger Wahnsinn.avi",
        @series_index.series_data["chase"]["1_4"]

    assert_equal false, @series_index.empty?
  end

  def test_check_for_episode_existance
    assert_equal true, @series_index.episode_existing?("Chase",
                       "Chase.S01E04.Episodename.avi")

    assert_equal false, @series_index.episode_existing?("Chase",
                        "Chase.S03E04.Episodename.avi")

    assert_equal true, @series_index.episode_existing?("Miami Medical",
                       "Miami.Medical.S01E04.Episodename.avi")

    assert_equal false, @series_index.episode_existing?("Not Exisiting",
                        "Not.Existing.S03E04.Episodename.avi")

    assert_equal false, @series_index.episode_existing?("Chase",
      "Chase.S01E14.Rache.an.Annie.Teil.3.GERMAN.DUBBED.DL.720p.HDTV.x264-TVP")

    assert_equal true, @series_index.episode_existing?("Shameless US",
      "Shameless.US.S02E11.Just.Like.The.Pilgrims.Intended.German.Dubbed.DL.VoDHD.XviD-TVS")

    assert_equal true, @series_index.episode_existing?("The Listener",
      "The.Listener.S03E01.Bankgeheimnis.DL.German.HDTV.XviD-GDR")
  end

  def test_check_seriesname_in_index
    assert_equal true, @series_index.is_series_in_index?(
      "Chase.S01E13.Rache.an.Annie.Teil.2.GERMAN.DUBBED.WS.HDTVRip.XviD-TVP")

    assert_equal true, @series_index.is_series_in_index?(
      "Unforgettable.S01E08.All.unsere.Sachen.German.DL.Dubbed.WS.WEB-DL.XviD.REPACK-GDR")

    assert_equal true, @series_index.is_series_in_index?(
      "Life.Unexpected.S02E10.Spiel.mit.dem.Feuer.German.Dubbed.DL.720p.WEB-DL.h264-GDR")

    assert_equal false, @series_index.is_series_in_index?(
      "Ugly.Betty.S03E10.Boese.Amanda.German.DL.Dubbed.WEBRiP.XViD-GDR")

    assert_equal false, @series_index.is_series_in_index?(
      "Memphis.Beat.S01E06.Sein.letzter.Kampf.GERMAN.DUBBED.720p.HDTV.x264-ZZGtv")

    assert_equal false, @series_index.is_series_in_index?(
      "Private.Practice.S05E12.Aussichtsloser.Kampf.German.Dubbed.WS.WEB-DL.XviD-GDR")
  end

  def test_check_seriesname_in_index_case_insensitive
    assert_equal true, @series_index.is_series_in_index?(
      "Two.and.a.half.Men.S09E09.Ein.Opossum.auf.Chemo.German.Dubbed.WS.WEB-DL.XviD-GDR")

  end
end
