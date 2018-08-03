# Adds operations missing from the standard adapter,
# especially for Facebook Page APIs.
{
  title: "Facebook (custom)",

  connection: {
    fields: [{
      name: "access_token",
      label: "Page access token",
      control_type: "password",
      optional: false,
      hint: "Get appropriate page access token from <a target='_blank' " \
        "href='https://developers.facebook.com/tools/explorer'> " \
        "Graph API Explorer </a>. Make sure you have selected required " \
        "scopes while obtaining the access token."
    }],

    authorization: {
      type: "api_key",

      apply: lambda do |connection|
        params(access_token: connection["access_token"])
      end
    },

    base_uri: ->(_connection) { "https://graph.facebook.com" }
  },

  test: lambda do |_connection|
    get("/me").
      after_error_response(400) do |_code, body, _header, message|
        if body.include? "Session has expired"
          error("The session has expired. Please get a fresh access token.")
        else
          error("#{message}: #{body}")
        end
      end
  end,

  object_definitions: {
    page: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: "access_token", label: "Page access token" },
          { name: "category" },
          { name: "description" },
          { name: "id" },
          { name: "name" }
        ]
      end
    },

    post: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: "created_time", type: "timestamp" },
          {
            name: "from",
            type: "object",
            properties: [{ name: "id" }, { name: "name" }]
          },
          { name: "id" },
          { name: "message" },
          { name: "type" },
          { name: "updated_time", type: "timestamp" }
        ]
      end
    },

    comment: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: "created_time", type: "timestamp" },
          {
            name: "from",
            type: "object",
            properties: [
              { name: "id" },
              { name: "email", control_type: "email" },
              { name: "name" }
            ]
          },
          { name: "id" },
          { name: "message" },
          { name: "post_id", label: "Post ID" },
          {
            name: "user_likes",
            type: "boolean",
            control_type: "checkbox"
          }
        ]
      end
    },

    conversation: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: "can_reply", type: "boolean", control_type: "checkbox" },
          { name: "id" },
          { name: "link" },
          { name: "message_count", type: "integer" },
          { name: "snippet", label: "Latest message" },
          { name: "unread_count", type: "integer" },
          { name: "updated_time", type: "timestamp" }
        ]
      end
    },

    message: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: "created_time", type: "timestamp" },
          {
            name: "from",
            type: "object",
            properties: [
              { name: "id" },
              { name: "email", control_type: "email" },
              { name: "name" }
            ]
          },
          { name: "id" },
          { name: "message" },
          {
            name: "to",
            type: "object",
            properties: [{
              name: "data",
              type: "array",
              of: "object",
              properties: [
                { name: "id" },
                { name: "email", control_type: "email" },
                { name: "name" }
              ]
            }]
          },
          { name: "conversation_id", label: "Conversation ID" },
          {
            name: "message_count",
            hint: "The number of messages to fetch, default value is 100.",
            type: "integer",
            sticky: true
          }
        ]
      end
    }
  },

  actions: {
    get_page_details: {
      description: "Get <span class='provider'>page details</span> in " \
        "<span class='provider'>Facebook (custom)</span>",
      subtitle: "Get page details",

      execute: lambda do |_connection, _input|
        get("/me", fields: "access_token,category,description,id,name").
          after_error_response(400) do |_code, body, _header, message|
            if body.include? "Session has expired"
              error("The session has expired. Please get a fresh access token.")
            else
              error("#{message}: #{body}")
            end
          end || {}
      end,

      output_fields: ->(object_definitions) { object_definitions["page"] },

      sample_output: lambda do |_connection, _input|
        get("/me", fields: "access_token,category,description,id,name").
          after_error_response(400) do |_code, body, _header, message|
            if body.include? "Session has expired"
              error("The session has expired. Please get a fresh access token.")
            else
              error("#{message}: #{body}")
            end
          end.
          dig("data", 0) || {}
      end
    },

    get_latest_posts: {
      title: "Get latest posts for the page",
      description: "Get latest <span class='provider'>post</span> in " \
        "<span class='provider'>Facebook (custom)</span>",
      help: "This action pulls 10 latest posts for the page.",

      execute: lambda do |_connection, _input|
        {
          posts: get("/me", fields: "feed.limit(10)").
            after_error_response(400) do |_code, body, _header, message|
              if body.include? "Session has expired"
                error("The session has expired. " \
                  "Please get a fresh access token.")
              else
                error("#{message}: #{body}")
              end
            end.
            dig("feed", "data") || []
        }
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "posts",
          type: "array",
          of: "object",
          properties: object_definitions["post"]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          posts: [get("/me/feed").dig("data", 0)] || []
        }
      end
    },

    get_comments: {
      title: "Get comments for the post",
      help: "Fetches comments from a specified time. " \
        "Returns a maximum of 25 comments.",
      description: "Get <span class='provider'>comments</span> in " \
        "<span class='provider'>Facebook (custom)</span>",

      execute: lambda do |_connection, input|
        since = (since = input["since"].presence) ? (since.to_time.to_i - 1) : 1
        {
          comments: get("/#{input['post_id']}/comments",
                        fields: "created_time,from,id,message,user_likes",
                        since: since).
            after_error_response(400) do |_code, body, _header, message|
              if body.include? "Session has expired"
                error("The session has expired. " \
                  "Please get a fresh access token.")
              else
                error("#{message}: #{body}")
              end
            end["data"] || []
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["comment"].only("post_id").required("post_id") + [{
          name: "since",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get comments created since given date/time. " \
            "Leave empty to get comments starting from the oldest."
        }]
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "comments",
          type: "array",
          of: "object",
          properties: object_definitions["comment"].ignored("post_id")
        }]
      end,

      sample_output: lambda do |_connection, input|
        {
          comments: [get("/#{input['post_id']}/comments") .dig("data", 0)] || []
        }
      end
    },

    get_latest_messages: {
      title: "Get latest messages for the conversation",
      description: "Get latest <span class='provider'>messages</span> in " \
        "<span class='provider'>Facebook (custom)</span>",
      help: "This action pulls the latest messages for the conversation. " \
        "The number of messages to fetch depends on 'Message count' value.",

      execute: lambda do |_connection, input|
        message_count = input["message_count"] || 100

        {
          messages:  get("/#{input['conversation_id']}/messages",
                         fields: "created_time,from,id,message,to",
                         limit: message_count)["data"] || []
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["message"].
          only("conversation_id", "message_count").
          required("conversation_id")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "messages",
          type: "array",
          of: "object",
          properties: object_definitions["message"].
            ignored("conversation_id", "message_count")
        }]
      end,

      sample_output: lambda do |_connection, input|
        {
          messages: [get("/#{input['conversation']}/messages",
                         fields: "created_time,from,id,message,to").
            dig("data", 0)] || []
        }
      end
    },

    reply_to_comment: {
      description: "Reply to a <span class='provider'>comment</span> in " \
        "<span class='provider'>Facebook (custom)</span>",

      execute: lambda do |_connection, input|
        post("/#{input['comment_id']}/comments", message: input["message"]).
          after_error_response(400) do |_code, body, _header, message|
            if body.include? "Session has expired"
              error("The session has expired. Please get a fresh access token.")
            else
              error("#{message}: #{body}")
            end
          end || {}
      end,

      input_fields: lambda do |_object_definitions|
        [
          { name: "comment_id", optional: false },
          {
            name: "message",
            hint: "Message text to be posted as comment",
            optional: false
          }
        ]
      end,

      output_fields: ->(_object_definitions) { [{ name: "id" }] },

      sample_output: lambda do |_connection, _input|
        { id: "395089840900326_397482493994394" }
      end
    },

    like_comment: {
      description: "Like a <span class='provider'>comment</span> in " \
        "<span class='provider'>Facebook (custom)</span>",

      execute: lambda do |_connection, input|
        post("/#{input['comment_id']}/likes") || {}
      end,

      input_fields: lambda do |_object_definitions|
        [{ name: "comment_id", optional: false }]
      end,

      output_fields: ->(_object_definitions) { [{ name: "success" }] },

      sample_output: ->(_connection, _input) { { success: true } }
    },

    reply_to_message: {
      title: "Reply to message",
      description: "Reply to a <span class='provider'>message</span> in " \
        "<span class='provider'>Facebook (custom)</span>",
      help: "This action can be used by the Facebook page to reply " \
        "to a private message to a Facebook page inbox.",

      execute: lambda do |_connection, input|
        post("/#{input['conversation_id']}/messages",
             message: input["message"]).
          after_error_response(400) do |_code, body, _header, message|
            if body.include? "Session has expired"
              error("The session has expired. Please get a fresh access token.")
            else
              error("#{message}: #{body}")
            end
          end || {}
      end,

      input_fields: lambda do |_object_definitions|
        [
          { name: "conversation_id", optional: false },
          {
            name: "message",
            hint: "Text to be sent as reply message",
            optional: false
          }
        ]
      end,

      output_fields: lambda do |_object_definitions|
        [{ name: "id" }, { name: "uuid", label: "UUID" }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          id: "m_mid.$cAAFnPYM1Mrlp__9wuFjzrooj4wjd",
          uuid: "mid.$cAAFnPYM1Mrlp__9wuFjzrooj4wjd"
        }
      end
    }
  },

  triggers: {
    new_or_updated_conversation: {
      subtitle: "New/updated conversation",
      description: "New or updated <span class='provider'>conversation" \
        "</span> in <span class='provider'>Facebook (custom)</span>",
      type: "paging_desc",

      poll: lambda do |_connection, _input, next_page_url|
        next_page_url ||= "/me/conversations?fields=can_reply,id,link," \
          "message_count,snippet,updated_time,unread_count"

        response = get(next_page_url).
                   after_error_response(400) do |_code, body, _header, message|
                     if body.include? "Session has expired"
                       error("The session has expired. " \
                         "Please get a fresh access token.")
                     else
                       error("#{message}: #{body}")
                     end
                   end
        {
          events: response["data"] || [],
          next_page: response.dig("paging", "next") || nil
        }
      end,

      document_id: lambda do |post|
        post["id"].to_s + "@" + post["updated_time"].to_s
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["conversation"]
      end,

      sample_output: lambda do |_connection, _input|
        get("/me/conversations", fields: "can_reply,id,link,message_count," \
          "snippet,updated_time,unread_count").dig("data", 0) || []
      end
    },

    new_or_updated_post: {
      subtitle: "New/updated post",
      description: "New or updated <span class='provider'>post</span> in " \
        "<span class='provider'>Facebook (custom)</span>",
      type: "paging_desc",

      input_fields: lambda do |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get posts created since given date/time. " \
            "Leave empty to get posts created or updated one hour ago"
        }]
      end,

      poll: lambda do |_connection, input, next_page_url|
        since = (input["since"].presence || 1.hour.ago).to_time.to_i - 1
        next_page_url ||= "/me/feed?" \
          "fields=created_time,from,id,message,type,updated_time&since=#{since}"
        response = get(next_page_url).
                   after_error_response(400) do |_code, body, _header, message|
                     if body.include? "Session has expired"
                       error("The session has expired. " \
                         "Please get a fresh access token.")
                     else
                       error("#{message}: #{body}")
                     end
                   end

        {
          events: response["data"] || [],
          next_page: response.dig("paging", "next") || nil
        }
      end,

      document_id: lambda do |post|
        post["id"].to_s + "@" + post["updated_time"].to_s
      end,

      output_fields: ->(object_definitions) { object_definitions["post"] },

      sample_output: lambda do |_connection, _input|
        get("/me/feed?fields=created_time,from,id,message,type,updated_time").
          dig("data", 0) || []
      end
    }
  }
}
