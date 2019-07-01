{
  title: 'Miro',

  connection: {
    authorization: {
      type: 'oauth2',

      authorization_url: lambda do
        'https://miro.com/oauth/authorize?response_type=code'
      end,

      token_url: lambda do
        'https://api.miro.com/v1/oauth/token'
      end,

      client_id: 'MIRO_CLIENT_ID',
      client_secret: 'MIRO_CLIENT_SECRET',

      credentials: lambda do |_connection, access_token|
        headers('Authorization' => "Bearer #{access_token}")
      end
    }
  },

  object_definitions: {
    board: {
      fields: lambda do
        [
          { name: 'id' },
          { name: 'name' },
          { name: 'description' }
        ]
      end
    },
    card: {
      fields: lambda do
        [
          { name: 'id' },
          { name: 'title' }
        ]
      end
    }
  },

  actions: {

    create_board: {
      description: 'Creates a Board',
      input_fields: lambda do
        [
          { name: 'name', label: 'Title' },
          { name: 'description' },
          {
            name: 'access_by_link',
            control_type: 'select',
            pick_list: 'board_access_by_link',
            hint: 'Access to the board by link. Can be private, view, comment.'
          },
          {
            name: 'access_within_account',
            control_type: 'select',
            pick_list: 'board_access_within_account',
            hint: 'Team access to the board. Can be private, view, comment or edit.'
          }
        ]
      end,
      execute: lambda do |_connection, input|
        post('https://api.miro.com/v1/boards')
          .payload(
            name: input['name'],
            description: input['description'],
            sharingPolicy: {
              access: input['access_by_link'],
              accountAccess: input['access_within_account']
            }
          )
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['board']
      end
    },

    copy_board: {

      description: 'Creates a copy of an existing board',

      input_fields: lambda do
        [
          {
            name: 'source',
            label: 'Original Board',
            control_type: 'select',
            pick_list: 'boards',
            optional: false
          },
          { name: 'name', label: 'Title' },
          { name: 'description' },
          {
            name: 'access_by_link',
            control_type: 'select',
            pick_list: 'board_access_by_link',
            hint: 'Access to the board by link. Can be private, view, comment.'
          },
          {
            name: 'access_within_account',
            control_type: 'select',
            pick_list: 'board_access_within_account',
            hint: 'Team access to the board: private, view, comment or edit.'
          }
        ]
      end,
      execute: lambda do |_connection, input|
        post("https://api.miro.com/v1/boards/#{input['source']}/copy")
          .payload(
            name: input['name'],
            description: input['description'],
            sharingPolicy: {
              access: input['access_by_link'],
              accountAccess: input['access_within_account']
            }
          )
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['board']
      end
    },

    create_card_widget: {
      input_fields: lambda do
        [
          {
            name: 'board',
            control_type: 'select',
            pick_list: 'boards',
            optional: false
          },
          {
            name: 'frame',
            control_type: 'select',
            pick_list: 'frames',
            optional: false,
            pick_list_params: { board: 'board' },
            hint: 'Switch frame to grid mode to avoid cards overlap'
          },
          { name: 'title' },
          { name: 'link', label: 'Title link', control_type: 'url' },
          { name: 'description' },
          { name: 'border_color', hint: 'In hex format (default is #2399f3)' },
          { name: 'due_date', type: 'date', control_type: 'date' }
        ]
      end,

      execute: lambda do |_connection, input|
        payload = {
          type: 'card',
          parentFrameId: input['frame'],
        }

        if input['title'].present?
          payload[:title] = input['title']
          if input['link'].present?
            payload[:title] =
              "<p><a href=\"#{input['link']}\" target=\"_blank\">#{input['title']}</a></p>"
          end
        end

        if input['description'].present?
          payload[:description] = input['description']
        end

        if input['border_color'].present?
          payload[:style] = { backgroundColor: input['border_color'] }
        end

        if input['due_date'].present?
          payload[:dueDate] = {
            dueDate: [input['due_date'].strftime('%Q').to_i]
          }
        end

        post("https://api.miro.com/v1/boards/#{input['board']}/widgets").payload(payload)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['card']
      end
    }
  },

  triggers: {},

  pick_lists: {

    board_access_by_link: lambda do
      [
        ['Private — only you have access to the board', 'private'],
        ['View — can view, no sign-in required', 'view'],
        ['Comment — can comment, no sign-in required', 'comment']
      ]
    end,

    board_access_within_account: lambda do
      [
        ['Private — nobody in the team can access this board', 'private'],
        ['View — any team member can find and view the board', 'view'],
        ['Comment — any team member can find and comment the board', 'comment'],
        ['Edit — any team member can find and edit the board', 'edit']
      ]
    end,

    boards: lambda do
      host = 'https://api.miro.com/v1'
      account_id = get("#{host}/oauth-token")['account']['id']
      query = 'fields=id,name&limit=500'
      boards_resp = get("#{host}/accounts/#{account_id}/boards?#{query}")
      next_link = boards_resp['nextLink']
      boards = boards_resp['data']

      while next_link.present?
        resp = get(next_link)
        next_link = resp['nextLink']
        resp['data'].each { |board| boards << board }
      end

      boards.pluck('name', 'id')
    end,

    frames: lambda do |_connection, board:|
      query = 'widgetType=frame&fields=id,title'
      get("https://api.miro.com/v1/boards/#{board}/widgets?#{query}")['data']
        .pluck('title', 'id')
    end

  }
}
