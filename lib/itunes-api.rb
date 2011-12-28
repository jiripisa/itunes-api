$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'singleton'
require 'logger'
require 'osx/cocoa'
require 'itunes-api/utils'

module ITunes

  #----------------------------------
  # Logger
  #----------------------------------
  module Log
    @@log = Logger.new(STDOUT)
    def log
      @@log
    end
  end

  #----------------------------------
  # Library
  #----------------------------------
  class Library

    include Log
    include Singleton

    attr_reader :library

    def initialize
      @albums = {}
      log.info("Initializing the iTunes Library")
      OSX.require_framework 'ScriptingBridge'
      iTunes = OSX::SBApplication.applicationWithBundleIdentifier_("com.apple.iTunes")
      @library = iTunes
      music = iTunes.sources.find_all { |source|source.name == 'Library'}[0].playlists.find_all { |playlist| playlist.name == 'Music'}[0]
      music.tracks.each do |track|
        key = "#{track.album.toANSI} - #{Helper.instance.interpret_name(track)}"
       (@albums[key] ||= Album.new(track)).tracks << track
      end
    end

    def albums
      @albums.values
    end
    
  end
  
  #----------------------------------
  # Album
  #----------------------------------
  class Album

    attr_reader :name, :interpret, :year, :sort_interpret, :tracks, :compilation

    def initialize(track)
      @name = track.album.toANSI
      @interpret = Helper.instance.interpret_name(track)
      @sort_interpret = track.sortAlbumArtist != '' ? track.sortAlbumArtist.toANSI : (track.sortArtist != '' ? track.sortArtist.toANSI : @interpret)
      @year = track.year
      @tracks = []
      @compilation = track.compilation
    end

    def to_s
      #@interpret == @sort_interpret ? "#{@interpret} / #{@name}" : "#{@sort_interpret} [#{@interpret}] / #{@name}"
      "#{@sort_interpret} - #{@name}"
    end

    def <=> (other)
      return (@compilation ? 1 : -1)  unless @compilation == other.compilation
      return @name <=> other.name if @compilation
      return @sort_interpret <=> other.sort_interpret unless @sort_interpret == other.sort_interpret
      return @year <=> other.year unless @year == other.year
      return @name <=> other.name
    end
    
  end 

  #----------------------------------
  # Album
  #----------------------------------

  class Helper

    include Singleton

    def interpret_name(track)
      track.compilation ? 'V.A.' : (track.albumArtist != '' ? track.albumArtist : track.artist).toANSI
    end

  end

end