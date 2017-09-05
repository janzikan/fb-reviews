require 'config/capybara'

class Scraper
  class PageDoesNotExistError < StandardError; end

  FB_URL = 'https://www.facebook.com'.freeze
  FB_REVIEWS_URL = "#{FB_URL}/pg/%s/reviews/".freeze

  # Selectors
  SELECTOR_REVIEWS = 'div._1dwg._1w_m'.freeze
  SELECTOR_CONTENT = 'div.userContent'.freeze
  SELECTOR_REVIEW_LINK = 'span.fsm a._5pcq'.freeze
  SELECTOR_SCORE = 'h5 span.fcg i'.freeze
  SELECTOR_AUTHOR = 'span.fwb'.freeze

  def initialize
    @session = Capybara::Session.new(:webkit)
    @session.driver.header('User-Agent', 'Mozilla')
  end

  def reviews(page_name)
    url = FB_REVIEWS_URL % page_name
    @session.visit(url)
    raise PageDoesNotExistError, 'Page does not exist' if @session.status_code == 404

    load_all_reviews
    scrape_reviews
  end

  private

  def scrape_reviews
    reviews = @session.all(SELECTOR_REVIEWS)

    reviews.inject([]) do |data, review|
      review_link = review.find(SELECTOR_REVIEW_LINK)
      review_path = review_link[:href]

      data << {
        time: created_at(review),
        score: score(review),
        author_name: author_name(review),
        author_url: facebook_url(profile_path(review_path)),
        review_url: facebook_url(review_path),
        text: text(review)
      }
    end
  end

  def score(review)
    review.find(SELECTOR_SCORE).text.match(/[1-5]/)[0].to_i
  end

  def author_name(review)
    review.find(SELECTOR_AUTHOR).text
  end

  def text(review)
    review.find(SELECTOR_CONTENT).text
  end

  def created_at(review_link)
    time = review_link.find('abbr')[:'data-utime'].to_i
    Time.at(time)
  end

  def profile_path(path)
    if path.start_with?('/permalink.php')
      param = path.match(/&(id=[0-9]+)/)[1]
      "/profile.php?#{param}"
    else
      path[0..path.index('/', 1)]
    end
  end

  def facebook_url(path)
    "#{FB_URL}#{path}"
  end

  def load_all_reviews
    loop do
      current_reviews_count = reviews_count
      scroll_page
      wait_for_ajax(current_reviews_count)
      print '.'

      # New content - continue loading
      next if current_reviews_count != reviews_count

      # No new content -try for the last time
      scroll_page
      wait_for_ajax(current_reviews_count)
      break if current_reviews_count == reviews_count
    end
  end

  def wait_for_ajax(current_reviews_count)
    wait_time = 0
    interval = 0.1

    loop do
      sleep interval
      wait_time += interval

      break if current_reviews_count != reviews_count
      break if wait_time >= 10
    end
  end

  def reviews_count
    @session.all(SELECTOR_REVIEWS).count
  end

  def scroll_page
    @session.execute_script('window.scrollBy(0,10000)')
  end
end
