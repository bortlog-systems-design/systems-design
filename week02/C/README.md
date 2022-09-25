### Week 2:

**Task 1**: Choose a database for your backend.

Choose database type (key-value, document, relational, etc.) and exact implementation (MySQL, Cassandra, MongoDB...),
and provide a list of pros and cons for your choice.

**Task 2**: Design the layout of your database depending on its type. Specify the layout/schema of documents, values, or
tables; specify what indexes you will use if applicable.

**Task 3**: Create a sequence diagram and API spec a home screen where users can infinitely scroll all tweets from their
subscriptions in chronological order from now into the past. Describe how your backend will fetch necessary data from DB
and what queries it will use. What will the complexity of one page fetch be, and how many DB queries will you need for
one page?

#### Task 1.

Here could be a long essay reg. relational vs document databases, ACID vs BASE, reliability/scalability, CAP theorem (
and Martin Kleppmann point of view on it) and more, but at the numbers we've estimated, pretty much every database (even
SQLite) could handle the payload, we can even fit everything to RAM on a single server (well, until reboot).

So, my criterias in this case would be:

1. team experience. Since at this point it just me, I have production experience with ClickHouse (not applicable here),
   MongoDB, MySQL/MariaDB, Postges, Redis.
2. Wide adoption
3. Open source license
4. Vendor-agnostic

For the current project I'd choose MongoDB. According to the points above:

1. team has experience with that (that's cheating :))
2. it's widespread, and it would be relatively easy to find developers with experience in it. Alternatively, there are
   lots of tutorials in the Internet and a dev without experience can start fast with it.
3. It's open-source - SSPL (GNU GPLv3 license with a slight adoption after a scandal with Amazon).
4. Can be easily installed on bare-metal together with cloud providers - MongoDB Atlas, Google Cloud, AWS DocumentDB

Pros:

1. easy horizontal scaling
2. generally faster writes compared to RDBMS
3. supports full text search and geospatial queries out of the box
4. supports timeseries out of the box

Cons:

1. BASE, not ACID. Eventual consistency has to be considered on the application level
2. no JOINs (one might argue that this is a pro).
3. Specific knowledge needed to design schema sometimes

#### Task 2.

Documents structure:

[![](https://mermaid.ink/img/pako:eNqdU01vgzAM_StRzvwCjtOuO-02VUIuMTQaSZBjVlVV__scQptS2GW-EJ6_nl_iq26DQV1rpHcLPYE7eCU2RaSorvknWWSyvlfWqA2WYj043DjQgR026AgxngOZ4nDIoIAILhm75Q-fEXlFQrrnIgVqg2f0vMFPEE8MfXyum2yw3xibNkySYz0XB2Hut-fjy4hrpCUERtMAK7YOI4Mbi_dHxLPBb0j1GDIfddADcKWGIG5dApKUzcuUokY-xOkYyY4slVeq7CXNo0LkRniaZp5sL2RJ3ai0N8CtsGgXGk2HaF4u6Gg9UBrwLR8IR8IoVwQpQ4Xu3rQuGtZ3gs9a7JJ-iPG43z-6L_5_NXmqv26uK-2Q5FUb2Zi58UHzCeXp61qOBjuYBk71UyhMHD4vvtU104SVnkYjVJY103UHQxQUjeVAH3kL52Ws9Aj-K4R7zO0XqbEqAg)](https://mermaid.live/edit#pako:eNqdU01vgzAM_StRzvwCjtOuO-02VUIuMTQaSZBjVlVV__scQptS2GW-EJ6_nl_iq26DQV1rpHcLPYE7eCU2RaSorvknWWSyvlfWqA2WYj043DjQgR026AgxngOZ4nDIoIAILhm75Q-fEXlFQrrnIgVqg2f0vMFPEE8MfXyum2yw3xibNkySYz0XB2Hut-fjy4hrpCUERtMAK7YOI4Mbi_dHxLPBb0j1GDIfddADcKWGIG5dApKUzcuUokY-xOkYyY4slVeq7CXNo0LkRniaZp5sL2RJ3ai0N8CtsGgXGk2HaF4u6Gg9UBrwLR8IR8IoVwQpQ4Xu3rQuGtZ3gs9a7JJ-iPG43z-6L_5_NXmqv26uK-2Q5FUb2Zi58UHzCeXp61qOBjuYBk71UyhMHD4vvtU104SVnkYjVJY103UHQxQUjeVAH3kL52Ws9Aj-K4R7zO0XqbEqAg)

Tweets/users - that's straightforward. I'd like to describe the central collection for the timeline, which would be `subscription_feed`.

When user makes a tweet, then we create an entry with tweet id for each subscriber.

Given there's a 1 user and 200 subscribers, we create 200 documents in `subscription_feed` with

```json
{
  "id": "Binary({{subscriber_id}}{{tweet.created_at}}{{tweet_id}})",
  "tweet_id": "{{tweet_id}}"
}
```
Please, note that the ID is binary and it's not just UUID but concatenated string then converted to binary representation.

Why in heck?

We then can query the user feed both for all tweets for the user and fetching tweets for a subscription in a specific time range
*only using id and its index*.

On the one hand this might sound crazy - we insert 1*`subscriber` documents for a single tweet. But on small scale I don't expect that to be a problem.
If this needs to be scaled, then we just add RabbitMQ/etc, and make writes in small batches. We can also prioritize writes - write feed for online users first, for offline then.

Example of querying this could be found in the task 3.

#### Task 3.

[![](https://mermaid.ink/img/pako:eNp1kc1qwzAQhF9F7NkJslP_6RBwbAo5FErdXoovirVuBLaVSnLaNOTdK9uBFEJ1EvvNzLK7Z6iVQGBg8HPAvsZC8g_Nu6on7h24trKWB95bkhNuSN5K7O09zMqRZs9bUqI-or5XFJtRUXDLd9zgzPPFep2VjLwdBLdIGkQxg6xcOFRsGHlEW--JaWWNRDXEfiFaIoWZdcVmcY14HYG5kVvCCxrVHnG2GrI7kW3xj_2vNb8VwYMOdcelcHs6j6IK7B47rIC5r8CGD62toOovTsoHq8pTXwOzekAPhmm461qBNbw1rup2AuwM38CCOF0GgR_7NKAhjRPfgxOwNFomlK5oEgRxuEppdPHgRykXQJeRH_lpROlDHIQJDRMPUEir9NN8yemgU4f3yTB1vPwCNbaVhQ)](https://mermaid.live/edit#pako:eNp1kc1qwzAQhF9F7NkJslP_6RBwbAo5FErdXoovirVuBLaVSnLaNOTdK9uBFEJ1EvvNzLK7Z6iVQGBg8HPAvsZC8g_Nu6on7h24trKWB95bkhNuSN5K7O09zMqRZs9bUqI-or5XFJtRUXDLd9zgzPPFep2VjLwdBLdIGkQxg6xcOFRsGHlEW--JaWWNRDXEfiFaIoWZdcVmcY14HYG5kVvCCxrVHnG2GrI7kW3xj_2vNb8VwYMOdcelcHs6j6IK7B47rIC5r8CGD62toOovTsoHq8pTXwOzekAPhmm461qBNbw1rup2AuwM38CCOF0GgR_7NKAhjRPfgxOwNFomlK5oEgRxuEppdPHgRykXQJeRH_lpROlDHIQJDRMPUEir9NN8yemgU4f3yTB1vPwCNbaVhQ)

##### API Spec

Let me copy schema definition from the previous week

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
⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄
type Query {
    timeline(lastReadTweetId: String): []Tweet!
}
⌃⌃⌃⌃⌃⌃⌃⌃⌃⌃⌃⌃
```

Unfortunately, GrapgQL is not very descriptive unless you try it. So, let me describe the flow in the text form and show
some snippets.

Below is simplified query resolver, simplified as much as possible for brevity
```go
package query

import (
	"context"
	"time"
)

type queryResolver struct {
}

func (r *queryResolver) Timeline(ctx context.Context, lastReadTweetID *string) ([]model.Tweet, error) {
    lastReadTimestamp := time.Now()
	
    if lastReadTweetID != nil {
        lastReadTweet, _ := r.db.TweetByID(ctx, lastReadTweetID)
        lastReadTimestamp = lastReadTweet.CreatedAt()
    }
    currentUser := ctx.Value("user").(*User)
    tweetsIDs, _ := r.db.GetTweetsFromTime(ctx, currentUser.UserID, lastReadTimestamp)
	
    return r.db.TweetsByIDs(ctx, tweetsIDs)
}
```

This resolver will result in 2 queries for the initial page when user opens the app, 3 queries for the next slice.

Let's assume that we define a slice of tweets in 30 items for simplicity.

#### Queries for initial page load

Given, now is 1st of January 2022. Timestamp would be 1609459200. We fetch initial page for user with id 1.
Snippets would be in JS as in Golang it's a bit more lines of code.

```js

function toBinaryId(susbcriberId, tweetCreatedAt){
    return BinaryID(Buffer.concat(susbcriberId, tweetCreatedAt))
}

var fromId = toBinaryId(susbcriberId, 0)
var toId = toBinaryId(susbcriberId, tweetCreatedAt)
var tweetIds = db.subscription_feed.find({'_id': {'$gte': fromId, '$lte': toId}}).sort('_id', -1).limit(30)

```

Et voilà. We have tweets ids for a page, next we just need to make an `$in` query

```js
var tweets = db.tweets.find({'_id': {'$in': tweetIds}})
```

2 queries using only primary index, as promised.

#### Queries for next page load

Please, note that in GraphQL query there's a single input parameter, which is tweet id. This should be passed from client,
when it needs to fetch the next portion of tweets.

First, we find that tweet and its creation date. Then, we can just proceed with the flow for initial page load but with specified timestamp.

2+1=3 queries.
