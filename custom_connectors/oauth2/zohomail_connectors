{
  title: "Zoho Mail",

  connection: {
   fields: [
      {
        name: "domain",
        control_type: "select",
        pick_list: [
          %w[.com zoho.com],
          %w[.eu zoho.eu],
          %w[.in zoho.in]
        ],
        optional: false
      },
      {
        name: "client_id",
        optional: false,
        hint: "Find your client ID & client secret <a href='https://accounts.zoho.com/developerconsole' target='_blank'>here</a>  <br /> Authorized redirect URI:
 https://www.workato.com/oauth/callback"
      },
      {
        name: "client_secret",
        optional: false
      }
        ], 
     
authorization: {
      type: "oauth2",

authorization_url: lambda do |connection|
      scope = [     "VirtualOffice.search.READ",
              "VirtualOffice.folders.READ",
                    "VirtualOffice.accounts.READ",
                    "VirtualOffice.messages.READ",
                    "VirtualOffice.messages.CREATE"].join(" ")
    "https://accounts.#{connection['domain']}/oauth/v2/auth?scope=#{scope}&client_id=#{connection["client_id"]}&response_type=code&access_type=offline&prompt=consent"
      end,

      acquire: lambda do |connection, auth_code, redirect_uri|
        scope = [  "VirtualOffice.search.READ",
                    "VirtualOffice.accounts.READ",
                "VirtualOffice.folders.READ",
                    "VirtualOffice.messages.READ",
                    "VirtualOffice.messages.CREATE"].join(" ")
        
    response = post("https://accounts.#{connection['domain']}/oauth/v2/token").
                   params(client_id: connection["client_id"],
                             client_secret: connection["client_secret"],
                             grant_type: "authorization_code",
                             code: auth_code,
                             scope:scope,
                             redirect_uri: redirect_uri)
               

        [{
            access_token: response["access_token"],
            refresh_token: response["refresh_token"]
          },
          nil, 
          {
            refresh_token: response["refresh_token"]
          }]
      end,

      refresh: lambda do |connection, redirect_uri|
        scope = [ "VirtualOffice.search.READ",
                    "VirtualOffice.accounts.READ",
                "VirtualOffice.folders.READ",
                    "VirtualOffice.messages.READ",
                    "VirtualOffice.messages.CREATE"].join(" ")
        
        post("https://accounts.#{connection['domain']}/oauth/v2/token").
          params(client_id: connection["client_id"],
                  client_secret: connection["client_secret"],
                  grant_type: "refresh_token",
                  refresh_token: connection["refresh_token"],
                scope:scope,
                  redirect_uri: redirect_uri)
      end,
      refresh_on: [404,500],

      apply: lambda do |_connection, access_token|
        headers("Authorization" => "Zoho-oauthtoken #{access_token}")
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
          {
            name: 'data',
            type: :object,
            properties: [
              {
                name: 'subject',
                label: 'subject',
              },
              {
                name: 'fromAddress',
                label: 'fromAddress',
              },
              {
                name: 'toAddress',
                label: 'toAddress',
              },
              { name: 'content' }
            ]
          }
        ]
    end
    }

  },

  methods: {
    getAccountId: lambda do |parsed|
      accountId = 0
     parsed.each do |accData|
       if (accData['type'] == 'ZOHO_ACCOUNT')
        accountId = accData['accountId']
      end
    end
      accountId
  end,
  getFromAddresses: lambda do |parsed|
          fromAddresses = []
  parsed.each do |accData|
    if (accData['type'] == 'ZOHO_ACCOUNT')
      fromAddresses = accData['sendMailDetails']
    end
  end
  fromAddresses
  end,

  getFolders: lambda do |parsed|
            folderJson = []
    parsed.each do |folderData|
      if (folderData['folderType'] == 'Inbox')
        folderJson <<(folderData)
      end
    end
    folderJson
    end,
  addContent: lambda do |input|
    response = input['response']
    connection = input['connection']
    accountId = input['accountId']
  mailContent = []
  response.each do |mailJson|
    if (!mailJson['folderId'].blank?)
  content = get("https://mail.#{connection['domain']}/api/accounts/#{accountId}/folders/#{mailJson['folderId']}/messages/#{mailJson['messageId']}/content")['data']['content']
    mailJson = mailJson.merge({ "content" => content })
      mailContent << mailJson
    end
  end
    mailContent
  end
  },

  pick_lists: {
    fromAddress: lambda do |connection|
      call(:getFromAddresses, get("https://mail.#{connection['domain']}/api/accounts")['data']).
      map { |fromAddress| [fromAddress["fromAddress"], fromAddress["fromAddress"]] }
    end,

    accounts: lambda do |connection|
      get("https://mail.#{connection['domain']}/api/accounts")['data'].
      map { |accountDetails| [accountDetails["displayName"], accountDetails["accountId"]] }
    end,

    folders: lambda do |connection|
      accountId = call(:getAccountId, get("https://mail.#{connection['domain']}/api/accounts")['data'])
      call(:getFolders, get("https://mail.#{connection['domain']}/api/accounts/#{accountId}/folders")['data']).
      map { |folder| [folder["folderName"], folder["folderName"]] }
    end
  },

  actions: {
    

    send_mail: {
      config_fields: [
          { name: "Account", control_type: "select", pick_list: "accounts", optional: true, 
            hint: "Select the account (Zoho account/ POP account) from the list of accounts available in Zoho Mail." },
          { name: "From", control_type: "select", pick_list: "fromAddress", optional: false },
          { name: "To", optional: false, optional: false, hint: "comma separated value of valid email addresses" },
          {name:"Subject", optional: false},
          {name:"Content", optional: false},
          { name: "Cc", hint: "Comma separated value of valid email addresses" },
          { name: "Bcc", hint: "Comma separated value of valid email addresses" },
          { name: "Body Type", 
            control_type: "select",
            pick_list: [
              %w[html html],
              %w[plaintext plaintext]
              ] }
        ],
      execute: ->(connection, input) {
          if (input["Account"].blank?)
             accountId = call(:getAccountId, get("https://mail.#{connection['domain']}/api/accounts")['data'])
          else 
             accountId =  input["Account"]
          end
          
           payload = {
            "fromAddress" => input["From"],
            "toAddress" => input["To"],
            "subject"=>input["Subject"],
            "content"=> input["Content"],
            "ccAddress"=> input["Cc"],
            "bccAddress" => input["Bcc"],
            "mailFormat" => input["Body Type"]
          } 
           post("https://mail.#{connection['domain']}/api/accounts/#{accountId}/messages", payload)
           
      },
        output_fields: lambda { |object_definitions|
        object_definitions["sendMailResponse"]
      }
    },

    create_draft: {
      config_fields: [
          { name: "Account", control_type: "select", pick_list: "accounts", optional: true, 
            hint: "Select the account (Zoho account/ POP account) from the list of accounts available in Zoho Mail." },
          { name: "From", control_type: "select", pick_list: "fromAddress", optional: false },
          { name: "To", optional: false, optional: false, hint: "comma separated value of valid email addresses" },
          {name:"Subject", optional: false},
          {name:"Content", optional: false},
          { name: "Cc", hint: "Comma separated value of valid email addresses" },
          { name: "Bcc", hint: "Comma separated value of valid email addresses" },
          { name: "Body Type", 
            control_type: "select",
            pick_list: [
              %w[html html],
              %w[plaintext plaintext]
              ] }
        ],
      execute: ->(connection, input) {
          if (input["Account"].blank?)
             accountId = call(:getAccountId, get("https://mail.#{connection['domain']}/api/accounts")['data'])
          else 
             accountId =  input["Account"]
          end
           payload = {
            "fromAddress" => input["From"],
            "toAddress" => input["To"],
            "subject"=>input["Subject"],
            "content"=> input["Content"],
            "ccAddress"=> input["Cc"],
            "bccAddress" => input["Bcc"],
            "mailFormat" => input["Body Type"],
            "mode" => "draft"
          } 
           post("https://mail.#{connection['domain']}/api/accounts/#{accountId}/messages", payload)
           
      },
        output_fields: lambda { |object_definitions|
        object_definitions["sendMailResponse"]
      }
    },

  create_task: {
        config_fields: [
            { name: "Account", control_type: "select", pick_list: "accounts", optional: true, 
            hint: "Select the account (Zoho account/ POP account) from the list of accounts available in Zoho Mail." },
            { name: "From", control_type: "select", pick_list: "fromAddress", optional: false },
            { name: "To", optional: false, control_type:"email", hint: "Assignee" },
            {name:"Subject", optional: false},
            {name:"Content"}
            
          ],
        execute: ->(connection, input) {
            if (input["Account"].blank?)
             accountId = call(:getAccountId, get("https://mail.#{connection['domain']}/api/accounts")['data'])
          else 
             accountId =  input["Account"]
          end
             payload = {
              "fromAddress" => input["From"],
              "toAddress" => input["To"].gsub("@", "+task@"),
              "subject"=>input["Subject"],
              "content"=> input["Content"],
              "ccAddress"=> input["Cc"],
              "bccAddress" => input["Bcc"],
              "mailFormat" => input["Body Type"]
            } 
             post("https://mail.#{connection['domain']}/api/accounts/#{accountId}/messages", payload)
             
        },
          output_fields: lambda { |object_definitions|
          object_definitions["sendMailResponse"]
        }
      },
    
  },

  triggers: {
   
new_mail: {
  type: :paging_desc,

  input_fields: lambda do
    [
      { name: "Account", control_type: "select", pick_list: "accounts", optional: true, 
            hint: "Select the account (Zoho account/ POP account) from the list of accounts available in Zoho Mail." }
    ]
  end,
  poll: lambda do |connection, input, page|
    limit = 50
    page ||= 0
    offset = (limit * page) + 1
    if (input['Account'].blank?)
          accountId = call(:getAccountId, get("https://mail.#{connection['domain']}/api/accounts")['data'])
    else accountId =  input['Account']
    end

    response = get("https://mail.#{connection['domain']}/api/accounts/#{accountId}/messages/search").
              params(searchKey: 'newMails',
                     limit: limit,
                     includeto: "true",
                     start: offset,
                     receivedTime: Time.now.to_i*1000 - 3600000
                     )['data']
    input = { "connection" => connection }.merge({ "accountId" => accountId }.merge({ "response" => response }))
    response = call(:addContent, input)
    {
      events: response,
      next_page: (response.length >= limit) ? page + 1 : nil
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
       { name: "Account", control_type: "select", pick_list: "accounts", optional: true, 
            hint: "Select the account (Zoho account/ POP account) from the list of accounts available in Zoho Mail." },
        {
          name: 'search',
          optional: false,
           hint: "This works the same as the advanced search in Zoho Mail. Example search string : entire:bill::sender:payments@example.com \
           The above search string list all Emails from the sender payments@example.com, with the word bill anywhere in the Email content" \
          "<a href='https://www.zoho.com/mail/help/search-syntax.html' " \
          "target='_blank'>Learn more</a>",
        }
      ]
    end,
  poll: lambda do |connection, input, page|
    limit = 50
    page ||= 0
    offset = (limit * page) + 1
     if (input["Account"].blank?)
             accountId = call(:getAccountId, get("https://mail.#{connection['domain']}/api/accounts")['data'])
          else 
             accountId =  input["Account"]
          end

    response = get("https://mail.#{connection['domain']}/api/accounts/#{accountId}/messages/search").
              params(searchKey: input['search'],
                     limit: limit,
                     includeto: "true",
                     start: offset,            
                     receivedTime: Time.now.to_i*1000 - 3600000
                     )['data']
    input = { "connection" => connection }.merge({ "accountId" => accountId }.merge({ "response" => response }))
    response = call(:addContent, input)

    {
      events: response,
      next_page: page > 5 ? nil : (response.length >= limit) ? page + 1 : nil
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
       { name: "Account", control_type: "select", pick_list: "accounts", optional: true, 
            hint: "Select the account (Zoho account/ POP account) from the list of accounts available in Zoho Mail." },
       { name: "folderName", control_type: "select", pick_list: "folders", optional: false }

      ]
    end,
  poll: lambda do |connection, input, page|
    limit = 50
    page ||= 0
    offset = (limit * page) +1
    if (input["Account"].blank?)
             accountId = call(:getAccountId, get("https://mail.#{connection['domain']}/api/accounts")['data'])
          else 
             accountId =  input["Account"]
          end
    t = (Time.now - 172800).strftime("%d-%b-%Y")
    response = get("https://mail.#{connection['domain']}/api/accounts/#{accountId}/messages/search").
              params(searchKey: "in:" + input['folderName'] + "::fromdate:" +(Time.now - 172800).strftime("%d-%b-%Y"),
                     limit: limit,
                     includeto: "true",
                     start: offset
                     )['data']
    input = { "connection" => connection }.merge({ "accountId" => accountId }.merge({ "response" => response }))
    response = call(:addContent, input)

    {
      events: response,
      next_page: page > 5 ? nil : (response.length >= limit) ? page + 1 : nil
      
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
