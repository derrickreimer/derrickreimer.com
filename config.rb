###
# Page options, layouts, aliases and proxies
###

PODCASTS = {
  "giant-robots" => {
    name: "Giant Robots Smashing Into Other Giant Robots",
    url: "http://giantrobots.fm/"
  },
  "rubyrogues" => {
    name: "Ruby Rogues",
    url: "https://devchat.tv/ruby-rogues"
  },
  "sftrou" => {
    name: "Startups For the Rest Of Us",
    url: "http://www.startupsfortherestofus.com/"
  },
  "zen-founder" => {
    name: "Zen Founder",
    url: "http://zenfounder.com/"
  }
}

# Per-page layout changes:
#
# With no layout
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# With alternative layout
# page "/path/to/file.html", layout: :otherlayout

# Proxy pages (http://middlemanapp.com/basics/dynamic-pages/)
# proxy "/index.html", "/about.html" # Override the home page temporarily

# General configuration

###
# Helpers
###

activate :blog do |blog|
  blog.permalink = "posts/{title}.html"
  blog.layout = "article_layout"

  # Matcher for blog source files
  # blog.sources = "{year}-{month}-{day}-{title}.html"
  # blog.taglink = "tags/{tag}.html"
  blog.summary_separator = /(READMORE)/
  blog.summary_length = nil # never auto-summarize
  # blog.year_link = "{year}.html"
  # blog.month_link = "{year}/{month}.html"
  # blog.day_link = "{year}/{month}/{day}.html"
  # blog.default_extension = ".markdown"

  blog.tag_template = "tag.html"
  blog.calendar_template = "calendar.html"

  # Enable pagination
  # blog.paginate = true
  # blog.per_page = 10
  # blog.page_link = "page/{num}"
end

activate :directory_indexes

# Reload the browser automatically whenever files change
# configure :development do
#   activate :livereload
# end

# Methods defined in the helpers block are available in templates
helpers do
  def disqus_page_identifier(url)
    Digest::SHA256.hexdigest(url)
  end

  def page_header_div(options, &block)
    klasses = %w(page-header)
    klasses << 'inverse' if options[:header_inverted]
    klasses << 'with-background' if options[:header_image]
    klasses << options[:header_classes]

    style = nil

    if options[:header_image]
      style = "background-image: url(#{options[:header_image]});"
    end

    attributes = { class: klasses.join(' ') }
    attributes[:style] = style if style

    content_tag(:div, attributes, &block)
  end

  def podcast_name(id)
    PODCASTS.fetch(id, {}).fetch(:name, "Unknown")
  end

  def podcast_url(id)
    PODCASTS.fetch(id, {}).fetch(:url, "Unknown")
  end

  def podcast_link(id)
    link_to podcast_name(id), podcast_url(id)
  end
end

# Build-specific configuration
configure :build do
  activate :minify_css
  activate :minify_javascript
end

# Deployment to GH pages
activate :deploy do |deploy|
  deploy.deploy_method = :git
end
