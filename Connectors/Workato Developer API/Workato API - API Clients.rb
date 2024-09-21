{
  title: 'Workato API - API Clients',

  connection: {
    fields: [
      {
        name: 'api_key',
        type: 'string',
        control_type: 'password',
        label: 'API Key',
        optional: false,
        hint: 'Your API key for authenticating with the Workato API'
      },
      {
        name: 'base_url',
        type: 'string',
        control_type: 'text',
        label: 'Base URL',
        optional: true,
        hint: 'Base URL for the Workato API (useful for testing or custom endpoints)',
        default: 'https://www.workato.com/api/developer_api_clients'
      }
    ],

    authorization: {
      type: 'custom_auth',

      apply: lambda do |connection|
        headers('Authorization': "Bearer #{connection['api_key']}")
      end
    }
  },

  object_definitions: {
    api_client: {
      fields: lambda do
        [
          { name: 'id', type: 'integer' },
          { name: 'name', type: 'string' },
          { name: 'api_privilege_group_id', type: 'integer' },
          { name: 'all_folders', type: 'boolean' },
          { name: 'folder_ids', type: 'array', of: 'integer' },
          { name: 'environment_name', type: 'string' }
        ]
      end
    }
  },

  actions: {
    list_clients: {
      description: 'List <span class="provider">Developer API Clients</span>',
      input_fields: lambda do |object_definitions|
        [
          { name: 'per_page', type: 'integer', hint: 'Number of API clients to return in a single page. Defaults to 100. Max is 100.' },
          { name: 'page', type: 'integer', hint: 'Page number of the API clients to fetch. Defaults to 1.' }
        ]
      end,
      execute: lambda do |connection, input|
        {
          clients: get("#{connection['base_url']}").
                    params(input).
                    after_error_response(/.*/) do |code, body, headers, message|
                      error "Failed with code #{code}: #{message}"
                    end
        }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'clients', type: 'array', of: 'object', properties: object_definitions['api_client'] }
        ]
      end
    },

    create_client: {
      description: 'Create <span class="provider">Developer API Client</span>',
      input_fields: lambda do |object_definitions|
        object_definitions['api_client'].required('name', 'all_folders')
      end,
      execute: lambda do |connection, input|
        post("#{connection['base_url']}").
          payload(input).
          after_error_response(/.*/) do |code, body, headers, message|
            error "Failed with code #{code}: #{message}"
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['api_client']
      end
    },

    get_client_by_id: {
      description: 'Get <span class="provider">Developer API Client by ID</span>',
      input_fields: lambda do |object_definitions|
        [
          { name: 'id', type: 'integer', optional: false }
        ]
      end,
      execute: lambda do |connection, input|
        get("#{connection['base_url']}/#{input['id']}").
          after_error_response(/.*/) do |code, body, headers, message|
            error "Failed with code #{code}: #{message}"
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['api_client']
      end
    },

    update_client: {
      description: 'Update <span class="provider">Developer API Client</span>',
      input_fields: lambda do |object_definitions|
        object_definitions['api_client'].required('id', 'name', 'all_folders')
      end,
      execute: lambda do |connection, input|
        put("#{connection['base_url']}/#{input['id']}").
          payload(input.except('id')).
          after_error_response(/.*/) do |code, body, headers, message|
            error "Failed with code #{code}: #{message}"
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['api_client']
      end
    },

    delete_client: {
      description: 'Delete <span class="provider">Developer API Client</span>',
      input_fields: lambda do |object_definitions|
        [
          { name: 'id', type: 'integer', optional: false }
        ]
      end,
      execute: lambda do |connection, input|
        delete("#{connection['base_url']}/#{input['id']}").
          after_error_response(/.*/) do |code, body, headers, message|
            error "Failed with code #{code}: #{message}"
          end
      end
    },

    regenerate_client_token: {
      description: 'Regenerate <span class="provider">Developer API Client Token</span>',
      input_fields: lambda do |object_definitions|
        [
          { name: 'id', type: 'integer', optional: false }
        ]
      end,
      execute: lambda do |connection, input|
        post("#{connection['base_url']}/#{input['id']}/regenerate").
          after_error_response(/.*/) do |code, body, headers, message|
            error "Failed with code #{code}: #{message}"
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['api_client']
      end
    },

    list_client_roles: {
      description: 'List <span class="provider">Developer API Client Roles</span>',
      execute: lambda do |connection, input|
        {
          roles: get("#{connection['base_url']}/roles").
                   params(input).
                   after_error_response(/.*/) do |code, body, headers, message|
                     error "Failed with code #{code}: #{message}"
                   end
        }
      end,
      output_fields: lambda do |object_definitions|
        [{ name: 'roles', type: 'array', of: 'object'}]
      end
    }
  }
}