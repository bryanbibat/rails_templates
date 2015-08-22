gsub_file 'Gemfile', /#.*\n/, "\n"
gsub_file 'Gemfile', /\n^\s*\n/, "\n"

gem 'bundler', '>= 1.8.4'
gem 'puma'
gem 'kaminari'

gem 'bootstrap-sass'
gem 'bootstrap-kaminari-views'

gem 'rails_admin'
gem 'haml'
gem 'devise'
gem 'friendly_id'
gem 'simple_form'

gem 'meta-tags', :require => 'meta_tags'
gem 'sitemap_generator'

gem 'searchkick'
gem 'typhoeus'

gem 'd3-rails'

gem 'gmaps4rails'

gem_group :development, :test do
  gem 'rspec-rails', '~> 3.2.0'
  gem 'haml-rails', '~> 0.4'
  gem 'mina'
  gem 'pry'
  gem 'pry-byebug'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
  gem 'quiet_assets'
  gem 'spring-commands-rspec'
end

gem_group :test do
  gem 'factory_girl_rails', '>= 4.0.0'
  gem 'email_spec', '>= 1.2.1'
  gem 'shoulda', '>=3.1.1'
  gem 'capybara', '~> 2.4.1'
  gem 'database_cleaner', '>= 0.8.0'
  gem 'spork', '~> 1.0rc'
  gem 'spork-rails'
  gem 'guard'
  gem 'guard-bundler'
  gem 'guard-rspec'
  gem 'guard-livereload'
  gem 'guard-puma'
  gem 'launchy'
  gem 'simplecov', :require => false
  gem 'growl'
  gem 'libnotify'
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'shoulda-matchers'
end

run 'bundle install'

run 'bundle exec guard init'

gsub_file 'Guardfile', /guard 'puma' do/, "guard 'puma', port: 3000 do"
gsub_file 'Guardfile', /bundle exec rspec/, 'bin/rspec'

inject_into_file "config/environments/development.rb", "BetterErrors::Middleware.allow_ip! ENV['TRUSTED_IP'] if ENV['TRUSTED_IP']\n", before: "Rails.application.configure do\n"
generate "rspec:install"
generate "devise:install"

application <<-CODE
config.generators do |generate|
      generate.helper false
      generate.assets false
      generate.view_specs false
    end
CODE

generate "simple_form:install --bootstrap"

generate :controller, "pages", "index"
gsub_file 'config/routes.rb', /get 'pages\/index'/, "root 'pages#index'"

inject_into_file "app/assets/javascripts/application.js", "//= require bootstrap-sprockets\n//= require d3\n//= require underscore\n//= require gmaps/google\n", after: "//= require jquery_ujs\n"
inject_into_file "spec/rails_helper.rb", <<-CODE, before: "ENV['RAILS_ENV'] ||= 'test'\n"
require 'simplecov'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter
]
SimpleCov.start 'rails' do
  add_filter 'app/secrets'
end
CODE

file 'spec/support/factory_girl.rb', <<-CODE
RSpec.configure do |config|
  # additional factory_girl configuration

  config.before(:suite) do
    begin
      DatabaseCleaner.start
      FactoryGirl.lint
    ensure
      DatabaseCleaner.clean
    end
  end
end
CODE

inject_into_file "app/helpers/application_helper.rb", <<-CODE, after: "module ApplicationHelper\n"
  def build_meta_tags(description: "Description", title: nil, image: url_to_image("opengraph.png"), page_type: :website)
    main_title = "TITLE"
    set_meta_tags(:title => title,
                  :description => description,
                  :open_graph => {
                    :title => title.nil? ? main_title : "\#{title} | \#{main_title}",
                    :description => description,
                    :type => page_type,
                    :url => url_for(:only_path => false),
                    :image => [image, { :width => 200, :height => 200 }]
                  })
  end
CODE

file "app/assets/stylesheets/pages.scss", <<-CODE
@import "bootstrap-sprockets";
@import "bootstrap";

footer, .footer {
  margin-top: 50px;
  color: #aaa;
  text-align: center;
  a {
    color: #87BEE0;
  }
}
CODE

run "rm app/views/layouts/application.html.erb"

file "app/views/layouts/application.html.haml", <<-CODE
!!!
%html{:lang => "en"}
  %head
    %meta{:charset => "utf-8"}/
    %meta{:content => "IE=Edge,chrome=1", "http-equiv" => "X-UA-Compatible"}/
    %meta{:content => "width=device-width, initial-scale=1.0", :name => "viewport"}/
    = display_meta_tags :site => "TITLE", :reverse => true
    = csrf_meta_tags
    / Le HTML5 shim, for IE6-8 support of HTML elements
    /[if lt IE 9]
      <script src="http://html5shim.googlecode.com/svn/trunk/html5.js" type="text/javascript"></script>
    = stylesheet_link_tag "application", :media => "all"
    %link{:href => "/favicon.ico", :rel => "shortcut icon"}/
  %body
    .navbar.navbar-static-top.navbar-default
      .container
        .navbar-header
          %button.navbar-toggle{ "type" => "button", "data-toggle" => "collapse", "data-target" => ".navbar-collapse" }
            %span.sr-only Toggle navigation
            %span.icon-bar
            %span.icon-bar
            %span.icon-bar
          = link_to "TITLE", root_url, :class => "navbar-brand"
        .navbar-collapse.collapse
          %ul.nav.navbar-nav
            %li{ :class => (controller_name == "pages") ? "active" : "" }= link_to "Home", root_url

    .container.main-container
      - flash.each do |name, msg|
        %div{:class => "alert alert-\#{name == "notice" ? "success" : "danger"}"}
          %a.close{"data-dismiss" => "alert"} ×
          = msg
      .row
        .col-sm-12
          = yield
    %footer
      .container
        %p
          &copy; 2015
          = link_to "Bryan Bibat", "http://bryanbibat.net"
    = yield :data_scripts
    = javascript_include_tag "application"
    = yield :scripts
    - if Rails.env == "production"
      = render "layouts/analytics"
CODE

file "app/views/layouts/_analytics.html.erb", <<-CODE
<!-- Piwik -->
<script type="text/javascript">
  var _paq = _paq || [];
  _paq.push(['trackPageView']);
  _paq.push(['enableLinkTracking']);
  (function() {
    var u="//analytics.bryanbibat.net/";
    _paq.push(['setTrackerUrl', u+'piwik.php']);
    _paq.push(['setSiteId', 15]);
    var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0];
    g.type='text/javascript'; g.async=true; g.defer=true; g.src=u+'piwik.js'; s.parentNode.insertBefore(g,s);
  })();
</script>
<noscript><p><img src="//analytics.bryanbibat.net/piwik.php?idsite=15" style="border:0;" alt="" /></p></noscript>
<!-- End Piwik Code -->
CODE

initializer "searchkick.rb", <<-CODE
require "typhoeus/adapters/faraday"
Ethon.logger = Logger.new("/dev/null")
CODE

run "git clone https://github.com/gabetax/twitter-bootstrap-kaminari-views.git"

run "mv twitter-bootstrap-kaminari-views/app/views/kaminari app/views/kaminari"

run "rm -rf twitter-bootstrap-kaminari-views"

file ".ruby-version", "2.2.2"

