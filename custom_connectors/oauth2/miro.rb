{
    title: 'Miro',

    connection: {
        authorization: {
            type: 'oauth2',

            authorization_url: ->() {
              'https://miro.com/oauth/authorize?response_type=code'
            },

            token_url: ->() {
              'https://api.miro.com/v1/oauth/token'
            },

            client_id: 'MIRO_CLIENT_ID',
            client_secret: 'MIRO_CLIENT_SECRET',

            credentials: ->(_connection, access_token) {
              headers("Authorization" => "Bearer #{access_token}")
            }
        }
    },

    object_definitions: {
        board: {
            fields: ->() {[{name: 'id'}, {name: 'name'}, {name: 'description'}]}
        },
        card: {
            fields: ->() {[{name: 'id'}, {name: 'title'}]}
        }
    },

    actions: {

        create_board: {

            description: '',

            input_fields: ->() {
              [
                  {
                      name: 'name',
                      label: 'Title'
                  },
                  {
                      name: 'description'
                  },
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
            },
            execute: ->(_connection, input) {
              post("https://api.miro.com/v1/boards")
                  .payload(
                      name: input['name'],
                      description: input['description'],
                      sharingPolicy: {
                          access: input['access_by_link'],
                          accountAccess: input['access_within_account']
                      }
                  )
            },
            output_fields: ->(object_definitions) {
              object_definitions['board']
            }
        },

        copy_board: {

            description: 'Creates a copy of an existing board',

            input_fields: ->() {
              [
                  {
                      name: 'source',
                      label: 'Original Board',
                      control_type: 'select',
                      pick_list: 'boards',
                      optional: false
                  },
                  {
                      name: 'name',
                      label: 'Title'
                  },
                  {
                      name: 'description'
                  },
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
            },
            execute: ->(_connection, input) {
              post("https://api.miro.com/v1/boards/#{input['source']}/copy")
                  .payload(
                      name: input['name'],
                      description: input['description'],
                      sharingPolicy: {
                          access: input['access_by_link'],
                          accountAccess: input['access_within_account']
                      }
                  )
            },
            output_fields: ->(object_definitions) {
              object_definitions['board']
            }
        },

        create_card_widget: {
            input_fields: ->() {
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
                      pick_list_params: {board: 'board'},
                      hint: 'Switch frame to grid mode to avoid cards overlap'
                  },
                  {
                      name: 'title'
                  },
                  {
                      name: 'link',
                      label: 'Title link',
                      control_type: 'url'
                  },
                  {
                      name: 'description'
                  },
                  {
                      name: 'border_color',
                      hint: 'In hex format (default is #2399f3)'
                  },
                  {
                      name: 'due_date',
                      type: 'date',
                      control_type: 'date'
                  }
              ]
            },

            execute: ->(_connection, input) {
              payload = {
                  type: 'card',
                  parentFrameId: input['frame'],
              }

              title = input['title']
              link = input['link']

              if title.present?
                payload[:title] = title
                if link.present?
                  payload[:title] = "<p><a href=\"#{link}\" target=\"_blank\">#{title}</a></p>"
                end
              end

              descr = input['description']
              if descr.present?
                payload[:description] = descr
              end

              color = input['border_color']
              if color.present?
                payload[:style] = {backgroundColor: color}
              end

              due_date = input['due_date']
              if due_date.present?
                payload[:dueDate] = {dueDate: [due_date.strftime('%Q').to_i]}
              end

              post("https://api.miro.com/v1/boards/#{input['board']}/widgets").payload(payload)
            },

            output_fields: ->(object_definitions) {
              object_definitions['card']
            }
        }
    },


    triggers: {},

    pick_lists: {

        board_access_by_link: -> () {
          [
              ["Private — only you have access to the board", "private"],
              ["View — can view, no sign-in required", "view"],
              ["Comment — can comment, no sign-in required", "comment"]
          ]
        },

        board_access_within_account: -> () {
          [
              ["Private — nobody in the team can find and access the board", "private"],
              ["View — any team member can find and view the board", "view"],
              ["Comment — any team member can find and comment the board", "comment"],
              ["Edit — any team member can find and edit the board", "edit"]
          ]
        },

        boards: -> () {
          host = 'https://api.miro.com/v1'
          account_id = get("#{host}/oauth-token")['account']['id']
          boards_resp = get("#{host}/accounts/#{account_id}/boards?fields=id,name&limit=500")
          next_link = boards_resp['nextLink']
          boards = boards_resp['data']

          while next_link != nil
            resp = get(next_link)
            next_link = resp['nextLink']
            resp['data'].each {|board| boards << board}
          end

          boards.pluck('name', 'id')
        },

        frames: -> (_connection, board:) {
          get("https://api.miro.com/v1/boards/#{board}/widgets?widgetType=frame&fields=id,title")['data']
              .pluck('title', 'id')
        }

    }
}