# frozen_string_literal: true

require 'config/capybara'

class Scraper
  class PageDoesNotExistError < StandardError; end

  FB_URL = 'https://www.facebook.com'
  FB_REVIEWS_URL = "#{FB_URL}/pg/%s/reviews/"

  # Selectors
  SELECTOR_REVIEWS = 'div._1dwg._1w_m'
  SELECTOR_CONTENT = 'div.userContent'
  SELECTOR_REVIEW_LINK = 'span.fsm a._5pcq'
  SELECTOR_SCORE = 'h5 span.fcg i'
  SELECTOR_AUTHOR = 'span.fwb'

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
      review_url = review_link[:href]

      data << {
        time: created_at(review),
        score: score(review),
        author_name: author_name(review),
        author_url: profile_url(review_url),
        review_url: review_url,
        text: text(review)
      }
    end
  end

  def score(review)
    score = review.find(SELECTOR_SCORE).text
    return if score.empty?

    score.to_i
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

  def profile_url(url)
    if url.include?('/permalink.php')
      param = url.match(/&(id=[0-9]+)/)[1]
      "#{FB_URL}/profile.php?#{param}"
    else
      url.match(/#{FB_URL}\/[^\/]*\//)[0]
    end
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
