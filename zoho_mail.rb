# frozen_string_literal: true

{
  title: 'Zoho Mail',

  connection: {
    fields: [
      {
        name: 'domain',
        control_type: 'select',
        pick_list: [
          %w[.com zoho.com],
          %w[.eu zoho.eu],
          %w[.in zoho.in]
        ],
        optional: false
      },
      {
        name: 'client_id',
        optional: false,
        hint: 'Find your client ID & client secret'\
        "<a href='https://accounts.zoho.com/developerconsole'"\
         "target='_blank'>here</a><br/> Authorized redirect URI:"\
         '<b>https://www.workato.com/oauth/callback</b>'
      },
      {
        name: 'client_secret',
        optional: false
      }
    ],

    authorization: {
      type: 'oauth2',

      authorization_url: lambda do |connection|
        scope = [
          'VirtualOffice.search.READ',
          'VirtualOffice.folders.READ',
          'VirtualOffice.accounts.READ',
          'VirtualOffice.messages.READ',
          'VirtualOffice.messages.CREATE'
        ].join(' ')
        "https://accounts.#{connection['domain']}/oauth/v2/"\
        "auth?scope=#{scope}&client_id=#{connection['client_id']}&"\
        'response_type=code&access_type=offline&prompt=consent'
      end,

      acquire: lambda do |connection, auth_code, redirect_uri|
                 scope = ['VirtualOffice.search.READ',
                          'VirtualOffice.folders.READ',
                          'VirtualOffice.accounts.READ',
                          'VirtualOffice.messages.READ',
                          'VirtualOffice.messages.CREATE'].join(' ')

                 response = post("https://accounts.#{connection['domain']}"\
                  '/oauth/v2/token')
                            .params(client_id: connection['client_id'],
                                    client_secret: connection['client_secret'],
                                    grant_type: 'authorization_code',
                                    code: auth_code,
                                    scope: scope,
                                    redirect_uri: redirect_uri)

                 [{
                   access_token: response['access_token'],
                   refresh_token: response['refresh_token']
                 },
                  nil,
                  {
                    refresh_token: response['refresh_token']
                  }]
               end,

      refresh: lambda do |connection, redirect_uri|
                 scope = ['VirtualOffice.search.READ',
                          'VirtualOffice.folders.READ',
                          'VirtualOffice.accounts.READ',
                          'VirtualOffice.messages.READ',
                          'VirtualOffice.messages.CREATE'].join(' ')

                 post("https://accounts.#{connection['domain']}/oauth/v2/token")
                   .params(client_id: connection['client_id'],
                           client_secret: connection['client_secret'],
                           grant_type: 'refresh_token',
                           refresh_token: connection['refresh_token'],
                           scope: scope,
                           redirect_uri: redirect_uri)
               end,
      refresh_on: [404, 500],

      apply: lambda do |_connection, access_token|
               headers('Authorization' => "Zoho-oauthtoken #{access_token}")
             end
    },

    test: lambda do |connection|
            puts get("https://mail.#{connection['domain']}/api/accounts")
          end
  },
  object_definitions: {

    newMailResponse: {
      fields: lambda do
                [
                  { name: 'summary' },
                  { name: 'sentDateInGMT' },
                  { name: 'calendarType' },
                  { name: 'subject' },
                  { name: 'messageId' },
                  { name: 'toAddress' },
                  { name: 'folderId' },
                  { name: 'sender' },
                  { name: 'receivedTime' },
                  { name: 'fromAddress' },
                  { name: 'content' }
                ]
              end
    },
    sendMailResponse: {
      fields: lambda do
                [
                  { name: 'fromAddress' },
                  { name: 'subject' },
                  { name: 'toAddress' },
                  { name: 'content' },
                  { name: 'ccAddress' },
                  { name: 'bccAddress' }
                ]
              end
    }

  },

  methods: {
    getAccountId: lambda do |connection|
                    parsed = get("https://mail.#{connection['domain']}/"\
                          'api/accounts')['data']
                    account_id = 0
                    parsed.each do |accdata|
                      if accdata['type'] == 'ZOHO_ACCOUNT'
                        account_id = accdata['accountId']
                      end
                    end
                    account_id
                  end,
    getFromAddresses: lambda do |parsed|
                        from_addresses = []
                        parsed.each do |accdata|
                          if accdata['type'] == 'ZOHO_ACCOUNT'
                            from_addresses = accdata['sendMailDetails']
                          end
                        end
                        from_addresses
                      end,

    getFolders: lambda do |parsed|
                  folder_json = []
                  parsed.each do |folderdata|
                    if folderdata['folderType'] == 'Inbox'
                      folder_json << folderdata
                    end
                  end
                  folder_json
                end,
    addContent: lambda do |input|
                  response = input['response']
                  connection = input['connection']
                  account_id = input['accountId']
                  mail_content = []
                  response.each do |mailjson|
                    next if mailjson['folderId'].blank?

                    content = get("https://mail.#{connection['domain']}/api/"\
                    "accounts/#{account_id}/folders/#{mailjson['folderId']}/"\
                    "messages/#{mailjson['messageId']}/"\
                    'content')['data']['content']
                    mailjson = mailjson.merge('content' => content)
                    mail_content << mailjson
                  end
                  mail_content
                end
  },

  pick_lists: {
    fromAddress: lambda do |connection|
      call(:getFromAddresses,
           get("https://mail.#{connection['domain']}/api/accounts")['data'])
        .map do |fromaddress|
        [fromaddress['fromAddress'],
         fromaddress['fromAddress']]
      end
    end,

    accounts: lambda do |connection|
      get("https://mail.#{connection['domain']}/api/accounts")['data']
        .map do |accountdetails|
        [accountdetails['displayName'],
         accountdetails['accountId']]
      end
    end,

    folders: lambda do |connection|
      account_id = call(:getAccountId, connection)
      call(:getFolders, get("https://mail.#{connection['domain']}/api/accounts"\
        "/#{account_id}/folders")['data'])
        .map { |folder| [folder['folderName'], folder['folderName']] }
    end
  },

  actions: {

    send_mail: {
      config_fields: [
        { name: 'Account', control_type: 'select', pick_list:
          'accounts', optional: true,
          hint: 'Select the account (Zoho account/ POP account)
           from the list of accounts available in Zoho Mail.' },
        { name: 'From', control_type: 'select',
          pick_list: 'fromAddress', optional: false },
        { name: 'To', optional: false,
          hint: 'comma separated value of valid email addresses' },
        { name: 'Subject', optional: false },
        { name: 'Content', optional: false },
        { name: 'Cc',
          hint: 'Comma separated value of valid email addresses' },
        { name: 'Bcc',
          hint: 'Comma separated value of valid email addresses' },
        { name: 'Body Type',
          control_type: 'select',
          pick_list: [
            %w[html html],
            %w[plaintext plaintext]
          ] }
      ],
      execute: lambda { |connection, input|
        account_id = if input['Account'].blank?
                       call(:getAccountId, connection)
                     else
                       input['Account']
                     end

        payload = {
          'fromAddress' => input['From'],
          'toAddress' => input['To'],
          'subject' => input['Subject'],
          'content' => input['Content'],
          'ccAddress' => input['Cc'],
          'bccAddress' => input['Bcc'],
          'mailFormat' => input['Body Type']
        }
        post("https://mail.#{connection['domain']}"\
          "/api/accounts/#{account_id}/messages", payload)['data']
      },

      sample_output: lambda do |_connection, input|
        {
          fromAddress: input['From'],
          subject: input['Subject'],
          toAddress: input['To'],
          content: input['Content'],
          ccAddress: input['Cc'],
          bccAddress: input['Bcc']
        }
      end,

      output_fields: lambda { |object_definitions|
                       object_definitions['sendMailResponse']
                     }
    },

    create_draft: {
      config_fields: [
        { name: 'Account', control_type: 'select',
          pick_list: 'accounts', optional: true,
          hint: 'Select the account (Zoho account/ POP account)
           from the list of accounts available in Zoho Mail.' },
        { name: 'From', control_type: 'select',
          pick_list: 'fromAddress', optional: false },
        { name: 'To', optional: false,
          hint: 'comma separated value of valid email addresses' },
        { name: 'Subject', optional: false },
        { name: 'Content', optional: false },
        { name: 'Cc',
          hint: 'Comma separated value of valid email addresses' },
        { name: 'Bcc',
          hint: 'Comma separated value of valid email addresses' },
        { name: 'Body Type',
          control_type: 'select',
          pick_list: [
            %w[html html],
            %w[plaintext plaintext]
          ] }
      ],
      execute: lambda { |connection, input|
        account_id = if input['Account'].blank?
                       call(:getAccountId, connection)
                     else
                       input['Account']
                     end
        payload = {
          'fromAddress' => input['From'],
          'toAddress' => input['To'],
          'subject' => input['Subject'],
          'content' => input['Content'],
          'ccAddress' => input['Cc'],
          'bccAddress' => input['Bcc'],
          'mailFormat' => input['Body Type'],
          'mode' => 'draft'
        }
        post("https://mail.#{connection['domain']}"\
          "/api/accounts/#{account_id}/messages", payload)['data']
      },
      sample_output: lambda do |_connection, input|
        {
          fromAddress: input['From'],
          subject: input['Subject'],
          toAddress: input['To'],
          content: input['Content'],
          ccAddress: input['Cc'],
          bccAddress: input['Bcc']
        }
      end,

      output_fields: lambda { |object_definitions|
                       object_definitions['sendMailResponse']
                     }
    },

    create_task: {
      config_fields: [
        { name: 'Account', control_type: 'select',
          pick_list: 'accounts', optional: true,
          hint: 'Select the account (Zoho account/ POP account)
          from the list of accounts available in Zoho Mail.' },
        { name: 'From', control_type: 'select',
          pick_list: 'fromAddress', optional: false },
        { name: 'To', optional: false, control_type: 'email',
          hint: 'Assignee' },
        { name: 'Subject', optional: false },
        { name: 'Content' }

      ],
      execute: lambda { |connection, input|
                 account_id = if input['Account'].blank?
                                call(:getAccountId, connection)
                              else
                                input['Account']
                              end
                 payload = {
                   'fromAddress' => input['From'],
                   'toAddress' => input['To'].gsub('@', '+task@'),
                   'subject' => input['Subject'],
                   'content' => input['Content'],
                   'ccAddress' => input['Cc'],
                   'bccAddress' => input['Bcc'],
                   'mailFormat' => input['Body Type']
                 }
                 post("https://mail.#{connection['domain']}/"\
                  "api/accounts/#{account_id}/messages", payload)['data']
               },

      sample_output: lambda do |_connection, input|
        {
          fromAddress: input['From'],
          subject: input['Subject'],
          toAddress: input['To'],
          content: input['Content'],
          ccAddress: input['Cc'],
          bccAddress: input['Bcc']
        }
      end,

      output_fields: lambda { |object_definitions|
                       object_definitions['sendMailResponse']
                     }
    }

  },

  triggers: {

    new_mail: {
      type: :paging_desc,

      input_fields: lambda do
        [
          { name: 'Account', control_type: 'select',
            pick_list: 'accounts', optional: true,
            hint: 'Select the account (Zoho account/ POP account)
             from the list of accounts available in Zoho Mail.' }
        ]
      end,
      poll: lambda do |connection, input, page|
        limit = 50
        page ||= 0
        offset = (limit * page) + 1
        account_id = if input['Account'].blank?
                       call(:getAccountId, connection)
                     else
                       input['Account']
                     end

        response = get("https://mail.#{connection['domain']}"\
          "/api/accounts/#{account_id}/messages/search")
                   .params(searchKey: 'newMails',
                           limit: limit,
                           includeto: 'true',
                           start: offset,
                           receivedTime: Time.now.to_i * 1000 -
                           3_600_000)['data']
        input = { 'connection' => connection }
                .merge({ 'accountId' => account_id }
                  .merge('response' => response))
        response = call(:addContent, input)
        {
          events: response,
          next_page: response.length >= limit ? page + 1 : nil
        }
      end,

      document_id: lambda do |response|
        response['messageId']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['newMailResponse']
      end
    },
    new_mail_matching_search: {
      type: :paging_desc,

      input_fields: lambda do
        [
          { name: 'Account', control_type: 'select',
            pick_list: 'accounts', optional: true,
            hint: 'Select the account (Zoho account/ POP account)
            from the list of accounts available in Zoho Mail.' },
          {
            name: 'search',
            optional: false,
            hint: 'This works the same as the advanced search in Zoho Mail.'\
             'Example search string : entire:bill::sender:payments@example.com'\
             'The above search string list all Emails from the'\
             'sender payments@example.com, with the word bill'\
             'anywhere in the Email content' \
            "<a href='https://www.zoho.com/mail/help/search-syntax.html' " \
            "target='_blank'>Learn more</a>"
          }
        ]
      end,
      poll: lambda do |connection, input, page|
              limit = 50
              page ||= 0
              offset = (limit * page) + 1
              account_id = if input['Account'].blank?
                             call(:getAccountId, connection)
                           else
                             input['Account']
                           end
              response = get("https://mail.#{connection['domain']}"\
                "/api/accounts/#{account_id}/messages/search")
                         .params(searchKey: input['search'],
                                 limit: limit,
                                 includeto: 'true',
                                 start: offset,
                                 receivedTime: Time.now.to_i * 1000 -
                           3_600_000)['data']
              input = { 'connection' => connection }
                      .merge({ 'accountId' => account_id }
                        .merge('response' => response))
              response = call(:addContent, input)
              {
                events: response,
                next_page: response.length >= 50 && page < 5 ? page + 1 : nil
              }
            end,

      document_id: lambda do |response|
                     response['messageId']
                   end,

      output_fields: lambda do |object_definitions|
                       object_definitions['newMailResponse']
                     end
    },
    new_mail_in_folder: {
      type: :paging_desc,

      input_fields: lambda do
                      [
                        { name: 'Account', control_type: 'select',
                          pick_list: 'accounts', optional: true,
                          hint: 'Select the account (Zoho account/ POP account)
                           from the list of accounts available in Zoho Mail.' },
                        { name: 'folderName', control_type: 'select',
                          pick_list: 'folders', optional: false }

                      ]
                    end,
      poll: lambda do |connection, input, page|
              limit = 50
              page ||= 0
              offset = (limit * page) + 1
              account_id = if input['Account'].blank?
                             call(:getAccountId, connection)
                           else
                             input['Account']
                           end
              response = get("https://mail.#{connection['domain']}"\
                "/api/accounts/#{account_id}/messages/search")
                         .params(searchKey: 'in:' + input['folderName'] +
                          '::fromdate:' + (Time.now - 172_800)
                          .strftime('%d-%b-%Y'),
                                 limit: limit,
                                 includeto: 'true',
                                 start: offset)['data']
              input = { 'connection' => connection }
                      .merge({ 'accountId' => account_id }
                        .merge('response' => response))
              response = call(:addContent, input)
              {
                events: response,
                next_page: response.length >= 50 && page < 5 ? page + 1 : nil
              }
            end,

      document_id: lambda do |response|
                     response['messageId']
                   end,

      output_fields: lambda do |object_definitions|
                       object_definitions['newMailResponse']
                     end
    }
  }
}
