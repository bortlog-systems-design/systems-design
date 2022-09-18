### Backend API communication protocol

I think, **GraphQL over HTTP** would be suitable here.

Reasons:
* provides bi-directional communication between client and server so it'll be  easy to build real time updates on server side.
* provides strongly-typed schema
* good tooling
* relatively easy to scale -> GraphQL Monolith can be split into microservices using GraphQL federation
* since the fields are explicitly specified on client side, this will reduce the number of bytes transferred between API clients and backend.

Cons:
* problematic caching on network layer since all requests are routed via POST. Caching needs to be implemented in the GraphQL server.
* N+1 is possible, dataloaders most likely will be needed (easy to implement though).
* media uploads (we allow photos/videos in user posts, right?) should be implemented separately, i.e. REST via HTTP.
* schema versioning is complex and requires communication/sync between teams
* it's non-binary protocol, so request/response payloads would be larger than using protobuf/msgpack etc.

*However, the current expectations for users number do not require binary protocols.*


#### Tweet creation API example

```graphql
enum TweetType {
	COMMENT
	RETWEET
}

enum Visibility {
	PUBLIC
	LIMITED
}

enum MediaType {
	IMAGE
	VIDEO
}

type Geo {
	Lat Float
	Lng Float
}

type Media {
	ID String!
	Body String!
	Type MediaType!
}


type Tweet {
	Content: String! 
	Visibility: Visibility!
	Hashtags: []String
	Media: Media
	Parent: Tweet
	Type: TweetType
	Geo: Geo
}


mutation createTweet($content: String, $visibility: Visibility, $hashtags: []String, $media: Media, $geo: Geo){
	createTweet(content: $content, visibility: $visibility, hashtags: $hashtags, $media: $media, geo: $geo){
		id
	}
}
```

### Make rough estimates of incoming and outgoing network traffic per day and persecond during peak hours.

Let's estimate daily rate of tweets first. Given

> Only 20% of users actively create new tweets, with an average rate of 2 tweets per hour during non-sleeping hours.

`999 (number of users)* 0.2 (20% of posters) * 2 (tweets per hour) * 16(hours a day) = 6393,6 new tweets per day.`

I'd round it to **10k tweets/day** as other 80% of users can always start to write something.

*Currently there's no media described in the spec, so let's estimate the inbound daily traffic without that first.*

Example of the tweet is desribed above.

As we don't know the country/language yet, let's be safe and assume 4 bytes for char for tweet content stored in UTF-8 (source: https://en.wikipedia.org/wiki/UTF-8#Encoding). Hence, we can estimate the size of the single tweet to be. Let's assume that 80% of tweets have 3 hashtags up to 40 chars, 20% have geo:

Hashtag size: 4 bytes * 40 chars = 240 bytes
Geo size: 32 bytes (lng) + 32 bytes (lat)

10k tweets * 960 bytes (content) + 10k * 8 bytes (visibility) + 10k tweets * 80% * 240 bytes (hashtags) + 10k*20%*64 bytes (geo):

`9600000 + 80000 + 1920000 + 128000 = ~12 Mb. `

**12 MB** is a figure just for raw bytes transferred tweets creation. If we use GraphQL over HTTP, we must add network overhead.

That'll be at least 40 bytes for HTTP via TCP4 and 60 for HTTP via TCP6. We also must add HTTP headers etc.

Based on https://www.chromium.org/spdy/spdy-whitepaper/, typical header sizes of 700-800 bytes is common.

Hence we can easily sum up

`10k tweets * 40 (http over tcp4) + 10k * 800 (headers) = ~8MB `


So, the estimated minumal inbound network traffic per day for tweets creation would be at least *20MB*.

In this case, we can say that average tweet request size would be ~2kb

Let's assume that average HTTP request for like/retweet would be 1 KB together with HTTP overhead.

Let's assume that 80% of readers read all the tweets they follow.

Then we can calculate likes/retweets.

Likes:

```
999 * 0.8 (readers) * 10k tweets * 0.2 (liked) * 1 kb = 1500 Mb
```
Retweets:

```
999 * 0.8 (readers) * 10k tweets * 0.05 (retweets) * 1 kb = 375 Mb
```

So, the estimated minumal inbound network traffic per day would be at least **1895MB**.

It will make at least ~500 K/s. As currently we have no data about visits statistics, I'd just multiply it by x3 and say that we'll have at least *1.5 Mb/sec* in peaks.


### Make rough estimates of the bare minimum required storage capacity for users, subscriptions, tweets, and likes if our system will work for three years.

#### Users

Since the collection is fixed-sized, let's not spend time here. Just a random guess - one user row will take up to 32 Kb, hence *32MB* for users collection

#### Subscriptions

We don't have any statistics about how frequently users subscribe on other users, so let's assume every reader is subscribed to every writer, which makes 800 subscriptions with 200 users in each.

This will make a collection where each subscription will receive 10k ids daily.

`800 (subscriptions) * 10k (tweets) * 365 * 3 (3 years) * 8byte (int64) = 70 Gb.`

#### Tweets

Generic structure of a tweet:
960 bytes (content)
8 bytes (visibility)
240 bytes (hashtags)
64 bytes (geo)
4kb (meta - device, ip, anything else)
8 bytes - likes count
8 bytes - parent id

average document size would be around 15 KB.

`10k tweets * 15kb * 365 * 3 = 165GB`

To sum up,

```
users: 32 MB
subscriptions: 70 GB
tweets: 165 GB
```
