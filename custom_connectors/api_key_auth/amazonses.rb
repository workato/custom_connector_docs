{
  title: 'Amazon SES',
  description: 'the user should have ListIdentities and SendEmail permissions' \
  ' to use the connector. SendEmail action from email address should ' \
  'be verfied in AWS',

  connection: {
    fields: [
      {
        name: 'api_key',
        label: 'Access key ID',
        optional: false,
        hint: 'Go to <b>AWS account name</b> > <b>My Security Credentials</b>' \
        ' > <b>Users</b>. Get API key from existing user or create new user.'
      },
      {
        name: 'secret_key',
        label: 'Secret access key',
        optional: false,
        hint: 'Go to <b>AWS account name</b> > <b>My Security Credentials</b>' \
        ' > <b>Users</b>. Get secret key from existing user or create new user.'
      },
      {
        name: 'region',
        label: 'Region',
        optional: false,
        hint: 'Region is typically provided in the SES account URL. ' \
        'If your account URL is <b>https://console.aws.amazon.com/ses/home?' \
        'region=us-east-1</b>, use us-west-1 as the region.
        '
      }
    ],

    authorization: {
      type: 'custom',
      credentials: lambda do |_|
      end
    }
  },

  methods: {
    generate_aws_signature: lambda do |input|
      api_key = input[:api_key]
      secret_key = input[:secret_key]
      service = 'email'
      region = input[:region]
      path = input[:path]
      http_method = input[:http_method]
      params = input[:params] || ''
      payload = input[:payload] || ''
      aws_header = input[:aws_header] || {}

      time = now.to_time.strftime('%Y%m%dT%H%M%SZ')
      date = time.split('T').first
      protocol = 'https'
      host = "#{service}.#{region}.amazonaws.com"
      param_str = params.to_param
      aws_header = aws_header.
                   merge('Host' => host,
                         'Content-Type' => 'application/x-www-form-urlencoded',
                         'X-Amz-Date' => time)
      url = "#{protocol}://#{host}#{path}"
      url = url + "?#{param_str}" if params.present?
      sign_algo = 'AWS4-HMAC-SHA256'

      # Creating canonical request
      c_header = aws_header.sort.map { |k, v| "#{k.downcase}:#{v}" }.
                 join("\n") + "\n"
      c_header_keys =
        aws_header.sort.map { |k, _| k.downcase }.join(';')
      payload_hash = payload.encode_sha256.encode_hex
      param_str = params.present? ? params.to_param : ''
      step1 = [http_method, path, param_str,
               c_header, c_header_keys,
               payload_hash].join("\n").encode_sha256.encode_hex

      # creating a string to sign
      scope = [date, region, service, 'aws4_request'].join('/')
      string_sign = [sign_algo, time, scope, step1].join("\n")

      # calculating signature
      k_date = date.hmac_sha256("AWS4#{secret_key}")
      k_region = region.hmac_sha256(k_date)
      k_service = service.hmac_sha256(k_region)
      k_signing = 'aws4_request'.hmac_sha256(k_service)
      signature = string_sign.hmac_sha256(k_signing).encode_hex

      auth_header = "#{sign_algo} Credential=#{api_key}/#{scope.strip}, SignedHeaders=#{c_header_keys}, Signature=#{signature}"
      headers = aws_header.merge('Authorization' => auth_header)
      [url, headers]
    end
  },

  object_definitions: {
    send_email: {
      fields: lambda do
        [
          { name: 'Source', control_type: :email,
            label: 'Source Email Address',
            optional: false,
            hint: "The email address that is sending the email. This email ' \
            'address must be either individually verified with Amazon SES, or' \
            ' from a domain that has been verified with Amazon SES." },
          { name: 'Destination', type: :object, optional: false, properties:
            [
              { name: 'ToAddresses', control_type: :email,
                hint: 'Use comma-separated string for multiple addresses',
                sticky: true },
              { name: 'CcAddresses', control_type: :email,
                hint: 'Use comma-separated string for multiple addresses',
                sticky: true },
              { name: 'BccAddresses', control_type: :email,
                hint: 'Use comma-separated string for multiple addresses',
                sticky: true }
            ] },
          { name: 'subject', label: 'Subject', optional: false },
          { name: 'email_type', control_type: 'select',
            pick_list: 'content_type', optional: false },
          { name: 'message', label: 'Message', optional:
            false, control_type: 'text-area',
            hint: 'Plain text if selected email type is <b>Text</b>, ' \
            'HTML formatted if selected email type is <b>HTML</b>' }
          # Below are additional optional inputs for this endpoint.
          # They are commented out because it has not been tested.

          # { name: 'SourceArn',
          #   hint: "This parameter is used only for sending authorization. ' \
          #   'It is the ARN of the identity that is associated with the ' \
          #   'sending authorization policy that permits you to send for the' \
          #   ' email address specified in the Source parameter." },
          # { name: 'Destination.ToAddresses',
          #   hint: 'Use comma-separated string for multiple addresses',
          #   sticky: true }
          # { name: 'ReplyToAddresses',
          #   hint: "The reply-to email address(es) for the message. If ' \
          #   'the recipient replies to the message, each reply-to address' \
          #   ' will receive the reply. Use comma-separated string for ' \
          #   'multiple addresses" },
          # { name: 'ReturnPath',
          #   hint: "The email address that bounces and complaints will be ' \
          #   'forwarded to when feedback forwarding is enabled. If the' \
          #   ' message cannot be delivered to the recipient, then an error' \
          #   ' message will be returned from the recipient's ISP; this message'
          #   ' will then be forwarded to the email address specified by the' \
          #   ' ReturnPath parameter. The ReturnPath parameter is never '
          #   'overwritten. This email address must be either individually ' \
          #   'verified with Amazon SES, or from a domain that has been ' \
          #   'verified with Amazon SES." },
          # { name: 'ReturnPathArn',
          #   hint: "This parameter is used only for sending authorization.' \
          #   ' It is the ARN of the identity that is associated with the ' \
          #   'sending authorization policy that permits you to use the email' \
          #   ' address specified in the ReturnPath parameter." },
          # { name: 'ConfigurationSetName',
          #   hint: "The name of the configuration set to use when you send' \
          #   ' an email using SendEmail." },
          # { name: 'Tags',
          #   hint: "A list of tags, in the form of name/value pairs, ' \
          #   'to apply to an email that you send using SendEmail. Tags ' \
          #   'correspond to characteristics of the email that you define, ' \
          #   'so that you can publish email sending events." }
        ]
      end
    }
  },

  test: lambda do |connection|
    # List Identities
    # https://docs.aws.amazon.com/ses/latest/APIReference/API_ListIdentities.html
    signature = call(:generate_aws_signature,
                     { api_key: connection['api_key'],
                       secret_key: connection['secret_key'],
                       region: connection['region'],
                       path: '/',
                       http_method: 'POST',
                       params: '',
                       payload: 'Action=ListIdentities&Version=2010-12-01' })

    url = signature[0]
    headers = signature[1]

    post(url).headers(headers).
      request_body('Action=ListIdentities&Version=2010-12-01')
  end,

  actions: {
    send_email: {
      title: 'Send email',
      description: "Send <span class='provider'>email</span> in " \
        "<span class='provider'>Amazon SES</span>",
      help: 'Uses the <a href="https://docs.aws.amazon.com/ses/latest/" \
      "APIReference/API_SendEmail.html" target="_blank">SendEmail API</a>.',

      input_fields: lambda do |object_definitions|
        object_definitions['send_email']
      end,

      execute: lambda do |connection, input|
        # Format inputs to SES specifications.
        # Destination addresses need to be changed to members.N notation
        if input.dig('Destination', 'ToAddresses').present?
          to_addresses = input.dig('Destination', 'ToAddresses').split(',').
                         flatten
          (1..to_addresses.length).each do |idx|
            input["Destination.ToAddresses.member.#{idx}"] =
              to_addresses[idx - 1]
          end
        end

        if input.dig('Destination', 'CcAddresses').present?
          cc_addresses = input.dig('Destination', 'CcAddresses').split(',').
                         flatten
          (1..cc_addresses.length).each do |idx|
            input["Destination.CcAddresses.member.#{idx}"] =
              cc_addresses[idx - 1]
          end
        end

        if input.dig('Destination', 'BccAddresses').present?
          bcc_addresses = input.dig('Destination', 'BccAddresses').split(',').
                          flatten
          (1..bcc_addresses.length).each do |idx|
            input["Destination.BccAddresses.member.#{idx}"] =
              bcc_addresses[idx - 1]
          end
        end

        case input['email_type']
        when 'html'
          input['Message.Body.Html.Data'] = input['message']
        when 'text'
          input['Message.Body.Text.Data'] = input['message']
        end

        # There is an issue with directly setting the input field name as
        # 'Message.Subject.Data'. Doing so will cause the recipe editor
        # to complain that this required field is not filled even when it is.
        # Thus, 'subject' is used first then renamed to 'Message.Subject.Data'
        input['Message.Subject.Data'] = input['subject']

        # Remove fields which should not go into the signature generation
        input = input.reject { |k,_| %w[Destination subject email_type message].include?(k) }

        input = "Action=SendEmail&#{input.encode_www_form}"

        signature = call(:generate_aws_signature,
                         { api_key: connection['api_key'],
                           secret_key: connection['secret_key'],
                           region: connection['region'],
                           path: '/',
                           http_method: 'POST',
                           params: '',
                           payload: input })

        url = signature[0]
        headers = signature[1]

        res = post(url).
              headers(headers).request_body(input).
              after_error_response(//) do |_code, body, _header, message|
                error("#{message}: #{body}")
              end
        {
          'RequestId': res.dig('SendEmailResponse',
                               'ResponseMetadata', 'RequestId'),
          'MessageId': res.dig('SendEmailResponse',
                               'SendEmailResult', 'MessageId')
        }
      end,

      output_fields: lambda do |_|
        [
          { name: 'RequestId' },
          { name: 'MessageId' }
        ]
      end
    }
  },

  pick_lists: {
    content_type: lambda do
      [
        %w[HTML html],
        %w[Text text]
      ]
    end
  }
}
