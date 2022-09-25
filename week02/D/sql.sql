create table users
(
    id           uuid not null PRIMARY KEY,
    handle       text,
    display_name text,
    verified     bool,
    avatar       text
);

create table tweets
(
    id             uuid not null PRIMARY KEY,
    created_at     timestamp, -- timestamp without TZ
--     counters block
    likes          integer,
    quotes         integer,
    retweets       integer,
    comment_tweets integer,
-- end counters block
    payload        text,
    author         uuid not null REFERENCES users (id),
-- here should be thread_id with reference to thread, yet it will be simplified to parent_id
    parent_id      uuid       -- reference to root tweet. can be null
);


-- users_details not need own ID
create table users_details
(
    id          uuid not null PRIMARY KEY REFERENCES users (id) ON DELETE cascade,
    description text,
    followers   int,
    following   int,
    joined_at   timestamp,
    location    text, -- store some geo spatial data here if we would need to
    website     text
);

-- many-to-many relation
create table users_tweets
(
    user_id   uuid not null references users (id),
    tweet_id  uuid not null references tweets (id),
    reactions bytea, -- masked: liked, retweeted, quoted, etc to show on FE
    PRIMARY KEY (user_id, tweet_id)
);

create table users_follows
(
    user_id uuid not null references users (id),
    follows uuid not null references users (id),
    PRIMARY KEY (user_id, follows)
);


CREATE INDEX ON tweets (author, created_at DESC);
CREATE INDEX ON tweets (author);

-- this one useful to "discover" page
CREATE INDEX ON tweets (created_at DESC);


-- queries examples:

-- fetch "authors user is following" to cache them in app
select u.*
from users_follows uf
         join users u on u.id = uf.follows
where user_id = ?;


-- fetch tweets feed
select t.* -- now we have only the fields which we need to display on "list of tweets" component
from tweets t
where t.author in ('authors uuids')
order by t.created_at DESC
    limit 20
-- optional "load more paginator"
-- [ offset "page" number * 20]
;


select * from users_tweets
where user_id = '89809c45-5cb5-4938-9631-3deb9c6a0e9a' and tweet_id in ('89809c45-5cb5-4938-9631-3deb9c6a0e9a');
