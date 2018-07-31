# Substitute YOUR_PRODUCT_HUNT_CLIENT_ID for your OAuth2 client id from ProductHunt
# Substitute YOUR_PRODUCT_HUNT_CLIENT_SECRET for your OAuth2 client secret from ProductHunt
{
  title: 'Product Hunt',

  connection: {
    fields: [
      {
        name: 'username',
        hint: 'Your Product Hunt Username. Remove "@" prefix.',
        optional: false
      },
    ],
    authorization: {
      type: 'oauth2',

      authorization_url: ->() {
        'https://api.producthunt.com/v1/oauth/authorize?response_type=code&scope=public+private'
      },

      token_url: ->() {
        'https://api.producthunt.com/v1/oauth/token'
      },
      
      client_id: 'YOUR_PRODUCT_HUNT_CLIENT_ID',
      
      client_secret: 'YOUR_PRODUCT_HUNT_CLIENT_SECRET',
      
      credentials: ->(connection, access_token) {
        headers('Authorization': "Bearer #{access_token}")
      }
    }
  },

  object_definitions: {
    user: {
      fields: ->() {
        [
          { name: 'id', type: :integer },
          { name: 'name' },
          { name: 'headline' },
          { name: 'created_at', type: :date_time },
          { name: 'username' },
          { name: 'twitter_username' },
          { name: 'website_url', control_type: 'url' },
          { name: 'profile_url', control_type: 'url' },
          { name: 'followers_count', type: :integer },
          { name: 'followings_count', type: :integer },
          { name: 'maker_of_count', type: :integer },
          { name: 'posts_count', type: :integer },
          { name: 'votes_count', type: :integer },
          { name: 'image_url', type: :object, properties: [{ name: 'original', control_type: 'url' }]}
        ]
      }
    },
    
    post: {
      fields: ->() {
        [
          { name: 'category_id', type: :integer },
          { name: 'day', type: :date },
          { name: 'id', type: :integer },
          { name: 'name' },
          { name: 'product_state' },
          { name: 'tagline' },
          { name: 'comments_count', type: :integer },
          { name: 'created_at', type: :date_time },
          { name: 'exclusive' },
          { name: 'featured', type: :boolean },
          { name: 'discussion_url', control_type: 'url' },
          { name: 'redirect_url', control_type: 'url' },
          { name: 'votes_count', type: :integer },
          { name: 'screenshot_url', type: :object, properties: [{ name: '300px', control_type: 'url' }]},
          { name: 'thumbnail', type: :object, properties: [{ name: 'image_url', control_type: 'url' }]}
        ]
      }
    },

    vote: {
      fields: ->() {
        [
          { name: "id", type: :integer },
          { name: "created_at", type: :date_time },
          { name: "post_id", type: :integer },
          { name: "user_id", type: :integer }
        ]
      }
    },

    comment: {
      fields: ->() {
        [
          { name: "id", type: :integer },
          { name: "created_at", type: :date_time },
          { name: "post_id", type: :integer },
          { name: "user_id", type: :integer },
          { name: "body" },
          { name: "votes", type: :integer }
        ]
      }
    }
  },

  actions: {
    select_tracking_period: {
      input_fields: ->() {
        [
          { name: 'current_time', type: :integer, optional: false },
          { name: 'post_id', type: :integer, optional: false }
        ]
      },
      execute: ->(connection, input) {
        post_created_hour = get("https://api.producthunt.com/v1/posts/#{input['post_id']}")['post']['created_at'].to_time.beginning_of_hour
        tracking_duration = ((input['current_time'].to_time.beginning_of_hour - post_created_hour)/3600).to_i
        tracking_array = [0]
        unless tracking_duration > 24
          while(tracking_duration > 0)
            tracking_array = tracking_array + [tracking_duration]
            tracking_duration = tracking_duration - 1
          end
        end
        {
          'intervals': tracking_array.map { |hour| { 'hour': hour } }
        }
      },
      output_fields: ->() {
        [
          {
            name: 'intervals', type: :array, of: :object,
            properties: [{ name: 'hour' }]
          }
        ]
      }
    },

    get_votes_count_by_hour: {
      #simplified, without storing state in Air Table
      input_fields: ->() {
        [
          { name: 'post_id', type: :integer, optional: false }
        ]
      },
      execute: ->(connection, input) {
        hourly_votes = []
        last_id = nil
        poll_more = true
        post = get("https://api.producthunt.com/v1/posts/#{input['post_id']}")['post']
        post_created_time = post['created_at'].to_time.beginning_of_hour

        while(poll_more) # pick up all votes in the past 24 hours (optional: older than last_id provided)
          new_poll = if last_id
                       get("https://api.producthunt.com/v1/posts/#{input['post_id']}/votes").
                         params(newer: last_id,
                                order: 'asc')['votes']
                     else
                       get("https://api.producthunt.com/v1/posts/#{input['post_id']}/votes").params(order: 'asc')['votes']
                     end

          hourly_votes = hourly_votes + new_poll
          if (new_poll.length == 0 || new_poll.length > 50 || (new_poll.last['created_at'].to_time - 24.hours) > post_created_time)
            poll_more = false
          end
          last_id = new_poll.last['id'] if new_poll.length > 0
        end

        { # simplify output into array of "hour"=>1, "new_vote_count"=>5
          'total': post['votes_count'],
          'votes': hourly_votes.map do |vote|
            vote['created_at'].to_time.beginning_of_hour
          end.
                   group_by { |v| v }.
                   sort { |a,b| a <=> b }.
                   map do |k,v|
            { 'hour' => (((k.to_time - post_created_time)/3600) + 1).to_i, 'new_vote_count' => v.size }
          end. # drop all columns for votes pass 24 hours and before post. In case the page consists of these votes
                   reject { |h| (h['hour'] > 24) || (h['hour'] < 0) }
        }
      },

      output_fields: ->(object_definitions) {
        [
          { name: 'total', type: :integer},
          { name: 'votes',
            type: :array,
            of: :object,
            properties: [
              { name: 'hour', type: :integer },
              { name: 'new_vote_count', type: :integer }
            ]
          }
        ]
      }
    },

    get_recent_top_posts: {
      input_fields: ->() {
        [
          { name: 'minimum_vote_count', type: :integer, optional: false }
        ]
      },
      execute: ->(connection, input) {
        {
          'posts': get("https://api.producthunt.com/v1/posts/all")['posts'].
                   select { |p| p['votes_count'] > input['minimum_vote_count'] }.
                   sort { |a,b| b['votes_count'] <=> a['votes_count'] }
        }
      },
      output_fields: ->(object_definitions) {
        [
          {
            name: 'posts',
            type: :array,
            of: :object,
            properties: object_definitions['post']
          }
        ]
      }
    },

    get_todays_top_posts_by_category: {
      input_fields: ->() {
        [
          { name: 'list_size', type: :integer, optional: false },
          { name: 'category', optional: false }
        ]
      },
      execute: ->(connection, input) {
        {
          'posts': get("https://api.producthunt.com/v1/categories/#{input['category']}/posts").
                   params(days_ago: 0)['posts'].
                   sort { |a,b| b['votes_count'] <=> a['votes_count'] }[0..(input['list_size'].to_i - 1)]
        }
      },
      output_fields: ->(object_definitions) {
        [
          {
            name: 'posts',
            type: :array,
            of: :object,
            properties: object_definitions['post']
          }
        ]
      }
    },

    get_user_details: {
      input_fields: ->() {
        [
          { name: 'username_or_id', optional: false }
        ]
      },
      execute: ->(connection, input) {
        {
          'user': get("https://api.producthunt.com/v1/users/#{input['username_or_id']}")['user']
        }
      },
      output_fields: ->(object_definitions) {
        [
          { name: 'user', type: :object, properties: object_definitions['user'] }
        ]
      }
    },

    get_post_using_url: {
      input_fields: ->() {
        [
          { name: 'url' , optional: false }
        ]
      },
      execute: ->(connection, input) {
        {
          'posts': get("https://api.producthunt.com/v1/posts/all?search[url]=#{input['url']}")['posts']
        }
      },
      output_fields: ->(object_definitions) {
        [
          {
            name: 'posts',
            type: :array,
            of: :object,
            properties: object_definitions['post']
          }
        ]
      }
    },

    get_all_posts: {
      input_fields: ->() {[]},
      execute: ->(connection, input) {
        {
          'posts': get("https://api.producthunt.com/v1/posts?days_ago=0")['posts'].
                   sort {|a,b| b['created_at'] <=> a['created_at'] }
        }
      },
      output_fields: ->(object_definitions) {
        [
          {
            name: 'posts',
            type: :array,
            of: :object,
            properties: object_definitions['post']
          }
        ]
      }
    },

    get_all_your_posts: {
      input_fields: ->() {[]},
      execute: ->(connection, input) {
        username = connection['username'].gsub('@','')
        {
          'posts': get("https://api.producthunt.com/v1/users/#{username}/posts/")['posts']
        }
      },
      output_fields: ->(object_definitions) {
        [
          {
            name: 'posts',
            type: :array,
            of: :object,
            properties: object_definitions['post']
          }
        ]
      }
    },

    get_post_detail: {
      input_fields: ->() {
        [
          { name: 'post_id', type: :integer, optional: false }
        ]
      },
      execute: ->(connection, input) {
        {
          'post': get("https://api.producthunt.com/v1/posts/#{input['post_id']}")['post']
        }
      },
      output_fields: ->(object_definitions) {
        [
          {
            name: 'post',
            type: :object,
            properties: object_definitions['post']
          }
        ]
      }
    },

    get_votes_for_a_post: {
      input_fields: ->() {
        [
          { name: 'post_id', type: :integer, optional: false }
        ]
      },
      execute: ->(connection, input) {
        {
          'votes': get("https://api.producthunt.com/v1/posts/#{input['post_id']}/votes")['votes']
        }
      },
      output_fields: ->(object_definitions) {
        [
          {
            name: 'votes',
            type: :array,
            of: :object,
            properties: object_definitions['vote']
          }
        ]
      }
    },

    get_followers: {
      input_fields: ->() {
        [
          { name: 'user_id', type: :integer, optional: false }
        ]
      },
      execute: ->(connection, input) {
        {
          'followers': get("https://api.producthunt.com/v1/users/#{input['user_id']}/followers")['followers']
        }
      },
      output_fields: ->(object_definitions) {
        [
          { name: 'followers',
            type: :array,
            of: :object,
            properties: [
              { name: 'id', type: :integer },
              { name: 'user', type: :object, properties: object_definitions['user'] }
            ]
          }
        ]
      }
    },

    # vote_for_a_post: {
    #   input_fields: ->() {
    #     [
    #       { name: 'post_id', type: :integer, optional: false }
    #     ]
    #   },
    #   execute: ->(connection, input) {
    #     post("https://api.producthunt.com/v1/posts/#{input['post_id']}/vote")['vote']
    #   },
    #   output_fields: ->(object_definitions) {
    #     object_definitions['vote']
    #   }
    # },
    # comment_on_a_post: {
    #   input_fields: ->() {
    #     [
    #       { name: 'post_id', type: :integer, optional: false},
    #       {name: 'body', control_type: :text, optional: false}
    #     ]
    #   },
    #   execute: ->(connection, input) {
    #     post("https://api.producthunt.com/v1/comments", { comment: input })['comment']
    #   },
    #   output_fields: ->(object_definitions) {
    #     object_definitions['comment']
    #   }
    # }
  },

  triggers: {
    new_post: {
      input_fields: ->() {
        []
      },
      poll: ->(connection, input, last_updated_since) {
        updated_since = last_updated_since || 53175

        posts = get("https://api.producthunt.com/v1/posts/all").
                params(per_page: 50,
                       newer: updated_since)['posts']

        next_updated_since = posts.last['id'] unless posts.blank?

        {
          events: posts,
          next_poll: next_updated_since,
          can_poll_more: posts.length >= 50
        }
      },
      dedup: ->(post) {
        post['id']
      },
      output_fields: ->(object_definitions) {
        object_definitions['post']
      }
    },

    new_vote: {
      input_fields: ->() {
        [
          {
            name: 'post_id',
            type: :integer,
            hint: 'ID of post you want to track',
            optional: false
          }
        ]
      },
      poll: ->(connection, input, last_updated_since) {
        updated_since = last_updated_since || 1

        votes = get("https://api.producthunt.com/v1/posts/#{input['post_id']}/votes").
                params(per_page: 50,
                       newer: updated_since,
                       order: "asc")['votes']

        next_updated_since = votes.last['id'] unless votes.blank?

        {
          events: votes,
          next_poll: next_updated_since,
          can_poll_more: votes.length >= 50
        }
      },
      dedup: ->(vote) {
        vote['id']
      },
      output_fields: ->(object_definitions) {
        [
          { name: 'id', type: :integer },
          { name: 'created_at', type: :date_time },
          { name: 'post_id', type: :integer },
          { name: 'user_id', type: :integer },
          { name: 'user', type: :object, properties: object_definitions['user']},
        ]
      }
    },

    new_vote_for_latest_post: {
      input_fields: ->() {
        []
      },
      poll: ->(connection, input, last_updated_since) {
        vote_updated_since = last_updated_since ||  1

        username = connection['username'].gsub('@','')

        user_id = get("https://api.producthunt.com/v1/users/#{username}")['user']['id']

        post = get("https://api.producthunt.com/v1/users/#{user_id}/posts")['posts'].last || {}

        votes = if post.blank?
                  []
                else
                  get("https://api.producthunt.com/v1/posts/#{post['id']}/votes").
                    params(per_page: 2,
                           newer: vote_updated_since,
                           order: "asc")['votes']
                end
        next_updated_since = votes.last['id'] unless votes.blank?

        {
          events: votes,
          next_poll: next_updated_since,
          can_poll_more: votes.length >= 2
        }
      },
      dedup: ->(vote) {
        vote['id']
      },
      output_fields: ->(object_definitions) {
        [
          { name: 'id', type: :integer },
          { name: 'created_at', type: :date_time },
          { name: 'post_id', type: :integer },
          { name: 'user_id', type: :integer },
          { name: 'user', type: :object, properties: object_definitions['user']},
        ]
      }
    },

    new_follower: {
      input_fields: ->() {
        []
      },
      poll: ->(connection, input, last_updated_since) {
        updated_since = last_updated_since || 1

        username = connection['username'].gsub('@','')

        user_id = get("https://api.producthunt.com/v1/users/#{username}")['user']['id']

        followers = get("https://api.producthunt.com/v1/users/#{user_id}/followers").
                    params(per_page: 50,
                           newer: updated_since)['followers']

        next_updated_since = followers.last['id'] unless followers.blank?

        {
          events: followers,
          next_poll: next_updated_since,
          can_poll_more: followers.length >= 50
        }
      },
      dedup: ->(follower) {
        follower['id']
      },
      output_fields: ->(object_definitions) {
        [
          { name: "id", type: :number },
          { name: 'user', type: :object, properties: object_definitions['user'] }
        ]
      }
    },

    new_comment_in_post: {
      input_fields: ->() {
        [
          {
            name: 'post_id',
            type: :integer,
            hint: 'When someone comments with this ID, pick it up',
            optional: false
          }
        ]
      },
      poll: ->(connection, input, last_updated_since) {
        updated_since = last_updated_since || 1

        comments = get("https://api.producthunt.com/v1/comments?search[#{input['post_id']}]").
                   params(per_page: 50,
                          newer: updated_since,
                          order: "asc")['comments']

        next_updated_since = comments.last['id'] unless comments.blank?

        {
          events: comments,
          next_poll: next_updated_since,
          can_poll_more: comments.length >= 50
        }
      },
      dedup: ->(comment) {
        comment['id']
      },
      output_fields: ->(object_definitions) {
        object_definitions['comment']
      }
    }
  }
}
