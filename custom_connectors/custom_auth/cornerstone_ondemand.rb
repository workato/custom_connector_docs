{
  title: 'Cornerstone OnDemand',

  connection: {
    fields: [
      {
        name: 'corpname',
        optional: false
      },
      {
        name: 'api_key',
        optional: false
      },
      {
        name: 'api_secret',
        optional: false,
        control_type: 'password'
      },
      {
        name: 'user_name',
        optional: false
      },
      {
        name: 'alias',
        optional: false
      }
    ],

    # We use a custom authorization scheme:
    # https://docs.workato.com/developing-connectors/sdk/authentication/custom-authentication.html
    authorization: {
      # How to acquire the token:
      # https://docs.workato.com/developing-connectors/sdk/authentication/custom-authentication.html#acquire
      acquire: lambda do |connection|
        request = call(
          :signed_request,
          connection['api_secret'],
          'POST',
          connection['corpname'],
          '/services/api/sts/session',
          { 'x-csod-api-key': connection['api_key'] },
          { userName: connection['user_name'], alias: connection['alias'] },
          ''
        )
        
        api_token = request.
          format_xml(nil, strip_response_namespaces: true).
          # Request lazy-executed here.
          # XPath-like walk of the API response
          dig('cornerstoneApi', 0, 'data', 0, 'Session', 0, 'Token', 0, 'content!')

        # Result is added to the connection hash
        { api_token: api_token }
      end,

      # How to know when to re-acquire the token.  Short-hand version of:
      # https://docs.workato.com/developing-connectors/sdk/authentication/custom-authentication.html#refreshon
      refresh_on: 401,

      apply: lambda do |connection|
        path = current_url.gsub("https://#{connection['corpname'].csod.com", '').gsub(/\?.*$/, '')
        timestamp = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%S.%3N')
        msg = [
          current_verb.to_s.upcase,
          "x-csod-date:#{timestamp}",
          "x-csod-session-token:#{connection['session_token']}",
          path
        ].join("\n")
        headers(
          'x-csod-date': timestamp,
          'x-csod-session-token': connection['session_token'],
          'x-csod-signature': msg.hmac_sha512(connection['session_secret'].decode_base64)
        )
      end
    }
  },

  # https://docs.workato.com/developing-connectors/sdk/reusable-methods.html
  methods: {
    # Auth mixed in here instead.
    signed_request: lambda do |hmac_secret, verb, corpname, path, headers, url_params, payload|
      timestamp = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%S.%3N')

      msg = verb.to_s.upcase + "\n" +
        headers.
        merge('x-csod-date': timestamp).
        sort.
        map { |name, value| "#{name.downcase}:#{value}" }.
        join("\n") + "\n" +
        path

      signature = msg.hmac_sha512(hmac_secret).encode_base64

      if verb.to_s.downcase == 'get'
        get("https://#{corpname}.csod.com#{path}").
          params(url_params).
          headers(headers.merge('x-csod-signature': signature))
      elsif verb.to_s.downcase == 'post'
        post("https://#{corpname}.csod.com#{path}").
          params(url_params).
          headers(headers.merge('x-csod-signature': signature))
      else
        error("Unsupported request verb #{verb}")
      end
    end,
  },

  test: lambda do |connection|
    call(
      :signed_request,
      connection['api_token'],
      'GET',
      connection['corpname'],
      '/services/api/OrgUnits/OU',
      { 'x-csod-api-key': connection['api_key'] },
      {},
      ''
    )
  end,

  actions: {
    get_ous: {
      execute: lambda do |connection, _input|
        call(
          :signed_request,
          connection['api_token'],
          'GET',
          connection['corpname'],
          '/services/api/OrgUnits/OU',
          { 'x-csod-api-key': connection['api_key'] },
          {},
          ''
        )
      end
    }
  }
}
