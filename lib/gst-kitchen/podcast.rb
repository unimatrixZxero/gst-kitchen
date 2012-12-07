class Podcast
  attr_accessor :title, :subtitle, :summary, :handle, :website, :cover, :formats, :media_url, :episodes, :episodes_path

  attr_accessor :explicit

  def self.from_yaml(yaml_file="podcast.yml")
    hash = YAML.load_file(yaml_file)

    podcast = self.new
    podcast.title = hash["title"]
    podcast.subtitle = hash["subtitle"]
    podcast.summary = hash["summary"]
    podcast.handle = hash["handle"]
    podcast.website = hash["website"]
    podcast.cover = hash["cover"]
    podcast.media_url = hash["media_url"]
    podcast.explicit = hash["explicit"] || false
    podcast.formats = hash["formats"].map { |format| Media.format(format) }
    podcast.episodes_path = hash["episodes_path"] || "episodes/"

    podcast.load_episodes

    podcast
  end

  def load_episodes
    self.episodes = Dir[File.join(self.episodes_path, "#{handle.downcase}*.yml")].map do |yml|
      Episode.from_yaml(yml)
    end
  end

  def create_episode_from_auphonic(production)
    Episode.from_auphonic production
  end

  def feed_url(format)
    url = URI(self.website)
    url.path = "/#{rss_file(format)}"
    url.to_s
  end

  def episode_media_url(episode, format)
    url = URI(self.media_url)
    url.path += "/#{episode.handle.downcase}.#{format.file_ext}"
    url.to_s
  end

  def cover_url
    url = URI(self.website)
    url.path = self.cover
    url.to_s
  end

  def deep_link_url(episode)
    url = URI(self.website)
    url.fragment = "#{episode.number}:"
    url.to_s
  end

  def podcast
    self
  end

  def current_format
    @current_format
  end

  def render_feed(format)
    @current_format = format
    template = ERB.new File.read("templates/episodes.rss.erb")
    File.open(rss_file(format), "w") do |rss|
      rss.write template.result(binding)
    end
  end

  def export_episode(episode)
    destination = File.join(episodes_path, "#{episode.handle.downcase}.yml")
    File.open(destination, "w") { |file| file.write episode.to_yaml}
  end

  def render_all_feeds
    self.formats.each do |format|
      render_feed(format)
    end
  end

  def other_formats(format)
    self.formats - [format]
  end

  private
  def rss_file(format)
    "episodes.#{format.file_ext}.rss"
  end
end
