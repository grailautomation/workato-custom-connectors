{
  title: "Hunter.io",

  connection: {
    fields: [
      {
        name: 'api_key',
        control_type: 'password',
        label: 'API Key',
        hint: 'You can find the API key in your dashboard',
        optional: false
      },
    ],
    authorization: {
      type: 'api_key',

      apply: lambda do |connection|
        params(api_key: connection['api_key'])
      end
    },
    base_uri: lambda do |_connection|
      'https://api.hunter.io'
    end
  },
  test: lambda do |_connection|
    get('/v2/account')
  end,

  actions: {

    email_finder: {
      title: "Find Email",
      subtitle: "Find an email using domain and name",
      description: lambda do |_input, _picklist_label|
        "Find <span class='provider'>email</span> in <span class='provider'>Hunter</span>"
      end,
      help: lambda do |_input, _picklist_label|
        "This action finds the most likely email address from a domain name, a first name and a last name."
      end,
      input_fields: lambda do |_object_definitions, _connection, _config_fields|
        [
          { name: 'domain', hint: 'Domain name of the company', optional: false, sticky: true },
          { name: 'first_name', hint: 'First name of the person', optional: false, sticky: true },
          { name: 'last_name', hint: 'Last name of the person', optional: false, sticky: true },
          { name: 'company', hint: 'Company name', optional: true, sticky: true },
          { name: 'max_duration', hint: 'Maximum duration of the request in seconds', optional: true, sticky: true }
        ]
      end,
      execute: lambda do |_connection, input, _extended_input_schema, _extended_output_schema, _continue|
        get("v2/email-finder").params(domain: input['domain'], first_name: input['first_name'], last_name: input['last_name'], company: input['company'], max_duration: input['max_duration']).after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,
      output_fields: lambda do |_object_definitions, _connection, _config_fields|
        [
          { name: 'data', type: 'object', properties: [
            { name: 'first_name' },
            { name: 'last_name' },
            { name: 'email' },
            { name: 'score', type: 'integer' },
            { name: 'domain' },
            { name: 'accept_all', type: 'boolean' },
            { name: 'position' },
            { name: 'twitter' },
            { name: 'linkedin_url' },
            { name: 'phone_number' },
            { name: 'company' },
            { name: 'sources', type: 'array', of: 'object', properties: [
              { name: 'domain' },
              { name: 'uri' },
              { name: 'extracted_on' },
              { name: 'last_seen_on' },
              { name: 'still_on_page', type: 'boolean' }
            ] },
            { name: 'verification', type: 'object', properties: [
              { name: 'date' },
              { name: 'status' }
            ] }
          ] },
          { name: 'meta', type: 'object', properties: [
            { name: 'params', type: 'object', properties: [
              { name: 'first_name' },
              { name: 'last_name' },
              { name: 'full_name' },
              { name: 'domain' },
              { name: 'company' },
              { name: 'max_duration' }
            ] }
          ] }
        ]
      end
    },

    verify_email: {
      title: "Verify Email",
      subtitle: "Verify an email address",
      description: lambda do
        "Verify <span class='provider'>email</span> in <span class='provider'>Hunter</span>"
      end,
      help: lambda do
        "This action verifies the deliverability of an email address."
      end,
      input_fields: lambda do
        [
          { name: "email", hint: "Email address to verify", type: "string", control_type: "text", optional: false, sticky: true }
        ]
      end,
      execute: lambda do |connection, input|
        get("https://api.hunter.io/v2/email-verifier").params(email: input["email"], api_key: connection['api_key']).after_error_response(/.*/) do |code, body, header, message|
          error("#{message}: #{body}")
        end
      end,
      output_fields: lambda do
        [
          { name: "data", type: "object", properties: [
            { name: "status", type: "string" },
            { name: "result", type: "string" },
            { name: "score", type: "integer" },
            { name: "email", type: "string" },
            { name: "regexp", type: "boolean" },
            { name: "gibberish", type: "boolean" },
            { name: "disposable", type: "boolean" },
            { name: "webmail", type: "boolean" },
            { name: "mx_records", type: "boolean" },
            { name: "smtp_server", type: "boolean" },
            { name: "smtp_check", type: "boolean" },
            { name: "accept_all", type: "boolean" },
            { name: "block", type: "boolean" },
            { name: "sources", type: "array", of: "object", properties: [
              { name: "domain", type: "string" },
              { name: "uri", type: "string" },
              { name: "extracted_on", type: "date_time" },
              { name: "last_seen_on", type: "date_time" },
              { name: "still_on_page", type: "boolean" }
            ]}
          ]},
          { name: "meta", type: "object", properties: [
            { name: "params", type: "object", properties: [
              { name: "email", type: "string" }
            ]}
          ]}
        ]
      end
    },

    domain_search: {
      title: "Domain Search",
      subtitle: "Search for email addresses from a domain",
      description: lambda do |_input, _picklist_label|
        "Search for <span class='provider'>email addresses</span> in <span class='provider'>Hunter</span>"
      end,
      help: lambda do |_input, _picklist_label|
        "This action allows you to search for all email addresses associated with a specific domain."
      end,
      input_fields: lambda do |_object_definitions, _connection, _config_fields|
        [
          { name: "domain", hint: "Domain name from which you want to find the email addresses.", type: "string", control_type: "text", optional: false },
          { name: "company", hint: "The company name from which you want to find the email addresses.", type: "string", control_type: "text", optional: false },
          { name: "limit", hint: "Specifies the max number of email addresses to return. The default is 10.", type: "integer", control_type: "number", optional: true, sticky: true },
          { name: "offset", hint: "Specifies the number of email addresses to skip. The default is 0.", type: "integer", control_type: "number", optional: true, sticky: true },
          { name: "type", hint: "Get only personal or generic email addresses.", type: "string", control_type: "text", optional: true, sticky: true },
          { name: "seniority", hint: "Get only email addresses for people with the selected seniority level. The possible values are junior, senior or executive.", type: "string", control_type: "text", optional: true, sticky: true }
        ]
      end,
      execute: lambda do |_connection, input, _extended_input_schema, _extended_output_schema, _continue|
        get("v2/domain-search").params(input).after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,
      output_fields: lambda do |_object_definitions, _connection, _config_fields|
        [
          { name: "data", type: "object", properties: [
            { name: "domain", type: "string" },
            { name: "disposable", type: "boolean" },
            { name: "webmail", type: "boolean" },
            { name: "accept_all", type: "boolean" },
            { name: "pattern", type: "string" },
            { name: "organization", type: "string" },
            { name: "description", type: "string" },
            { name: "industry", type: "string" },
            { name: "twitter", type: "string" },
            { name: "facebook", type: "string" },
            { name: "linkedin", type: "string" },
            { name: "instagram", type: "string" },
            { name: "youtube", type: "string" },
            { name: "technologies", type: "array", properties: [] },
            { name: "country", type: "string" },
            { name: "state", type: "string" },
            { name: "city", type: "string" },
            { name: "postal_code", type: "string" },
            { name: "street", type: "string" },
            { name: "emails", type: "array", properties: [
              { name: "value", type: "string" },
              { name: "type", type: "string" },
              { name: "confidence", type: "integer" },
              { name: "sources", type: "array", properties: [
                { name: "domain", type: "string" },
                { name: "uri", type: "string" },
                { name: "extracted_on", type: "date_time" },
                { name: "last_seen_on", type: "date_time" },
                { name: "still_on_page", type: "boolean" }
              ] },
              { name: "first_name", type: "string" },
              { name: "last_name", type: "string" },
              { name: "position", type: "string" },
              { name: "seniority", type: "string" },
              { name: "department", type: "string" },
              { name: "linkedin", type: "string" },
              { name: "twitter", type: "string" },
              { name: "phone_number", type: "string" },
              { name: "verification", type: "object", properties: [
                { name: "date", type: "date_time" },
                { name: "status", type: "string" }
              ] }
            ] },
            { name: "linked_domains", type: "array", properties: [] }
          ] },
          { name: "meta", type: "object", properties: [
            { name: "results", type: "integer" },
            { name: "limit", type: "integer" },
            { name: "offset", type: "integer" },
            { name: "params", type: "object", properties: [
              { name: "domain", type: "string" },
              { name: "company", type: "string" },
              { name: "type", type: "string" },
              { name: "seniority", type: "string" },
              { name: "department", type: "string" }
            ] }
          ] }
        ]
      end
    }
  },

  triggers: {
    # Add trigger code here
  }
}
