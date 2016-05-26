# TumblrDownload
Download a blog's liked posts to selected folder. (Sorry, Mac only)

## Usage:
1. First you need to [register an application on Tumblr](http://www.tumblr.com/oauth/apps), then you'll get a pair of "OAuth consumer key" and "Secret key". They are required later.
2. Fill in the OAuth consumer key in the application's "API key" text field.
3. Select your path to save all the files.
4. Fill in the Tumblr blog name.
5. Download!
6. You'll see a text file of downloaded posts in that folder. Use it later to unlike the posts within. But you first need to authorize the application to your blog and get two other keys: "OAuthToken" and "OAuthTokenSecret".

## Notes:

* It's very likely that the downloaded posts won't match the number of posts you liked. It seems like Tumblr's issue. (Tried to unlike all and still see likes but there is nothing within)
* The API key and directory are both stored locally, but the other three keys used to unlike posts are not saved.

## ToDo:
* Download a blog's posts

License
----

MIT
