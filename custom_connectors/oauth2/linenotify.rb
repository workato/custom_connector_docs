{
  title: 'Line Notify',

  connection: {
    fields: [
      {
        name: "client_id",
        label: "Client ID",
        optional: false,
        hint: "You can find your client ID " \
          "<a href='https://developers.line.me/console/' " \
          "target='_blank'>here</a>"
      },
      {
        name: "client_secret",
        label: "Client secret",
        control_type: "password",
        optional: false,
        hint: "You can find your client secret " \
          "<a href='https://developers.line.me/console/' " \
          "target='_blank'>here</a>"
      }
    ],

    authorization: {
      type: "oauth2",

      authorization_url: lambda do |connection|
        "https://notify-bot.line.me/oauth/authorize?" \
          "client_id=#{connection['client_id']}&response_type=code&scope=notify"
      end,

      acquire: lambda do |connection, auth_code|
        response = post("https://notify-bot.line.me/oauth/token").
                     payload(code: auth_code,
                             client_id: connection["client_id"],
                             client_secret: connection["client_secret"],
                     	       redirect_uri: "https://www.workato.com/oauth/callback",
                             grant_type: "authorization_code").
                     request_format_www_form_urlencoded

        [response, nil, nil]
      end,

      refresh_on: [403],

      refresh: lambda do |connection, refresh_token|
        post("https://notify-bot.line.me/oauth/token").
          payload(grant_type: "refresh_token",
                  client_id: connection["client_id"],
                  client_secret: connection["client_secret"],
                  refresh_token: refresh_token,
                  redirect_uri: "https://www.workato.com/oauth/callback").
          request_format_www_form_urlencoded
      end,

      apply: lambda do |_connection, access_token|
        headers("Authorization": "Bearer #{access_token}")
      end
    },

    base_uri: lambda do
      "https://notify-bot.line.me"
    end
  },
  object_definitions: {
    response: {
      fields: lambda do
        [
          { name: "status", type: "Integer" },
          { name: "message" }
        ]
      end
    }
  },

  actions: {
    notify: {
      description: "Send <span class='provider'>notification</span> in " \
       "<span class='provider'>Line Notify</span>",
      title_hint: "Sends notifications to users or groups that" \
       " are related to an access token.",
      input_fields: lambda do
        [
          { name: "message", label: "Message", optional: false },
          { name: "stickerId", label: "Sticker ID", type: "number",
            hint: "You can find sticker list " \
             "<a href='https://devdocs.line.me/files/sticker_list.pdf'" \
             " target='_blank'>here</a>"
          },
          { name: "stickerPackageId", label: "Sticker package ID", type: "number",
            hint: "You can find sticker package list " \
             "<a href='https://devdocs.line.me/files/sticker_list.pdf'" \
             "target='_blank'>here</a>"
          }
        ]
      end,

      execute: lambda do |_connection, input|
        post("https://notify-api.line.me/api/notify").
          payload(input).
          request_format_multipart_form
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['response']
      end,
      sample_output: lambda do |_|
        { "status": 200, "message": "ok" }
      end
    }
  }
}
