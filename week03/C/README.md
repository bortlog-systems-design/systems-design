### Week 3:

**Task 1**: Let's formalize our approach to likes and retweets.

Design and provide sequence diagrams and storage schema for a like.

Design and provide sequence diagrams and storage schema for a retweet.

Describe how to fetch the count of likes and retweets when we fetch the home screen feed.

Describe how to fetch data to render already liked and/or already retweeted states for the home screen feed.

**Task 2**: Let's do a thing that real Twitter still didn't manage to make and release for all users after all these years: Edits.

You have many options, you can edit in place, but then there is a risk that the author will radically change the content of the tweet after it gets a lot of likes/retweets. A more complex way is to preserve edits' history somehow and still have access to older versions.

Create a sequence diagram and API spec for tweet edits. Describe storage for edits and how you'll fetch them for individual tweet screens and for feed.


#### Task 1

##### Likes storage

I plan to store likes in the following way:
* separate collection for likes for each tweet - we need that to check whether current user has liked the tweet or not
* likes_count in tweets collection - this will optimize likes loading for older tweets in timeline, however needs to be recalculated via recurring task, thus often would be not up to date.

optionally, counter could be stored in redis and in order to optimize point #2, but that's not needed on the load we have

Updated storage diagram below:

[![](https://mermaid.ink/img/pako:eNqdVE1vgzAM_StRzvwCjtOuO-02VUIuMTQaJMgxq6qq_30OgaYUJk3NheCv9_yMueraG9SlRnq30BL0B6fkjAEpqGt6iScwWdcqa9TGFmMd9LhxYA-221gHCOHsyWRHjwwKiOCSbLf04DMir0gIeiqSTbV3jI439hOEE0MbHuvG09lvDFXtR8mxjrODMOHt-fgy4NpSEwKjqYAV2x4DQz9k74-IZ73bkGrRJz7qoDvgQnVe3DoHRCmrpy5FjXQJ4zGQHVgqr1TZS5pahcCV8DTV1NleyJy6UWmvgVtmUc80qgbRPA3oaB1QbPAtXQgHwiAjgpihfLOAllnDciH4qMUu6bsY0xxfhv433gI1TXqXyP1D-4PL7H-p24f6a3Bd6B5J1svI6k7AB80nlB3UpVwNNjB2HOvHUBjZf15crUumEQs9DkaozPuuywa6IFY0lj19pN_B9Fco9ADuy_sl5vYLfzRWgw)](https://mermaid.live/edit#pako:eNqdVE1vgzAM_StRzvwCjtOuO-02VUIuMTQaJMgxq6qq_30OgaYUJk3NheCv9_yMueraG9SlRnq30BL0B6fkjAEpqGt6iScwWdcqa9TGFmMd9LhxYA-221gHCOHsyWRHjwwKiOCSbLf04DMir0gIeiqSTbV3jI439hOEE0MbHuvG09lvDFXtR8mxjrODMOHt-fgy4NpSEwKjqYAV2x4DQz9k74-IZ73bkGrRJz7qoDvgQnVe3DoHRCmrpy5FjXQJ4zGQHVgqr1TZS5pahcCV8DTV1NleyJy6UWmvgVtmUc80qgbRPA3oaB1QbPAtXQgHwiAjgpihfLOAllnDciH4qMUu6bsY0xxfhv433gI1TXqXyP1D-4PL7H-p24f6a3Bd6B5J1svI6k7AB80nlB3UpVwNNjB2HOvHUBjZf15crUumEQs9DkaozPuuywa6IFY0lj19pN_B9Fco9ADuy_sl5vYLfzRWgw)

Sequence diagram:

[![](https://mermaid.ink/img/pako:eNplkUFvgzAMhf9K5DOtAl2B5lCJwqXSNk3iNnHJgluiQtIFs62r-t8XoIdJ9cnye_6eZF9B2RpBQI-fAxqFhZZHJ7vKMF9n6UgrfZaGWM5kz_JWo6FHMStHNXvbsxLdF7pHR7EbHYUk-SF7nPV8sd1mpWDP-oSMvhHv5KxceKXYCbY3PTpi7WjQhuzU9UzZtkVF2pp5odgt7iipTvPo1RIyp48NMXtgo1SqBuuhRfYhSTWeMRhCx4ZzLQn_B-d3DATQoeukrv19rqOjAmqwwwqEb2s8yKGlCipz81Y5kC0vRoEgN2AAM_d-ThAH2fZ-6m8B4go_IKJks4yiMAl5xNc8ScMALiA28TLlfMXTKErWqw2PbwH8WusBfBmHcbiJOX9KonXK12kAWGuy7mX-4PTIKeF9WpgSb397QZX6)](https://mermaid.live/edit#pako:eNplkUFvgzAMhf9K5DOtAl2B5lCJwqXSNk3iNnHJgluiQtIFs62r-t8XoIdJ9cnye_6eZF9B2RpBQI-fAxqFhZZHJ7vKMF9n6UgrfZaGWM5kz_JWo6FHMStHNXvbsxLdF7pHR7EbHYUk-SF7nPV8sd1mpWDP-oSMvhHv5KxceKXYCbY3PTpi7WjQhuzU9UzZtkVF2pp5odgt7iipTvPo1RIyp48NMXtgo1SqBuuhRfYhSTWeMRhCx4ZzLQn_B-d3DATQoeukrv19rqOjAmqwwwqEb2s8yKGlCipz81Y5kC0vRoEgN2AAM_d-ThAH2fZ-6m8B4go_IKJks4yiMAl5xNc8ScMALiA28TLlfMXTKErWqw2PbwH8WusBfBmHcbiJOX9KonXK12kAWGuy7mX-4PTIKeF9WpgSb397QZX6)

##### Retweets storage

I don't plan to use a separate collection for retweets. In the tweets collection there's `type`, which is going to be one of `Comment|Retweet`.
When user makes a retweet, a new tweet is created with his user id and original tweet id. This way we have everything we need to display user retweets.

Sequence diagram:

[![](https://mermaid.ink/img/pako:eNptUsFuozAQ_ZXRnElkaAPEh0oJXHpotRK3FZcpDMVaYqdmaLYb5d_XQFeq1PXBsua9ee9pPFdsXMuoceS3iW3DpaFXT6faQjhn8mIacyYrUACNUAyGrXwHD9WMHn48QsX-nf13RnmcGSUJvdDIK15sHh4OlQbPcmEWWO4VOlSbAJZHDYVnEgYCy5eVARcjfWjq2M-JQRxMI3sg24Lz5tVYGr5qlcfNpxE1v9bSswuSgdoLuA5mqGp6bqeB4YWk6f9FGqFxk5UgDtO5nXN0zv_XZA1c6C8xTVtbjPDE_kSmDTO-ztQapecT16jDs-WOpkFqrO0tUGkSV33YBrX4iSNcPT-_BHVHwxiqYZ6or_gbdZLtt0kSZ7FK1E5leRzhB-p9us2VulN5kmS7u71KbxH-cS4IqG0ap_E-Veo-S3a52uURcmvE-ad1C5ZlWBx-Lg2L4-0vk3mvLA)](https://mermaid.live/edit#pako:eNptUsFuozAQ_ZXRnElkaAPEh0oJXHpotRK3FZcpDMVaYqdmaLYb5d_XQFeq1PXBsua9ee9pPFdsXMuoceS3iW3DpaFXT6faQjhn8mIacyYrUACNUAyGrXwHD9WMHn48QsX-nf13RnmcGSUJvdDIK15sHh4OlQbPcmEWWO4VOlSbAJZHDYVnEgYCy5eVARcjfWjq2M-JQRxMI3sg24Lz5tVYGr5qlcfNpxE1v9bSswuSgdoLuA5mqGp6bqeB4YWk6f9FGqFxk5UgDtO5nXN0zv_XZA1c6C8xTVtbjPDE_kSmDTO-ztQapecT16jDs-WOpkFqrO0tUGkSV33YBrX4iSNcPT-_BHVHwxiqYZ6or_gbdZLtt0kSZ7FK1E5leRzhB-p9us2VulN5kmS7u71KbxH-cS4IqG0ap_E-Veo-S3a52uURcmvE-ad1C5ZlWBx-Lg2L4-0vk3mvLA)

storage is the same as above, but for convinience just duplicating it:

[![](https://mermaid.ink/img/pako:eNqdVE1vgzAM_StRzvwCjtOuO-02VUIuMTQaJMgxq6qq_30OgaYUJk3NheCv9_yMueraG9SlRnq30BL0B6fkjAEpqGt6iScwWdcqa9TGFmMd9LhxYA-221gHCOHsyWRHjwwKiOCSbLf04DMir0gIeiqSTbV3jI439hOEE0MbHuvG09lvDFXtR8mxjrODMOHt-fgy4NpSEwKjqYAV2x4DQz9k74-IZ73bkGrRJz7qoDvgQnVe3DoHRCmrpy5FjXQJ4zGQHVgqr1TZS5pahcCV8DTV1NleyJy6UWmvgVtmUc80qgbRPA3oaB1QbPAtXQgHwiAjgpihfLOAllnDciH4qMUu6bsY0xxfhv433gI1TXqXyP1D-4PL7H-p24f6a3Bd6B5J1svI6k7AB80nlB3UpVwNNjB2HOvHUBjZf15crUumEQs9DkaozPuuywa6IFY0lj19pN_B9Fco9ADuy_sl5vYLfzRWgw)](https://mermaid.live/edit#pako:eNqdVE1vgzAM_StRzvwCjtOuO-02VUIuMTQaJMgxq6qq_30OgaYUJk3NheCv9_yMueraG9SlRnq30BL0B6fkjAEpqGt6iScwWdcqa9TGFmMd9LhxYA-221gHCOHsyWRHjwwKiOCSbLf04DMir0gIeiqSTbV3jI439hOEE0MbHuvG09lvDFXtR8mxjrODMOHt-fgy4NpSEwKjqYAV2x4DQz9k74-IZ73bkGrRJz7qoDvgQnVe3DoHRCmrpy5FjXQJ4zGQHVgqr1TZS5pahcCV8DTV1NleyJy6UWmvgVtmUc80qgbRPA3oaB1QbPAtXQgHwiAjgpihfLOAllnDciH4qMUu6bsY0xxfhv433gI1TXqXyP1D-4PL7H-p24f6a3Bd6B5J1svI6k7AB80nlB3UpVwNNjB2HOvHUBjZf15crUumEQs9DkaozPuuywa6IFY0lj19pN_B9Fco9ADuy_sl5vYLfzRWgw)

##### Fetching likes/retweets count

Since we store counters in the same document, we can immediately fetch the numbers, no additional queries needed.

##### Fetching already liked and/or already retweeted states for the home screen feed.

Since we store likes in a separate collection, we just need to make a query with tweet_id + user_id. If entry exists - user has liked the tweet.
Thus once we have tweet ids for the slice, we make a query into `likes` collection in order to check whether entries exist or not.

As for retweets, we need to create a query with `origin_tweet_id + user_id`. If the entry is found - user has retweeted the given tweet.

#### Task 2

In my opinion, the task is very simple. In my schema I've already specified a `version` field for optimistic locking. This can be reused for versioning.

In this case, when user edits a tweet, we generate idempotence key on client and send that to backend. On backend we generate version and insert a new tweet record with edited content.
This way we're able to preserve tweet history. With a slight modification of schema, we'll be able to specify the exact version for the retweet.

Unfortunately, this time I've not been able to organize enough time for task documentation, thus no diagrams this time. I sincerely apologize for that.
