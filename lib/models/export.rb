class Export
  COLUMNS = %i(time score author_name author_url review_url).freeze
  SEPARATOR = "\t".freeze

  class << self
    def to_tsv(page_name, data)
      output = File.open("#{page_name}.tsv", 'w')
      output.puts COLUMNS.join(SEPARATOR)
      data.each { |review| output.puts values(review) }
      output.close
    end

    private

    def values(review)
      COLUMNS.map { |key| review[key] }.join(SEPARATOR)
    end
  end
end
