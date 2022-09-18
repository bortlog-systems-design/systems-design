# 1. Communication protocol
REST over HTTP vs GRPC
* GRPC has less additional load then JSON
* GRPC use .proto for generate server/client but now for REST we can use [OpenAPI](https://www.openapis.org)
* REST is currently the default for web services, so most people have experience working with it.

From point 3 I choose REST for communication

### API
#### Models

```js
// List
{
  "data": [obj]
  "next": str
}

// TweetRespose
{
  "id": int
  "owner": {
    "id": int
    "name": str
    "username": str
  },
  "type": enum[tweet|retweet|quote|comment]
  "ref": int // optional, reference to tweet_id (for retweet, quoute, comment)
  "text": str // optional, empty for retweet
}

// TweetRequest
{
  "text": str // optional, empty for retweet
  "type": enum[tweet|retweet|quote|comment]
  "ref": int // optional, reference to tweet_id (for retweet, quoute, comment)
}

// StatsResponse
{
  "tweetId": int
  "like": bool // is user like this tweet
  "likeCount": int
  "retweetCount": int
  "commentCount": int
}
```

*Create tweet*
```http
POST /api/v1/tweets
Authorization: token
Content-Type: application/json

Body: TweetRequest

Response: TweetRespose
```

*Create like*
```http
POST /api/v1/tweets/{tweetId}/like
Authorization: token

Response: no content
```

*Get tweets*
```http
GET /api/v1/tweets?ids=&types=&next=
Authorization: token

Response: List<TweetRespose>
```

*Get user tweet*
```http
GET /api/v1/users/{userId}/tweets?ids=&types=&next=
Authorization: token

Response: List<TweetRespose>
```

*Get tweet stats*
```http
GET /api/v1/stats?tweetIds=
Authorization: token

Response: List<StatsResponse>
```

# Estimates of incoming and outgoing network

Calculate size using https://www.debugbear.com/json-size-analyzer
Sources:
```json
[  
  {  
    "data": [],  
    "next": "base64_123123123123123123123123123123123123"  
  },  
  {  
    "text": "omNmD7KbOCRhz0eWytkSXf6xJMUyh3cmAL4TD8cALfVXYFxyNZB64cIkKNsXZnAX8fF2cSlk5KpxSKXwQ7CYKZQfbKfLZahRFxVWbxQr4voA0bJ9V13N2MVc76QjLx50FdkHEWJVwVZVt22gujFfSH1PLgfbsFMXcFJG6046sVbWA1dM7py4ZQwXudgI6jv5SpCFYpDYHPKBoODXRaQcBsVZLY4ChTPD692W47Gn1uZj35trnDAlrhEWxmO3ewd8",  
    "type": 1,  
    "ref": 18446744073709551615  
  },  
  {  
    "id": 18446744073709551615,  
    "owner": {  
      "id": 18446744073709551615,  
      "name": "somename123456789123456789",  
      "username": "somename1234567890"  
    },  
    "type": 1,  
    "ref": 18446744073709551615,  
    "text": "omNmD7KbOCRhz0eWytkSXf6xJMUyh3cmAL4TD8cALfVXYFxyNZB64cIkKNsXZnAX8fF2cSlk5KpxSKXwQ7CYKZQfbKfLZahRFxVWbxQr4voA0bJ9V13N2MVc76QjLx50FdkHEWJVwVZVt22gujFfSH1PLgfbsFMXcFJG6046sVbWA1dM7py4ZQwXudgI6jv5SpCFYpDYHPKBoODXRaQcBsVZLY4ChTPD692W47Gn1uZj35trnDAlrhEWxmO3ewd8"  
  },  
  {  
    "tweetId": 18446744073709551615,  
    "like": true,  
    "likeCount": 18446744073709551615,  
    "retweetCount": 18446744073709551615,  
    "commentCount": 18446744073709551615  
  }  
]
```

Result:
* List: 24B
* TweetRequest: 304B
* TweetRespose: 425B
* StatsResponse: 146B

*Calculate creates tweets*
```
304B [TweetRequest] * 2 [tweets] * 16 [non-sleeping hours] * 200 [20% users] = 1_945_600 bytes per 24h
```

TODO: calculate trafic for:
* get tweets and stats
* create likes

# 3. Required storage capacity

TODO
