# frozen_string_literal: true

{
  title: 'Miro',

  connection: {

    fields: [
      { name: 'client_id', optional: false },
      { name: 'client_secret', control_type: 'password', optional: false }
    ],

    base_uri: ->(_connection) { 'https://api.miro.com' },

    authorization: {
      type: 'oauth2',

      authorization_url: lambda do |connection|
        params = {
          client_id: connection['client_id'],
          response_type: 'code'
        }.to_param

        "https://miro.com/oauth/authorize?#{params}"
      end,

      acquire: lambda do |connection, auth_code, redirect_uri|
        params = {
          code: auth_code,
          client_id: connection['client_id'],
          client_secret: connection['client_secret'],
          grant_type: 'authorization_code',
          redirect_uri: redirect_uri
        }.to_param

        response = post("https://api.miro.com/v1/oauth/token?#{params}")

        { access_token: response['access_token'] }
      end,

      refresh_on: [401, 403],

      credentials: lambda do |_connection, access_token|
        headers('Authorization' => "Bearer #{access_token}")
      end
    }
  },

  object_definitions: {
    board: {
      fields: lambda do
        [
          {
            name: 'name',
            label: 'Title',
            sticky: true,
            hint: 'Board title.'
          },
          {
            name: 'description',
            label: 'Description',
            sticky: true,
            hint: 'Board description.'
          },
          {
            name: 'sharingPolicy',
            type: 'object',
            properties: [
              {
                name: 'access',
                label: 'Access by link',
                control_type: 'select',
                pick_list: 'board_access_by_link',
                sticky: true,
                hint: 'Access to the board by link.'
              },
              {
                name: 'accountAccess',
                label: 'Access within account',
                control_type: 'select',
                pick_list: 'board_access_within_account',
                sticky: true,
                hint: 'Team access to the board.'
              }
            ]
          }
        ]
      end
    },
    card: {
      fields: lambda do
        [
          {
            name: 'type'
          },
          {
            name: 'title',
            label: 'Card Title',
            sticky: true,
            hint: 'Max 6000 symbols.'
          },
          {
            name: 'description',
            label: 'Card Description',
            sticky: true,
            hint: 'This description will opened by double-click on card.'
          },
          {
            name: 'style',
            type: 'object',
            properties: [
              {
                name: 'backgroundColor',
                label: 'Card Border Color',
                sticky: true,
                hint: 'In hex format (default is #2399f3)'
              }
            ]
          },
          {
            name: 'date',
            label: 'Due date',
            type: 'object',
            properties: [
              {
                name: 'due',
                label: 'Card Due Date',
                type: 'date',
                control_type: 'date',
                sticky: true,
                hint: 'Set due date for the card.'
              }
            ]
          }
        ]
      end
    }
  },

  actions: {

    create_board: {
      description: 'Creates a Board in Miro.',

      input_fields: lambda do |object_definitions|
        object_definitions['board']
      end,

      execute: lambda do |_connection, input|
        post('/v1/boards', input)
          .after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['board']
      end,

      sample_output: lambda do
        account_id = get('/v1/oauth-token')['account']['id']
        get("/v1/accounts/#{account_id}/boards", limit: 1)
          .dig('data', 0) || {}
      end
    },

    copy_board: {
      description: 'Creates a copy of an existing board in Miro.',

      input_fields: lambda do |object_definitions|
        [
          {
            name: 'source',
            label: 'Original Board',
            control_type: 'select',
            pick_list: 'boards',
            optional: false,
            hint: 'Choose a board to copy.'
          }
        ].concat(object_definitions['board'])
      end,

      execute: lambda do |_connection, input|
        post("/v1/boards/#{input['source']}/copy", input)
          .after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['board']
      end,

      sample_output: lambda do
        account_id = get('/v1/oauth-token')['account']['id']
        get("/v1/accounts/#{account_id}/boards", limit: 1)
          .dig('data', 0) || {}
      end
    },

    create_card_widget: {
      description: 'Creates a Card Widget on board in Miro.',

      input_fields: lambda do |object_definitions|
        [
          {
            name: 'board',
            control_type: 'select',
            pick_list: 'boards',
            optional: false,
            hint: 'Choose board for card creation.'
          },
          {
            name: 'parentFrameId',
            label: 'Frame',
            control_type: 'select',
            pick_list: 'frames',
            optional: false,
            pick_list_params: { board: 'board' },
            hint: 'Switch frame to grid mode to avoid cards overlap.'
          },
          {
            name: 'link',
            label: 'Title Link',
            control_type: 'url',
            sticky: true,
            hint: 'This link will be integrated into card title.'
          }
        ].concat(object_definitions['card'].ignored('type'))
      end,

      execute: lambda do |_connection, input|
        input['type'] = 'card'
        title = input['title']
        link = input.delete('link')

        if title.present? && link.present?
          input['title'] =
            "<p><a href=\"#{link}\" target=\"_blank\">#{title}</a></p>"
        end

        date = input.delete('date')
        if date.present?
          due = date['due']
          if due.present?
            input[:dueDate] = { dueDate: [due.strftime('%Q').to_i] }
          end
        end

        board_id = input.delete('board')
        post("/v1/boards/#{board_id}/widgets", input.compact)
          .after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['card']
      end,

      sample_output: lambda do |_connection, _input|
        {
          title: 'Sample Card',
          description: 'Sample description',
          style: {
            backgroundColor: '#2399f3'
          }
        }
      end
    }
  },

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
      account_id = get('/v1/oauth-token')['account']['id']
      response =
        get("v1/accounts/#{account_id}/boards?fields=id,name&limit=500")
          .after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      next_link = response['nextLink']
      data = response['data']
      while next_link.present?
        resp = get(next_link)
        next_link = resp['nextLink']
        resp['data'].each { |board| data << board }
      end
      data.pluck('name', 'id')
    end,

    frames: lambda do |_connection, board:|
      query = 'widgetType=frame&fields=id,title'
      response =
        get("/v1/boards/#{board}/widgets?#{query}")
          .after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      response['data'].pluck('title', 'id')
    end

  }
}
