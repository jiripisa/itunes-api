$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'singleton'
require 'logger'
require 'osx/cocoa'
require 'itunes-api/utils'
require 'erb'

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
      log.info("Library loaded")
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
      return track.sortAlbumArtist.toANSI if track.sortAlbumArtist != ''
      return track.albumArtist.toANSI if track.albumArtist != ''
      return track.sortArtist.toANSI if track.sortArtist != ''
      return track.artist.toANSI
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
    
    def missing_artwork?
      tracks.find{|track| track.artworks.size == 0}
    end
    
    def artwork_file_name
      return key.gsub(':', '-').gsub('/','-')
    end

    def to_s
      self.key
    end

    def <=> (other)
      return self.key <=> other.key
    end
    
  end 
  
end

#----------------------------------
# DirWithArtworkFiles
#----------------------------------

class DirWithArtworkFiles
  def initialize dir
    current_dir = Dir.pwd
    Dir.chdir dir
    @root_dir = dir
    @artwork_files = Dir.glob('*.jpg') + Dir.glob('*.png')
    Dir.chdir current_dir
  end
  
  def albums_with_artwork_file(albums = ITunes::Library.instance.albums)
    albums.find_all{|album| album_has_artwork_file(album)}
  end
  
  def albums_without_artwork_file(albums = ITunes::Library.instance.albums)
    albums.find_all{|album| not album_has_artwork_file(album)}
  end
  
  def artwork_files_without_album(albums = ITunes::Library.instance.albums)
    @artwork_files.find_all{|artwork_file| not artwork_file_has_album(artwork_file, albums)}
  end
  
  def generate_script(albums, file)
    erb = ERB.new(File.new("#{File.dirname(__FILE__)}/itunes-api/add_artwork_applescripts.erb").read)
    File.open(file, "w+") {|out| out.puts erb.result(binding)}  
  end
  
  private
  def artwork_for_album(album)
    "#{@root_dir}/#{@artwork_files.find{|artwork| album.artwork_file_name.upcase == file_name(artwork).upcase}}"
  end
  
  def album_has_artwork_file(album)
    @artwork_files.find{|artwork| album.artwork_file_name.upcase == file_name(artwork).upcase}
  end
  
  def artwork_file_has_album(artwork_file, albums)
    albums.find{|album| album.artwork_file_name.upcase == file_name(artwork_file).upcase}
  end  
  
  def file_name(artwork)
    return artwork.split('.jpg')[0].split('.png')[0]
  end
  
end
