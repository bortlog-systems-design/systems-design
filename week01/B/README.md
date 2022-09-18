[Initial task](https://github.com/bortlog-systems-design/systems-design/blob/main/README.md)

## Week 1:

We will design this system's overall architecture and various aspects in the next few months, but for the first week, let's choose application-level protocol and architectural API building approach.
Also, we will make rough estimates for future capacity planning and informed architectural decisions.


### Task 1:

**Choose a communication protocol for your backend API.**

As a public API, I'll choose **REST over HTTP 1.1 with JSON payloads** since it's supported by all clients and servers.

For internal communications between services, I'll use **gRPC** since it utilizes HTTP/2 and transfers binary data, which improves performance and reduces memory costs.
>gRPC is designed for low latency and high throughput communication. gRPC is great for lightweight microservices where efficiency is critical.

But it is limited for usage from browser which is crucial for such service as Twitter.
>It's impossible to directly call a gRPC service from a browser today. gRPC heavily uses HTTP/2 features and no browser provides the level of control required over web requests to support a gRPC client. For example, browsers do not allow a caller to require that HTTP/2 be used, or provide access to underlying HTTP/2 frames.

Nonetheless, several browser-compatible solutions for gRPC exist, but I am not aware of how stable and convenient there are.

_P.S. As a combination of REST and RPC, we can use **Twirp**, but I am not familiar with this protocol so wouldn't choose this option._

#### Pros and cons of chosen communication protocol

**Pros**:
- **Wide support**. REST over HTTP 1.1 with JSON payloads is supported by all modern clients and servers.
- **Client-server autonomy**. In the REST API system, the client and server work independently, using different tech stacks. The client doesn’t need to know anything about business logic, while the server has no idea about the user interface. The separation of responsibilities means that API providers and API consumers can be modified and it won’t backfire on their communication. _It gives modifiability and better system reliability._
- **Uniform interface**. It dictates a standardized way to communicate with a given server, no matter the client app or device that runs it. _It gives ease of use and shared understanding_.
- **Layered architecture**. The RESTful system has a layered structure in which each layer works independently and interacts only with the layers directly connected to it. When calling a server, a client doesn’t know whether there are any intermediaries along the way. Due to the layered architecture, you can place a proxy or load balancer between the client and server and thus improve scalability. Adding security as a separate layer enhances system safety. Although these services are involved in producing the response, the client doesn’t have to worry about what’s behind the interface. _It gives improved system scalability and security_.
- **Caching**. REST APIs allow clients to store frequently accessed data on their side instead of requesting them again and again. As a result, the app makes fewer calls, which reduces the load on the server and its latency. In turn, the application becomes more responsive and reliable. _It gives low server latency, increase in app speed and responsiveness_.
- **Stateless interactions**. REST API doesn’t store any information related to the previous sessions, treating each request independently. All data on the current client’s state is contained in the request body. Being stateless, REST APIs don’t have to deal with the server-side state synchronization logic. Another advantage of session independence is that any server can process requests. This improves the performance of the application and reduces the risk of going down. _It gives enhanced performance and app reliability_

**Cons:**
- **Exclusively client-initiated requests.** In HTTP, only the client can initiate a request. Even if the server knows the client needs a resource, it has no mechanism to inform the client and must instead wait to receive a request for the resource from the client.
- **Redundant headers.** In HTTP, several headers are repeatedly sent across requests on the same channel. However, headers such as the `User-Agent`, `Host`, and `Accept` are generally static and do not need to be resent.
- **Uncompressed request and response headers.** Request headers today vary in size from ~200 bytes to over 2KB. As applications use more cookies and user agents expand features, typical header sizes of 700-800 bytes is common.
- **Optional data compression.** HTTP uses optional compression encodings for data. Content should always be sent in a compressed format.
- **Utilization of HTTP requests**. REST typically relies on a few verbs (GET, POST, PUT, DELETE, and PATCH) which sometimes doesn't fit your use case. For example, moving expired documents to the archive folder might not cleanly fit within these verbs.
- **Multiple requests to fetch complicated resources**. Fetching complicated resources with nested hierarchies requires multiple round trips between the client and server to render single views, e.g. fetching content of a blog entry and the comments on that entry. For mobile applications operating in variable network conditions, these multiple roundtrips are highly undesirable.

#### Example of a tweet creation API call and response using chosen protocol

Example of REST API **request**:
```HTTP
POST /tweets HTTP/1.1
Host: api.twitter.com
Authorization: Bearer mt0dgHmLJMVQhvjpNXDyA83vA_PxH23Y
Content-Type: application/json
Content-Length: 512

{
  "text": "Hello, World!"
}
```

Example of REST API **response**:
```HTTP
HTTP/1.1 201 Created
Location: http://api.twitter.com/tweets/f8c3de3d-1fea-4d7c-a8b0-29f63c4c3454
Cache-Control: no-cache
Date: Wed Jul 4 15:31:53 2022
Server: Apache/2.2.14 (Win32)
Connection: Keep-Alive
Content-Type: application/json;charset=UTF-8
Content-Length: 512

{
  "tweetId": "f8c3de3d-1fea-4d7c-a8b0-29f63c4c3454",
  "userId": "c81d4e2e-bcf2-11e6-869b-7df92533d2db",
  "text": "Hello, World!",
  "media": [],
  "created": "2022-07-04T15:31:06.419Z"
}
```

### Task 2:

**Make rough estimates of incoming and outgoing network traffic per day and persecond during peak hours.**


As mentioned in the task, users can:
- read their feed based on likes or subscriptions
- subscribe to other users
- create tweets
- like, retweet, respond to a tweet, and quote tweets

According to the given statistics, a majority of users spent their time by reading and liking tweets from their feed.

Another big part of users (20%) creates new tweets on a regular basics.

Other interactions, in my opinion, are less frequent.

So we can make our estimation based on 3 types of events:
- get twitter feed
- like tweet
- create new tweet

#### Memory overhead of our communication protocol

Firstly, let's discuss some overheads of chosen public communication protocol -- **REST over HTTP 1.1 with JSON payloads**.

The main overhead, which might be interesting for current estimation, is **memory**.

First, JSON converts all data to text: strings (which already happen to be text), but also numbers and dates. This might cause an increase in size. For example, a floating point number such as `3.14159265359`, which should fit in four bytes (eight if we need a lot more precision) would take a whopping 13 characters, meaning 13 bytes in ASCII and even more in Unicode, meaning that the amount of data we need to send is multiple times the actual amount of raw data. JSON also sends a lot of keys, such as `“firstName”`, potentially with a lot of repetition in case we were to send many instances of `Person` in a long array. Of course compression will help a bit, but we can easily say that **JSON adds a lot of extra size** to our communications.

The second source of extra size comes from HTTP request/response structure. An HTTP request/response is made out of three components: request line or status line, headers and message body.

The message body is our JSON with necessary information. Request line (or status line) and headers are additional information required by the protocol and for some additional configuration. This additional data is described by strings so requires some memory.

Request or status lines are relatively small. The main memory overhead comes from headers.

According to [Google's SPDY research project whitepaper](https://www.chromium.org/spdy/spdy-whitepaper/), request headers today vary in size from ~200 bytes to over 2KB. As applications use more cookies and user agents expand features, typical header sizes of 700-800 bytes is common.

Compression can reduce all these additional memory costs, but I wouldn't count it in this task.

For calculations below let's assume that memory overhead of our communication protocol is **~900 bytes**.

#### Incoming and outgoing network traffic per day

**Create new tweet**

[As I calculated during the **Task 3**](#tweets), our system expects to have `6000` new tweets per day.

Each tweet creation consists of 1 request and 1 response.

The body of request body may contain the next data:

| Field      | Size |
| ----------- | ----------- |
| text (emojis are allowed --> UTF 8)  | 4 * 240 = 960 Bytes      |
| media  | 10 MB      |

Other neccessary fields can be created on the backend side.

The possible response body can contain the following information:
| Field      | Size |
| ----------- | ----------- |
| tweet_id   | 16 Bytes      |
| creator_id   | 16 Bytes      |
| creation_time (Datetime)  | 8 Bytes      |
| text (emojis are allowed --> UTF 8)  | 4 * 240 = 960 Bytes      |
| media  | 10 MB      |

Important to mention that media is an optional field, and text may not contain precisely 240 symbols (as well as media size can be less than the maximum limit of 10 MB).

So let's assume that we have any media attachment only at `20%` of new tweets with an average size of `5 MB`. And the average size of the text is `400 Bytes`.

Based on these assumption we can calculate incoming and outgoing network traffic per day for tweets creation:

```
incoming_traffic_per_day = (text [bytes] + protocol_overhead [bytes]) * number_of_new_tweets_per_day + media [MB] * (number_of_new_tweets_per_day * 0.2)

outgoing_traffic_per_day = (tweet_id [bytes] + creator_id [bytes] + creation_time[bytes] + text [bytes] + protocol_overhead [bytes]) * number_of_new_tweets_per_day + media [MB] * (number_of_new_tweets_per_day * 0.2)
```

```
incoming_traffic_per_day = (400 [bytes] + 900 [bytes]) * 6000 + 5 [MB] * 1200 = 78 [bytes] * 10^5 + 6 [MB] * 10^3 = 8 [MB] + 6 [MB] * 10^3 = 6,1 [GB]
```

```
outgoing_traffic_per_day = (16 [bytes] + 16 [bytes] + 8 [bytes] + 400 [bytes] + 900 [bytes]) * 6000 + 5 [MB] * 1200 = 804 [bytes] * 10^4 + 6 [MB] * 10^3 = 8 [MB] + 6 [MB] * 10^3 = 6,1 [GB] 
```

**Like tweet**

[As I calculated during the **Task 3**](#likes), our system expects to have `36 000` new likes per day.

Each like event consists of 1 request and 1 response.

The body of request body may contain the next data:  
| Field      | Size |
| ----------- | ----------- |
| tweet_id   | 16 Bytes      |

Other neccessary fields can be created on the backend side.

The body of response can be empty since we can handle everything only by status code.

Based on these assumption we can calculate incoming and outgoing network traffic per day for likes:
```
incoming_traffic_per_day  = (tweet_id [bytes] + protocol_overhead [bytes]) * number_of_likes_per_day

outgoing_traffic_per_day = protocol_overhead [bytes] * number_of_likes_per_day
```

```
incoming_traffic_per_day = (16 [bytes] + 900 [bytes]) * 36 000 = 33 [bytes] * 10 ^6 = 32 [MB]

outgoing_traffic_per_day = 900 [bytes] * 36 000 = 32 [MB]
```

**Get tweet feed**

_I am not sure how to calculate it properly but let's try._

Let's assume that our client doesn't have any cache and rebuilds the feed from scratch every time.

There is no sense in fetching all existing tweets from the user's feed since we know (it was mentioned in **Task 3**) that the user reads an average of `180 tweets per day`. So we can initially fetch `180 + (180 / 3)` last tweets and fetch more later on demand.

So on each request we need to fetch last `240` tweets from the feed.

Now we need to decide how many `GET feed` requests from one user per day we have on average.

I believe this number can be limited by `4` since we know that the peak of usage is lunchtime and evening + there might be 1-2 request during other time.

Each time it's just `GET` request without any body.

As a response body, we might return the list of last tweets relevant for current user.

As mentioned before, each tweet contains the next information:
| Field      | Size |
| ----------- | ----------- |
| tweet_id   | 16 Bytes      |
| creator_id   | 16 Bytes      |
| creation_time (Datetime)  | 8 Bytes      |
| text (emojis are allowed --> UTF 8)  | 4 * 240 = 960 Bytes      |
| media  | 10 MB      |

We have any media attachment only at `20%` of all tweets with an average size of `5 MB`. And the average size of the text is `400 Bytes`.

Based on this information, let's calculate incoming and outgoing network traffic per day for feeds:
```
incoming_traffic_per_day = protocol_overhead [bytes] * number_of_get_feed_per_day * count_of_users

outgoing_traffic_per_day = ((tweet_id [bytes] + creator_id [bytes] + creation_time[bytes] + text [bytes] + protocol_overhead [bytes]) * size_of_the_feed + media [MB] * (size_of_the_feed * 0.2)) * number_of_get_feed_per_day * count_of_users
```

```
incoming_traffic_per_day = 900 [bytes] * 4 * 999 = 36 [bytes] * 10^5 = 4 [MB]

outgoing_traffic_per_day = ((16 [bytes] + 16 [bytes] + 8 [bytes] + 400 [bytes] + 900 [bytes]) * 240 + 5 [MB] * 48) * 4 * 999 = (322 [bytes] * 10^3 + 240 [MB]) * 4 000 = 241 [MB] * 4 000 = 941.5 [GB] 
```

##### Total incoming and outgoing network traffic per day

```
incoming_traffic_per_day_total = incoming_traffic_per_day_feed [MB] + incoming_traffic_per_day_likes [MB] + incoming_traffic_per_day_tweet_creation [GB]

outgoing_traffic_per_day = outgoing_traffic_per_day_feed [GB] + outgoing_traffic_per_day_likes [MB] + outgoing_traffic_per_day [GB]
```

```
incoming_traffic_per_day_total = 4 [MB] + 32 [MB] + 6,1 [GB] = 6,2 [GB]

outgoing_traffic_per_day = 941.5 [GB] + 32 [MB] + 6,1 [GB] = 948 [GB]
```

**The rough estimation:**
- Incoming network traffic: **6,2 GB per day**.
- Outgoing network traffic: **948 GB per day**.

#### Incoming and outgoing network traffic persecond during peak hours

I don't know how to calculate it properly so skipped this part. :(

### Task 3:

**Make rough estimates of the bare minimum required storage capacity for users, subscriptions, tweets, and likes if our system will work for three years.**

#### Users

Rough user data:

| Field      | Size |
| ----------- | ----------- |
| user_id (UUID)      | 16 Bytes      |
| user_email   | 32 Bytes     |
| username   | 20 Bytes     |
| date_of_birth | 4 Bytes |
| date_joined (Date) | 4 Bytes |

To calculate the memory required to store all user data, we can use the next formula:
```
  (user_id [bytes] + user_email [bytes] + username [bytes] +  date_of_birth [bytes] + date_joined [bytes]) * count_of_users
```
**Total size:**
```
(16 [bytes] + 32 [bytes] + 20 [bytes] + 4 [bytes] + 4 [bytes]) * 999 =  75 924 [bytes] = 75 [KB]
```

#### Subscriptions

We have `N` users, each user can subscribe for all users except themselves, so it means that each user could have at maximum `N - 1` subscriptions.

Since `N`, at least for now, is relatively small, we can assume that in 3 years we can achieve that _in average_ each user will have `(N - 1) / 2` subscriptions.

The subscriptions can be described as a directed graph where the edge from node `A` to node `B` means that user `A` is the subscriber of user `B`.

Basically, we just need to store a pair of user IDs. This pair will represent the edge of our graph.

| Field      | Size |
| ----------- | ----------- |
| subscriber_id    | 16 Bytes      |
| target_id   | 16 Bytes      |

_In case of relational database, we will use a composite key of two IDs as a foreign key._

To calculate the memory required to store all subscriptions after 3 years of work, we can use the next formula:
```
  (subscriber_id [bytes] + target_id [bytes]) * average_number_of_subscriptions_per_user * count_of_users
```

**Total size:**
```
(16 [bytes] + 16 [bytes]) * (998 / 2) * 999 = 15 952 032 [bytes] = 15 579 [KB] = 16 [MB]
```

#### Tweets

According to statistics, only 20% of users actively create new tweets, with an average rate of 2 tweets per hour during non-sleeping hours. Also, it's mentioned that all users live in the same country with one timezone.

Let's assume that non-sleeping hours in our case are `8 AM - 11 PM`. In total, it's `15 hours per day`.

Now we can calculate the number of new tweets per day:
```
  (new_twets_per_hour_from_one_user * hours_per_day) * number_of_active_creators
```

```
(2 [new tweets per hour] * 15 [hours per day])  * (999 [users] * 0.2) = 30 [new tweets per day] * 200 [users] = 6000 [new tweets per day]
```

In 3 years we can expect:
```
 number_of_tweets_per_day * 3_years_in_days
```
```
6000 [new tweets per day] * 1095 [days] = 6 570 000 [new tweets]
```

The possible structure of one tweet can be as follows:

| Field      | Size |
| ----------- | ----------- |
| tweet_id   | 16 Bytes      |
| creator_id   | 16 Bytes      |
| creation_time (Datetime)  | 8 Bytes      |
| text (emojis are allowed --> UTF 8)  | 4 * 240 = 960 Bytes      |
| media  | 10 MB      |

So for storage of `6 570 000` new tweets we need:

```
(tweet_id [bytes] + creator_id [bytes] + creation_time [bytes] + text [bytes] + media [bytes]) * number_of_tweets_after_3_years
```


```
(16 [bytes] + 16 [bytes] + 8 [bytes] + 960 [bytes] + 10 [MB]) * 6 570 000  =
(1000 [bytes] + 10 [MB]) * 6 570 000 = 11 [MB] * 657 * 10^4 = 7 227 * 10^4 [MB] = 70 577 [GB] = 69 [TB]
```

P.S. It depends on the implementation of how we would handle retweets and quoted tweets, but in some cases, we can handle them as a new tweet. That means we might need 5-10% more memory for that. But I am not sure.


#### Likes

According to the given statistics, all users visit our app daily and mostly read other users' tweets, spending, on average, 30 minutes daily. In addition, we know that, on average, users click like for 20% of tweets that they read.

First, we need to understand how many tweets a user reads per day (on average).
The user of real Twitter, [according to this article](https://www.businessinsider.com/it-would-take-10-years-to-read-one-days-tweets-2011-2), spends about 6.6 seconds to read each tweet.

Let's assume that our user spends `10 seconds reading 1 tweet`. It means that one user reads `6 tweets per minute`.

We now that an average daily session of one user is 30 minutes. So one average user is able to read:
```
reading_rate [tweets per minute] * daily_session [minutes per day]
```

```
6 [tweets per minute] * 30 [minutes per day] = 180 [tweets per day]
```

We know that each user likes only 20% of tweets that they read, so we can expect:
```
daily_likes_rate [likes per day] * count_of_users
```

```
(180 [tweets per day] * 0.2) * 999 = 36 [likes per day] * 999 = 36 000 [likes per day] 
```
which seems bigger than the total number of new tweets per day (`6000`). But we need to take into account that one tweet receives likes from multiple users + one user can scroll down theirs feed to the previous days.

In 3 years we can expect:
```
number_of_likes_per_day * 3_years_in_days
```

```
36 000 [likes per day] * 1095 [days] = 39 420 000 [likes] 
```

We can store likes similarly to subscriptions.

So the possible structure of one like can be as follows:
| Field      | Size |
| ----------- | ----------- |
| tweet_id    | 16 Bytes      |
| user_id   | 16 Bytes      |

_In case of relational database, we will use a composite key of two IDs as a foreign key._

So for storage of `39 420 000` likes we need:

```
(tweet_id [bytes] + user_id [bytes]) * number_of_likes_after_3_years
```

```
(16 [bytes] + 16 [bytes]) * 39 420 000  = 126 144 * 10^4 [bytes] = 1.2[GB]
```
