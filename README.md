# FB reviews
Get list of reviews from any Facebook page.

## Installation
```
git clone https://github.com/janzikan/fb-reviews
cd fb-reviews
bundle
```

## Usage
Simply use the following command
```
bundle exec bin/reviews [FB page name]
```

This will generace TSV (Tab Separated Values) file `[FB page name].tsv`, containing the following information about each review:
* Time and date when the review was published
* Score
* Name of the author
* URL of author's profile
* URL of the review

You **do not** need to provide your Facebook login credentials in order to get the data.

### Example
We want to get reviews from TEDxPrague FB page:
https://www.facebook.com/tedxprague/

```
bin/reviews tedxprague
```

This will generate file `tedxprague.tsv`.
