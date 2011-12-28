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
        (@albums[Album.key(track)] ||= Album.new(track)).tracks << track
      end
    end

    def albums
      @albums.values.sort
    end
    
  end
  
  #----------------------------------
  # Album
  #----------------------------------
  class Album

    attr_reader :name, :interpret, :year, :sort_interpret, :tracks, :compilation, :key
    
    def self.sort_interpret(track)
      return 'V.A.' if track.compilation
      return track.sortAlbumArtist if track.sortAlbumArtist != ''
      return track.albumArtist if track.albumArtist != ''
      return track.sortArtist if track.sortArtist != ''
      return track.artist
    end
    
    def self.interpret(track)
      return 'V.A.' if track.compilation
      return track.albumArtist if track.albumArtist != ''
      return track.artist
    end

    def self.key(track)
      "#{sort_interpret(track)} - #{album_name(track)}"
    end
    
    def self.album_name(track)
      return track.album.toANSI
    end

    def initialize(track)
      @name = self.class.album_name(track)
      @interpret = self.class.interpret(track)
      @sort_interpret = self.class.sort_interpret(track)
      @year = track.year
      @tracks = []
      @compilation = track.compilation
      @key = self.class.key(track)
    end

    def to_s
      self.key
    end

    def <=> (other)
      return self.key <=> other.key
    end
    
  end 

end