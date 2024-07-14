{
  title: 'Pitchbook',

  connection: {
    fields: [
      {
        name: 'api_key',
        label: 'API Key',
        optional: false,
        control_type: 'password',
        hint: 'You can find your API Key in your Pitchbook account settings.'
      }
    ],

    authorization: {
      type: 'api_key',

      apply: lambda do |connection|
        headers("Authorization": "PB-Token #{connection['api_key']}")
      end
    },

    base_uri: lambda do
      'https://api.pitchbook.com'
    end
  },

  test: lambda do |connection|
    get("/lookup-tables/structure")
  end,

  methods: {
    fetch_lookup_table: lambda do |connection, table_name|
      get("/lookup-tables").
        params(tableNames: table_name)['items'].first['codes']
    end
  },

  pick_lists: {
    ownership_status: lambda do |connection|
      call(:fetch_lookup_table, connection, 'OWNERSHIP_STATUS').map do |item|
        [item['description'], item['code']]
      end
    end,

    backing_status: lambda do |connection|
      call(:fetch_lookup_table, connection, 'BACKING_STATUS').map do |item|
        [item['description'], item['code']]
      end
    end,

    business_status: lambda do |connection|
      call(:fetch_lookup_table, connection, 'BUSINESS_STATUS').map do |item|
        [item['description'], item['code']]
      end
    end,

    us_state: lambda do |connection|
      call(:fetch_lookup_table, connection, 'US_STATE').map do |item|
        [item['description'], item['code']]
      end
    end,

    country: lambda do |connection|
      call(:fetch_lookup_table, connection, 'COUNTRY').map do |item|
        [item['description'], item['code']]
      end
    end,

    industry: lambda do |connection|
      call(:fetch_lookup_table, connection, 'INDUSTRY').map do |item|
        [item['description'], item['code']]
      end
    end,

    vertical: lambda do |connection|
      call(:fetch_lookup_table, connection, 'VERTICAL').map do |item|
        [item['description'], item['code']]
      end
    end,

    deal_type: lambda do |connection|
      call(:fetch_lookup_table, connection, 'DEAL_TYPE').map do |item|
        [item['description'], item['code']]
      end
    end,

    deal_status: lambda do |connection|
      call(:fetch_lookup_table, connection, 'DEAL_STATUS').map do |item|
        [item['description'], item['code']]
      end
    end,

    exit_type: lambda do |connection|
      call(:fetch_lookup_table, connection, 'EXIT_TYPE').map do |item|
        [item['description'], item['code']]
      end
    end,

    exit_status: lambda do |connection|
      call(:fetch_lookup_table, connection, 'EXIT_STATUS').map do |item|
        [item['description'], item['code']]
      end
    end,

    currency_code: lambda do |connection|
      call(:fetch_lookup_table, connection, 'CURRENCY_CODE').map do |item|
        [item['description'], item['code']]
      end
    end
  },

  actions: {

    general_search: {
      description: 'Retrieve a list of entities based on a general search.',
      input_fields: ->() {
        [
          { name: 'term', label: 'Search Term', optional: true }
        ]
      },

      execute: ->(connection, input) {
        params = input.map { |key, value| "#{key}=#{value}" }.join("&")
        get("https://api-v2.pitchbook.com/search?#{params}")
      },

      output_fields: ->(object_definitions) {
        [{ name: "entities", type: :array, of: :object, properties: object_definitions['entity'] }]
      }
    },

    shared_search: {
      description: 'Retrieve entities from a shared search.',
      input_fields: ->() {
        [
          { name: 'entityType', label: 'Entity Type', optional: false, hint: 'Specify the type of entity.' },
          { name: 'searchID', label: 'Search ID', optional: false, hint: 'Pass a search ID found in the generated URL of a PitchBook Shared Search.' },
          { name: 'hash', label: 'Hash', optional: false, hint: 'Hash value for shared search.' },
          { name: 'page', label: 'Page', optional: true, hint: 'Set this parameter to increment the page.' },
          { name: 'perPage', label: 'Per Page', optional: true, hint: 'How many returned results show on page.' }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/#{input['entityType']}/search")
          .params(searchId: input['searchID'], hash: input['hash'], page: input['page'], perPage: input['perPage'])
      },

      output_fields: ->(object_definitions) {
        [{ name: "entities", type: :array, of: :object, properties: object_definitions['entity'] }]
      }
    },

    entity_people: {
      description: 'Retrieve people associated with an entity.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Entity ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/entities/#{input['pbId']}/people")
      },

      output_fields: ->(object_definitions) {
        [{ name: "people", type: :array, of: :object, properties: object_definitions['person'] }]
      }
    },

    entity_locations: {
      description: 'Retrieve locations associated with an entity.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Entity ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/entities/#{input['pbId']}/locations")
      },

      output_fields: ->(object_definitions) {
        [{ name: "locations", type: :array, of: :object, properties: object_definitions['location'] }]
      }
    },

    entity_affiliates: {
      description: 'Retrieve affiliates of an entity.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Entity ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/entities/#{input['pbId']}/affiliates")
      },

      output_fields: ->(object_definitions) {
        [{ name: "affiliates", type: :array, of: :object, properties: object_definitions['affiliate'] }]
      }
    },

    entity_news: {
      description: 'Retrieve news articles related to an entity.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Entity ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/entities/#{input['pbId']}/news")
      },

      output_fields: ->(object_definitions) {
        [{ name: "news", type: :array, of: :object, properties: object_definitions['news_article'] }]
      }
    },

    general_updates: {
      description: 'Retrieve general updates for an entity.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Entity ID', optional: false },
          { name: 'trailingRange', label: 'Trailing Range', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/entities/#{input['pbId']}/updates")
          .params(trailingRange: input['trailingRange'])
      },

      output_fields: ->(object_definitions) {
        [{ name: "updates", type: :array, of: :object, properties: object_definitions['update'] }]
      }
    },
    
    company_search: {
      description: 'Retrieve companies matching the specified criteria.',
      input_fields: ->() {
        [
          { name: 'term', label: 'Search Term', optional: true }
        ]
      },

      execute: ->(connection, input) {
        params = input.map { |key, value| "#{key}=#{value}" }.join("&")
        get("https://api-v2.pitchbook.com/companies/search?#{params}")
      },

      output_fields: ->(object_definitions) {
        object_definitions['company']
      }
    },

    company_bio: {
      description: 'Retrieve the bio of the specific company.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Company ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/companies/#{input['pbId']}/bio")
      },

      output_fields: ->(object_definitions) {
        object_definitions['company']
      }
    },

    company_industries: {
      description: 'Retrieve the industries related to the specified company.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Company ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/companies/#{input['pbId']}/industries")
      },

      output_fields: ->(object_definitions) {
        object_definitions['industry']
      }
    },

    company_active_investors: {
      description: 'Retrieve active investors of the specific company.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Company ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/companies/#{input['pbId']}/active-investors")
      },

      output_fields: ->(object_definitions) {
        [{ name: "investors", type: :array, of: :object, properties: object_definitions['investor'] }]
      }
    },

    company_all_investors: {
      description: 'Retrieve all investors of the specific company.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Company ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/companies/#{input['pbId']}/all-investors")
      },

      output_fields: ->(object_definitions) {
        [{ name: "investors", type: :array, of: :object, properties: object_definitions['investor'] }]
      }
    },

    company_general_service_providers: {
      description: 'Retrieve general service providers associated with the company.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Company ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/companies/#{input['pbId']}/general-service-providers")
      },

      output_fields: ->(object_definitions) {
        [{ name: "service_providers", type: :array, of: :object, properties: object_definitions['service_provider'] }]
      }
    },

    company_deal_service_providers: {
      description: 'Retrieve service providers associated with deals of the specific company.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Company ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/companies/#{input['pbId']}/deal-service-providers")
      },

      output_fields: ->(object_definitions) {
        [{ name: "service_providers", type: :array, of: :object, properties: object_definitions['service_provider'] }]
      }
    },

    company_most_recent_financing: {
      description: 'Retrieve the most recent financing data of the specific company.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Company ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/companies/#{input['pbId']}/most-recent-financing")
      },

      output_fields: ->(object_definitions) {
        object_definitions['financing']
      }
    },

    company_most_recent_debt_financing: {
      description: 'Retrieve the most recent debt financing data of the specific company.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Company ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/companies/#{input['pbId']}/most-recent-debt-financing")
      },

      output_fields: ->(object_definitions) {
        object_definitions['debt_financing']
      }
    },

    company_deals: {
      description: 'Retrieve all deals of the specific company.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Company ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/companies/#{input['pbId']}/deals")
      },

      output_fields: ->(object_definitions) {
        [{ name: "deals", type: :array, of: :object, properties: object_definitions['deal'] }]
      }
    },

    most_recent_private_company_financials: {
      description: 'Retrieve financial information of the most recent available fiscal year of the specific company.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Company ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/companies/#{input['pbId']}/most-recent-financials")
      },

      output_fields: ->(object_definitions) {
        object_definitions['financials']
      }
    },

    company_vc_exit_predictions: {
      description: 'Retrieve exit predictions for a given period, based on PitchBook machine learning.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Company ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/companies/#{input['pbId']}/vc-exit-predictions")
      },

      output_fields: ->(object_definitions) {
        object_definitions['vc_exit']
      }
    },

    company_social_analytics: {
      description: 'Retrieve social media and web signals data of the specific company.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Company ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/companies/#{input['pbId']}/social-analytics")
      },

      output_fields: ->(object_definitions) {
        object_definitions['social_analytics']
      }
    },

    company_similar_companies: {
      description: 'Retrieve the list of similar companies/competitors.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Company ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/companies/#{input['pbId']}/similar-companies")
      },

      output_fields: ->(object_definitions) {
        [{ name: "similar_companies", type: :array, of: :object, properties: object_definitions['similar_company'] }]
      }
    },

    company_profile_updates: {
      description: 'Retrieve changes to the company profile for up to the last 90 days.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Company ID', optional: false },
          { name: 'trailingRange', label: 'Trailing Range', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/companies/#{input['pbId']}/updates?trailingRange=#{input['trailingRange']}")
      },

      output_fields: ->(object_definitions) {
        object_definitions['update']
      }
    },
    
    patent_search: {
      description: 'Retrieve patents matching the specified criteria.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Company ID', optional: false },
          { name: 'status', label: 'Status', optional: true, hint: 'Values include "Active", "Pending", "Inactive". Use a comma to separate multiple.' },
          { name: 'publicationDate', label: 'Publication Date', optional: true, hint: 'Format: YYYY-MM-DD. Use ">", "<", "^" operators to specify range.' },
          { name: 'firstFilingDate', label: 'First Filing Date', optional: true, hint: 'Format: YYYY-MM-DD. Use ">", "<", "^" operators to specify range.' },
          { name: 'filingAuthorityLocation', label: 'Filing Authority Location', optional: true, hint: 'Use a comma to separate multiple values.' },
          { name: 'cpcSectionCode', label: 'CPC Section Code', optional: true, hint: 'Use a comma to separate multiple values.' },
          { name: 'cpcClassCode', label: 'CPC Class Code', optional: true, hint: 'Use a comma to separate multiple values.' },
          { name: 'page', label: 'Page', optional: true, hint: 'Default is 1.' },
          { name: 'perPage', label: 'Per Page', optional: true, hint: 'Between 1 and 250. Default is 25.' }
        ]
      },

      execute: ->(connection, input) {
        params = input.map { |key, value| "#{key}=#{value}" }.join("&")
        get("https://api-v2.pitchbook.com/companies/#{input['pbId']}/patents/search?#{params}")
      },

      output_fields: ->(object_definitions) {
        [{ name: "patents", type: :array, of: :object, properties: object_definitions['patent'] }]
      }
    },

    patent_detailed: {
      description: 'Retrieve detailed information on a specific patent.',
      input_fields: ->() {
        [
          { name: 'patentId', label: 'Patent ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/companies/patents/#{input['patentId']}")
      },

      output_fields: ->(object_definitions) {
        object_definitions['patent']
      }
    },

    patent_file_download: {
      description: 'Retrieve the exact file of a specific patent.',
      input_fields: ->() {
        [
          { name: 'patentId', label: 'Patent ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/companies/patents/#{input['patentId']}/download")
      }
    },
    
    deal_search: {
      description: 'Retrieve deals matching the specified criteria.',
      input_fields: ->() {
        [
          { name: 'term', label: 'Search Term', optional: true }
        ]
      },

      execute: ->(connection, input) {
        params = input.map { |key, value| "#{key}=#{value}" }.join("&")
        get("https://api-v2.pitchbook.com/deals/search?#{params}")
      },

      output_fields: ->(object_definitions) {
        object_definitions['deal']
      }
    },

    deal_bio: {
      description: 'Retrieve the bio of the specific deal.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Deal ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/deals/#{input['pbId']}")
      },

      output_fields: ->(object_definitions) {
        object_definitions['deal']
      }
    },

    deal_detailed: {
      description: 'Retrieve detailed information on a specific deal.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Deal ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/deals/#{input['pbId']}/detailed")
      },

      output_fields: ->(object_definitions) {
        object_definitions['deal']
      }
    },

    deal_investors_exiters: {
      description: 'Retrieve investors and exiters from a specific deal.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Deal ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/deals/#{input['pbId']}/investors-exiters")
      },

      output_fields: ->(object_definitions) {
        [{ name: "investors", type: :array, of: :object, properties: object_definitions['investor'] }]
      }
    },

    deal_service_providers: {
      description: 'Retrieve service providers hired within the specific deal.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Deal ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/deals/#{input['pbId']}/service-providers")
      },

      output_fields: ->(object_definitions) {
        [{ name: "service_providers", type: :array, of: :object, properties: object_definitions['service_provider'] }]
      }
    },

    deal_valuation: {
      description: 'Retrieve the company’s valuation prior and after the specific deal.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Deal ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/deals/#{input['pbId']}/valuation")
      },

      output_fields: ->(object_definitions) {
        object_definitions['valuation']
      }
    },

    deal_stock_info: {
      description: 'Retrieve key data about stock within the specific deal.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Deal ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/deals/#{input['pbId']}/stock-info")
      },

      output_fields: ->(object_definitions) {
        object_definitions['stock']
      }
    },

    deal_cap_table_history: {
      description: 'Retrieve cap table history within the specific deal.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Deal ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/deals/#{input['pbId']}/cap-table-history")
      },

      output_fields: ->(object_definitions) {
        [{ name: "cap_table_history", type: :array, of: :object, properties: object_definitions['cap_table'] }]
      }
    },

    deal_tranche_information: {
      description: 'Retrieve tranche information for the specific deal.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Deal ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/deals/#{input['pbId']}/tranche")
      },

      output_fields: ->(object_definitions) {
        [{ name: "tranches", type: :array, of: :object, properties: object_definitions['tranche'] }]
      }
    },

    deal_debt_lenders: {
      description: 'Retrieve debt and lender data within the specific deal.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Deal ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/deals/#{input['pbId']}/debt-lenders")
      },

      output_fields: ->(object_definitions) {
        [{ name: "debts", type: :array, of: :object, properties: object_definitions['debt'] }]
      }
    },

    deal_multiples: {
      description: 'Retrieve key financial multiple values of the specific deal.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Deal ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/deals/#{input['pbId']}/multiples")
      },

      output_fields: ->(object_definitions) {
        object_definitions['multiple']
      }
    },

    deal_updates: {
      description: 'Retrieve changes to the deal profile for up to the last 90 days.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Deal ID', optional: false },
          { name: 'trailingRange', label: 'Trailing Range', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/deals/#{input['pbId']}/updates?trailingRange=#{input['trailingRange']}")
      },

      output_fields: ->(object_definitions) {
        object_definitions['update']
      }
    },
    
    investor_search: {
      description: 'Retrieve investors matching the specified criteria.',
      input_fields: ->() {
        [
          { name: 'term', label: 'Search Term', optional: true }
        ]
      },

      execute: ->(connection, input) {
        params = input.map { |key, value| "#{key}=#{value}" }.join("&")
        get("https://api-v2.pitchbook.com/investors/search?#{params}")
      },

      output_fields: ->(object_definitions) {
        object_definitions['investor']
      }
    },

    investor_bio: {
      description: 'Retrieve the bio of the specific investor.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Investor ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/investors/#{input['pbId']}/bio")
      },

      output_fields: ->(object_definitions) {
        object_definitions['investor']
      }
    },

    active_investments: {
      description: 'Retrieve active investments of the specific investor.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Investor ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/investors/#{input['pbId']}/active-investments")
      },

      output_fields: ->(object_definitions) {
        [{ name: "investments", type: :array, of: :object, properties: object_definitions['investment'] }]
      }
    },

    all_investments: {
      description: 'Retrieve all investments of the specific investor.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Investor ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/investors/#{input['pbId']}/all-investments")
      },

      output_fields: ->(object_definitions) {
        [{ name: "investments", type: :array, of: :object, properties: object_definitions['investment'] }]
      }
    },

    investor_preferences: {
      description: 'Retrieve investment preferences of the specific investor.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Investor ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/investors/#{input['pbId']}/investment-preferences")
      },

      output_fields: ->(object_definitions) {
        object_definitions['preference']
      }
    },

    investor_funds: {
      description: 'Retrieve funds of the specific investor.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Investor ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/investors/#{input['pbId']}/funds")
      },

      output_fields: ->(object_definitions) {
        [{ name: "funds", type: :array, of: :object, properties: object_definitions['fund'] }]
      }
    },

    investor_last_closed_fund: {
      description: 'Retrieve the last closed fund of the specific investor.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Investor ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/investors/#{input['pbId']}/last-closed-fund")
      },

      output_fields: ->(object_definitions) {
        object_definitions['fund']
      }
    },

    investor_general_service_providers: {
      description: 'Retrieve general service providers hired by the specific investor.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Investor ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/investors/#{input['pbId']}/general-service-providers")
      },

      output_fields: ->(object_definitions) {
        [{ name: "service_providers", type: :array, of: :object, properties: object_definitions['service_provider'] }]
      }
    },

    investor_deal_service_providers: {
      description: 'Retrieve deal service providers hired by the specific investor.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Investor ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/investors/#{input['pbId']}/deal-service-providers")
      },

      output_fields: ->(object_definitions) {
        [{ name: "service_providers", type: :array, of: :object, properties: object_definitions['service_provider'] }]
      }
    },

    investor_board_seats: {
      description: 'Retrieve board seats of the specific investor.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Investor ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/investors/#{input['pbId']}/board-seats")
      },

      output_fields: ->(object_definitions) {
        [{ name: "board_seats", type: :array, of: :object, properties: object_definitions['board_seat'] }]
      }
    },

    investor_profile_updates: {
      description: 'Retrieve changes to the investor profile.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Investor ID', optional: false },
          { name: 'trailingRange', label: 'Trailing Range', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/investors/#{input['pbId']}/profile-updates?trailingRange=#{input['trailingRange']}")
      },

      output_fields: ->(object_definitions) {
        object_definitions['update']
      }
    },
    
    people_search: {
      description: 'Retrieve people matching the specified criteria.',
      input_fields: ->() {
        [
          { name: 'term', label: 'Search Term', optional: true }
        ]
      },

      execute: ->(connection, input) {
        params = input.map { |key, value| "#{key}=#{value}" }.join("&")
        get("https://api-v2.pitchbook.com/people/search?#{params}")
      },

      output_fields: ->(object_definitions) {
        [{ name: "people", type: :array, of: :object, properties: object_definitions['person'] }]
      }
    },

    people_bio: {
      description: 'Retrieve the bio of the specific person.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Person ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/people/#{input['pbId']}/bio")
      },

      output_fields: ->(object_definitions) {
        object_definitions['person']
      }
    },

    people_contact: {
      description: 'Retrieve contact information of the specific person.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Person ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/people/#{input['pbId']}/contact")
      },

      output_fields: ->(object_definitions) {
        object_definitions['contact']
      }
    },

    people_education_work: {
      description: 'Retrieve education and work information of the specific person.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Person ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/people/#{input['pbId']}/education-work")
      },

      output_fields: ->(object_definitions) {
        [{ name: "education_work", type: :array, of: :object, properties: object_definitions['education_work'] }]
      }
    },

    people_profile_updates: {
      description: 'Retrieve changes to the person profile.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Person ID', optional: false },
          { name: 'trailingRange', label: 'Trailing Range', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/people/#{input['pbId']}/profile-updates?trailingRange=#{input['trailingRange']}")
      },

      output_fields: ->(object_definitions) {
        object_definitions['update']
      }
    },
    
    fund_search: {
      description: 'Retrieve funds matching the specified criteria.',
      input_fields: ->() {
        [
          { name: 'term', label: 'Search Term', optional: true }
        ]
      },

      execute: ->(connection, input) {
        params = input.map { |key, value| "#{key}=#{value}" }.join("&")
        get("https://api-v2.pitchbook.com/funds/search?#{params}")
      },

      output_fields: ->(object_definitions) {
        [{ name: "funds", type: :array, of: :object, properties: object_definitions['fund'] }]
      }
    },

    fund_bio: {
      description: 'Retrieve the bio of the specific fund.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Fund ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/funds/#{input['pbId']}/bio")
      },

      output_fields: ->(object_definitions) {
        object_definitions['fund']
      }
    },

    fund_benchmark: {
      description: 'Retrieve the benchmark of the specific fund.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Fund ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/funds/#{input['pbId']}/benchmark")
      },

      output_fields: ->(object_definitions) {
        object_definitions['benchmark']
      }
    },

    fund_active_investments: {
      description: 'Retrieve active investments of the specific fund.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Fund ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/funds/#{input['pbId']}/active-investments")
      },

      output_fields: ->(object_definitions) {
        [{ name: "investments", type: :array, of: :object, properties: object_definitions['investment'] }]
      }
    },

    fund_investments: {
      description: 'Retrieve investments of the specific fund.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Fund ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/funds/#{input['pbId']}/investments")
      },

      output_fields: ->(object_definitions) {
        [{ name: "investments", type: :array, of: :object, properties: object_definitions['investment'] }]
      }
    },

    fund_cash_flows: {
      description: 'Retrieve cash flows of the specific fund.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Fund ID', optional: false },
          { name: 'period', label: 'Period', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/funds/#{input['pbId']}/cashflows/#{input['period']}")
      },

      output_fields: ->(object_definitions) {
        object_definitions['cash_flow']
      }
    },

    fund_investment_preferences: {
      description: 'Retrieve key investment preferences of the specific fund.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Fund ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/funds/#{input['pbId']}/investment-preferences")
      },

      output_fields: ->(object_definitions) {
        object_definitions['preference']
      }
    },

    fund_people: {
      description: 'Retrieve people associated with the specific fund.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Fund ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/funds/#{input['pbId']}/people")
      },

      output_fields: ->(object_definitions) {
        [{ name: "people", type: :array, of: :object, properties: object_definitions['person'] }]
      }
    },

    fund_commitments: {
      description: 'Retrieve commitments of the specific fund.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Fund ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/funds/#{input['pbId']}/commitments")
      },

      output_fields: ->(object_definitions) {
        [{ name: "commitments", type: :array, of: :object, properties: object_definitions['commitment'] }]
      }
    },

    most_recent_fund_performance: {
      description: 'Retrieve the most recent performance data of the specific fund.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Fund ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/funds/#{input['pbId']}/performance")
      },

      output_fields: ->(object_definitions) {
        object_definitions['performance']
      }
    },

    fund_profile_updates: {
      description: 'Retrieve changes to the fund profile for up to the last 90 days.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Fund ID', optional: false },
          { name: 'trailingRange', label: 'Trailing Range', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/funds/#{input['pbId']}/updates?trailingRange=#{input['trailingRange']}")
      },

      output_fields: ->(object_definitions) {
        object_definitions['update']
      }
    },
    
    limited_partner_search: {
      description: 'Retrieve limited partners matching the specified criteria.',
      input_fields: ->() {
        [
          { name: 'term', label: 'Search Term', optional: true }
        ]
      },

      execute: ->(connection, input) {
        params = input.map { |key, value| "#{key}=#{value}" }.join("&")
        get("https://api-v2.pitchbook.com/limited-partners/search?#{params}")
      },

      output_fields: ->(object_definitions) {
        object_definitions['limited_partner']
      }
    },

    limited_partner_bio: {
      description: 'Retrieve the bio of the specific limited partner.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Limited Partner ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/limited-partners/#{input['pbId']}/bio")
      },

      output_fields: ->(object_definitions) {
        object_definitions['limited_partner']
      }
    },

    limited_partner_service_providers: {
      description: 'Retrieve service providers of the specific limited partner.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Limited Partner ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/limited-partners/#{input['pbId']}/service-providers")
      },

      output_fields: ->(object_definitions) {
        [{ name: "service_providers", type: :array, of: :object, properties: object_definitions['service_provider'] }]
      }
    },

    limited_partner_commitment_preferences: {
      description: 'Retrieve commitment preferences of the specific limited partner.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Limited Partner ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/limited-partners/#{input['pbId']}/commitment-preferences")
      },

      output_fields: ->(object_definitions) {
        object_definitions['preference']
      }
    },

    limited_partner_actual_allocations: {
      description: 'Retrieve actual allocations of the specific limited partner.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Limited Partner ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/limited-partners/#{input['pbId']}/actual-allocations")
      },

      output_fields: ->(object_definitions) {
        object_definitions['allocation']
      }
    },

    limited_partner_target_allocations: {
      description: 'Retrieve target allocations of the specific limited partner.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Limited Partner ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/limited-partners/#{input['pbId']}/target-allocations")
      },

      output_fields: ->(object_definitions) {
        object_definitions['allocation']
      }
    },

    limited_partner_commitments_detailed: {
      description: 'Retrieve detailed commitments of the specific limited partner.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Limited Partner ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/limited-partners/#{input['pbId']}/commitments-detailed")
      },

      output_fields: ->(object_definitions) {
        [{ name: "commitments", type: :array, of: :object, properties: object_definitions['commitment_detailed'] }]
      }
    },

    limited_partner_commitment_aggregates: {
      description: 'Retrieve commitment aggregates of the specific limited partner.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Limited Partner ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/limited-partners/#{input['pbId']}/commitments-aggregates")
      },

      output_fields: ->(object_definitions) {
        object_definitions['commitment_aggregate']
      }
    },

    limited_partner_profile_updates: {
      description: 'Retrieve profile updates of the specific limited partner.',
      input_fields: ->() {
        [
          { name: 'pbId', label: 'Limited Partner ID', optional: false },
          { name: 'trailingRange', label: 'Trailing Range', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/limited-partners/#{input['pbId']}/updates?trailingRange=#{input['trailingRange']}")
      },

      output_fields: ->(object_definitions) {
        object_definitions['update']
      }
    },
    
    credit_news_search: {
      description: 'Retrieve credit news articles matching the specified criteria.',
      input_fields: ->() {
        [
          { name: 'term', label: 'Search Term', optional: true }
        ]
      },

      execute: ->(connection, input) {
        params = input.map { |key, value| "#{key}=#{value}" }.join("&")
        get("https://api-v2.pitchbook.com/credit-analysis/credit-news/search?#{params}")
      },

      output_fields: ->(object_definitions) {
        [{ name: "news_articles", type: :array, of: :object, properties: object_definitions['news_article'] }]
      }
    },

    most_recent_credit_news: {
      description: 'Retrieve the most recent credit news articles.',
      input_fields: ->() {
        []
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/credit-analysis/credit-news/most-recent")
      },

      output_fields: ->(object_definitions) {
        [{ name: "news_articles", type: :array, of: :object, properties: object_definitions['news_article'] }]
      }
    },

    credit_news: {
      description: 'Retrieve details of a specific credit news article.',
      input_fields: ->() {
        [
          { name: 'articleid', label: 'Article ID', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/credit-analysis/credit-news/#{input['articleid']}")
      },

      output_fields: ->(object_definitions) {
        object_definitions['news_article']
      }
    },

    bulk_credit_news: {
      description: 'Retrieve multiple credit news articles within a single API call.',
      input_fields: ->() {
        [
          { name: 'items', type: :array, of: :object, properties: [
            { name: 'articleid', label: 'Article ID', optional: false }
          ], optional: false }
        ]
      },

      execute: ->(connection, input) {
        post("https://api-v2.pitchbook.com/credit-analysis/credit-news", input)
      },

      output_fields: ->(object_definitions) {
        object_definitions['news_article']
      }
    },

    credit_news_attachment: {
      description: 'Retrieve an exact attachment file for a specific article.',
      input_fields: ->() {
        [
          { name: 'articleid', label: 'Article ID', optional: false },
          { name: 'name', label: 'Attachment Name', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/credit-analysis/credit-news/#{input['articleid']}/attachment?name=#{input['name']}")
      }
    },
    
    contracts_history: {
      description: 'Retrieve the contracts history of the account.',
      input_fields: ->() {
        []
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/contracts/history")
      },

      output_fields: ->(object_definitions) {
        [{ name: "contracts", type: :array, of: :object, properties: object_definitions['contract'] }]
      }
    },

    credit_history: {
      description: 'Retrieve credit usage within the specific time frame (for up to the last 90 days).',
      input_fields: ->() {
        [
          { name: 'sinceDate', label: 'Since Date', type: :date, optional: true, hint: 'Extract information about the entity updates after this date.' },
          { name: 'trailingRange', label: 'Trailing Range', type: :integer, optional: true, hint: 'Extract information about the entity updates during the last N days.' }
        ]
      },

      execute: ->(connection, input) {
        params = input.map { |key, value| "#{key}=#{value}" }.join("&")
        get("https://api-v2.pitchbook.com/credits/history?#{params}")
      },

      output_fields: ->(object_definitions) {
        object_definitions['credit']
      }
    },

    usage_report: {
      description: 'Retrieve the usage report of the account.',
      input_fields: ->() {
        []
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/usage/report")
      },

      output_fields: ->(object_definitions) {
        object_definitions['usage']
      }
    },

    cost_of_calls: {
      description: 'Retrieve the cost of calls for the account.',
      input_fields: ->() {
        []
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/cost-of-calls")
      },

      output_fields: ->(object_definitions) {
        object_definitions['cost']
      }
    },

    limits: {
      description: 'Retrieve limit values set on the account level and remaining limits for the current date.',
      input_fields: ->() {
        []
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/limits")
      },

      output_fields: ->(object_definitions) {
        object_definitions['limit']
      }
    },
    
    sandbox_entities: {
      description: 'Retrieve the list of entities available to test with a sandbox API key.',
      input_fields: ->() {
        [
          { name: 'entityType', label: 'Entity Type', optional: false,
            hint: 'Specify the type of entity to retrieve (e.g., COMPANIES, INVESTORS)' }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/sandbox-entities")
          .params(entityType: input['entityType'])
      },

      output_fields: ->(object_definitions) {
        [{ name: "entities", type: :array, of: :object, properties: object_definitions['entity'] }]
      }
    },

    lookup_table_structure: {
      description: 'Retrieve the structure of lookup tables.',
      input_fields: ->() {
        [
          { name: 'tableName', label: 'Table Name', optional: false,
            hint: 'Specify the lookup table name to retrieve its structure.' }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/lookup-tables/#{input['tableName']}/structure")
      },

      output_fields: ->(object_definitions) {
        object_definitions['lookup_table_structure']
      }
    },

    lookup_tables: {
      description: 'Retrieve the data of lookup tables.',
      input_fields: ->() {
        [
          { name: 'tableName', label: 'Table Name', optional: false,
            hint: 'Specify the lookup table name to retrieve its data.' }
        ]
      },

      execute: ->(connection, input) {
        get("https://api-v2.pitchbook.com/lookup-tables/#{input['tableName']}")
      },

      output_fields: ->(object_definitions) {
        object_definitions['lookup_table_data']
      }
    }
    
  },
  
  object_definitions: {

    entity: {
      fields: ->() {
        [
          { name: 'pbId', type: :string },
          { name: 'name', type: :string },
          { name: 'type', type: :string },
          { name: 'status', type: :string }
        ]
      }
    },

    person: {
      fields: ->() {
        [
          { name: 'personId', type: :string },
          { name: 'firstName', type: :string },
          { name: 'lastName', type: :string },
          { name: 'jobTitle', type: :string },
          { name: 'companyName', type: :string },
          { name: 'location', type: :string },
          { name: 'email', type: :string },
          { name: 'phoneNumber', type: :string }
        ]
      }
    },

    location: {
      fields: ->() {
        [
          { name: 'locationId', type: :string },
          { name: 'address', type: :string },
          { name: 'city', type: :string },
          { name: 'state', type: :string },
          { name: 'country', type: :string },
          { name: 'postalCode', type: :string }
        ]
      }
    },

    affiliate: {
      fields: ->() {
        [
          { name: 'affiliateId', type: :string },
          { name: 'name', type: :string },
          { name: 'type', type: :string },
          { name: 'status', type: :string }
        ]
      }
    },

    news_article: {
      fields: ->() {
        [
          { name: 'articleId', type: :string },
          { name: 'title', type: :string },
          { name: 'content', type: :string },
          { name: 'publishedDate', type: :date },
          { name: 'author', type: :string },
          { name: 'source', type: :string },
          { name: 'attachments', type: :array, of: :object, properties: [
            { name: 'attachmentId', type: :string },
            { name: 'filename', type: :string },
            { name: 'fileType', type: :string }
          ] }
        ]
      }
    },

    update: {
      fields: ->() {
        [
          { name: 'updateId', type: :string },
          { name: 'updateType', type: :string },
          { name: 'updateDate', type: :date },
          { name: 'updateDetail', type: :string }
        ]
      }
    },
    
    company: {
      fields: ->() {
        [
          { name: 'pbId', type: :string },
          { name: 'company_name', type: :string },
          { name: 'status', type: :string },
          { name: 'founded_year', type: :integer },
          { name: 'headquarters_location', type: :string },
          { name: 'website', type: :string },
          { name: 'description', type: :string }
        ]
      }
    },

    industry: {
      fields: ->() {
        [
          { name: 'industry_name', type: :string },
          { name: 'industry_code', type: :string }
        ]
      }
    },

    investor: {
      fields: ->() {
        [
          { name: 'investorId', type: :string },
          { name: 'investorName', type: :string },
          { name: 'investorType', type: :string },
          { name: 'location', type: :string },
          { name: 'website', type: :string },
          { name: 'amount_invested', type: :integer }
        ]
      }
    },

    service_provider: {
      fields: ->() {
        [
          { name: 'serviceProviderId', type: :string },
          { name: 'serviceProviderName', type: :string },
          { name: 'serviceProviderType', type: :string }
        ]
      }
    },

    financing: {
      fields: ->() {
        [
          { name: 'financing_date', type: :date },
          { name: 'financing_amount', type: :integer },
          { name: 'currency', type: :string },
          { name: 'financing_type', type: :string }
        ]
      }
    },

    debt_financing: {
      fields: ->() {
        [
          { name: 'debt_financing_date', type: :date },
          { name: 'debt_amount', type: :integer },
          { name: 'currency', type: :string },
          { name: 'lenders', type: :string }
        ]
      }
    },

    deal: {
      fields: ->() {
        [
          { name: 'dealId', type: :string },
          { name: 'dealName', type: :string },
          { name: 'dealType', type: :string },
          { name: 'status', type: :string },
          { name: 'dealDate', type: :date }
        ]
      }
    },

    financials: {
      fields: ->() {
        [
          { name: 'fiscal_year', type: :integer },
          { name: 'revenue', type: :integer },
          { name: 'net_income', type: :integer },
          { name: 'total_assets', type: :integer },
          { name: 'total_liabilities', type: :integer }
        ]
      }
    },

    vc_exit: {
      fields: ->() {
        [
          { name: 'exit_probability', type: :integer },
          { name: 'predicted_exit_year', type: :integer },
          { name: 'exit_type', type: :string }
        ]
      }
    },

    social_analytics: {
      fields: ->() {
        [
          { name: 'web_total', type: :integer },
          { name: 'web_positive', type: :integer },
          { name: 'web_negative', type: :integer },
          { name: 'social_total', type: :integer },
          { name: 'social_positive', type: :integer },
          { name: 'social_negative', type: :integer }
        ]
      }
    },

    similar_company: {
      fields: ->() {
        [
          { name: 'companyId', type: :string },
          { name: 'companyName', type: :string },
          { name: 'industry', type: :string },
          { name: 'location', type: :string }
        ]
      }
    },

    patent: {
      fields: lambda do
        [
          { name: 'patentId', type: :string },
          { name: 'patentTitle', type: :string },
          { name: 'status', type: :string },
          { name: 'publicationDate', type: :date },
          { name: 'firstFilingDate', type: :date },
          { name: 'expirationDate', type: :date },
          { name: 'filingAuthorityLocation', type: :string },
          { name: 'cpcSection', type: :array, of: :object, properties: [
            { name: 'code', type: :string },
            { name: 'description', type: :string }
          ] },
          { name: 'cpcClass', type: :array, of: :object, properties: [
            { name: 'code', type: :string },
            { name: 'description', type: :string }
          ] },
          { name: 'cpcSubclass', type: :array, of: :object, properties: [
            { name: 'code', type: :string },
            { name: 'description', type: :string }
          ] }
        ]
      end
    },

    valuation: {
      fields: lambda do
        [
          { name: 'preMoney', type: :integer },
          { name: 'postMoney', type: :integer },
          { name: 'dealSize', type: :integer }
        ]
      end
    },

    stock: {
      fields: lambda do
        [
          { name: 'dealId', type: :string },
          { name: 'companyName', type: :string },
          { name: 'series', type: :string },
          { name: 'pricePerShare', type: :object, properties: [
            { name: 'amount', type: :integer },
            { name: 'currency', type: :string },
            { name: 'nativeAmount', type: :integer },
            { name: 'nativeCurrency', type: :string }
          ]},
          { name: 'stockType', type: :string },
          { name: 'numberOfSharesAcquired', type: :integer }
        ]
      end
    },

    cap_table: {
      fields: lambda do
        [
          { name: 'dealId', type: :string },
          { name: 'capTableHistory', type: :string },
          { name: 'numberOfShares', type: :integer },
          { name: 'sharePrice', type: :integer },
          { name: 'valuation', type: :integer }
        ]
      end
    },

    tranche: {
      fields: lambda do
        [
          { name: 'trancheId', type: :string },
          { name: 'trancheAmount', type: :integer },
          { name: 'trancheDate', type: :date },
          { name: 'trancheType', type: :string }
        ]
      end
    },

    debt: {
      fields: lambda do
        [
          { name: 'debtId', type: :string },
          { name: 'debtAmount', type: :integer },
          { name: 'debtType', type: :string },
          { name: 'debtProvider', type: :string }
        ]
      end
    },

    multiple: {
      fields: lambda do
        [
          { name: 'dealId', type: :string },
          { name: 'dealNumber', type: :integer },
          { name: 'valuationToRevenue', type: :integer },
          { name: 'valuationToCashFlow', type: :integer },
          { name: 'valuationToEBIT', type: :integer },
          { name: 'valuationToEBITDA', type: :integer },
          { name: 'valuationToNetIncome', type: :integer }
        ]
      end
    },

    investment: {
      fields: lambda do
        [
          { name: 'investmentId', type: :string },
          { name: 'investmentType', type: :string },
          { name: 'investmentDate', type: :date },
          { name: 'amount', type: :integer },
          { name: 'currency', type: :string },
          { name: 'companyId', type: :string },
          { name: 'companyName', type: :string }
        ]
      end
    },

    preference: {
      fields: lambda do
        [
          { name: 'sectorPreferences', type: :array, of: :string },
          { name: 'geographicPreferences', type: :array, of: :string },
          { name: 'investmentTypePreferences', type: :array, of: :string },
          { name: 'preferredInvestmentStage', type: :array, of: :string },
          { name: 'preferredInvestmentSize', type: :array, of: :string }
        ]
      end
    },

    fund: {
      fields: lambda do
        [
          { name: 'fundId', type: :string },
          { name: 'fundName', type: :string },
          { name: 'fundSize', type: :integer },
          { name: 'currency', type: :string },
          { name: 'fundType', type: :string },
          { name: 'closeDate', type: :date }
        ]
      end
    },

    board_seat: {
      fields: lambda do
        [
          { name: 'companyId', type: :string },
          { name: 'companyName', type: :string },
          { name: 'boardSeatId', type: :string },
          { name: 'boardSeatTitle', type: :string },
          { name: 'boardSeatStartDate', type: :date },
          { name: 'boardSeatEndDate', type: :date }
        ]
      end
    },

    contact: {
      fields: ->() {
        [
          { name: 'email', type: :string },
          { name: 'phoneNumber', type: :string }
        ]
      }
    },

    education_work: {
      fields: ->() {
        [
          { name: 'institutionName', type: :string },
          { name: 'degree', type: :string },
          { name: 'fieldOfStudy', type: :string },
          { name: 'graduationYear', type: :integer },
          { name: 'companyName', type: :string },
          { name: 'jobTitle', type: :string },
          { name: 'startDate', type: :date },
          { name: 'endDate', type: :date }
        ]
      }
    },

    benchmark: {
      fields: ->() {
        [
          { name: 'benchmarks', type: :array, of: :object, properties: [
            { name: 'benchmarkName', type: :string },
            { name: 'benchmarkValue', type: :integer }
          ] }
        ]
      }
    },

    cash_flow: {
      fields: ->() {
        [
          { name: 'period', type: :string },
          { name: 'contributed', type: :integer },
          { name: 'distributed', type: :integer }
        ]
      }
    },

    commitment: {
      fields: ->() {
        [
          { name: 'commitmentId', type: :string },
          { name: 'committedAmount', type: :integer },
          { name: 'commitmentType', type: :string },
          { name: 'commitmentDate', type: :date },
          { name: 'investorId', type: :string },
          { name: 'investorName', type: :string }
        ]
      }
    },

    performance: {
      fields: ->() {
        [
          { name: 'fundId', type: :string },
          { name: 'fundSize', type: :integer },
          { name: 'currency', type: :string },
          { name: 'performanceDate', type: :date },
          { name: 'netIRR', type: :integer },
          { name: 'grossIRR', type: :integer },
          { name: 'multiple', type: :integer }
        ]
      }
    },

    limited_partner: {
      fields: ->() {
        [
          { name: 'limitedPartnerId', type: :string },
          { name: 'limitedPartnerName', type: :string },
          { name: 'limitedPartnerType', type: :string },
          { name: 'location', type: :string },
          { name: 'website', type: :string },
          { name: 'assetsUnderManagement', type: :integer },
          { name: 'numberOfCommitments', type: :integer }
        ]
      }
    },

    allocation: {
      fields: ->() {
        [
          { name: 'date', type: :date },
          { name: 'allocationType', type: :string },
          { name: 'allocatedAmount', type: :integer },
          { name: 'currency', type: :string }
        ]
      }
    },

    commitment_detailed: {
      fields: ->() {
        [
          { name: 'limitedPartnerId', type: :string },
          { name: 'committedFundId', type: :string },
          { name: 'committedFundName', type: :string },
          { name: 'commitmentDate', type: :date },
          { name: 'commitmentSize', type: :integer },
          { name: 'commitmentStatus', type: :string },
          { name: 'commitmentType', type: :string }
        ]
      }
    },

    commitment_aggregate: {
      fields: ->() {
        [
          { name: 'totalActiveCommitments', type: :integer },
          { name: 'totalCommitments', type: :integer }
        ]
      }
    },

    news_article: {
      fields: ->() {
        [
          { name: 'articleid', type: :string },
          { name: 'title', type: :string },
          { name: 'content', type: :string },
          { name: 'publishedDate', type: :date },
          { name: 'author', type: :string },
          { name: 'source', type: :string },
          { name: 'attachments', type: :array, of: :object, properties: [
            { name: 'attachmentId', type: :string },
            { name: 'filename', type: :string },
            { name: 'fileType', type: :string }
          ] }
        ]
      }
    },
    
    contract: {
      fields: ->() {
        [
          { name: 'contractId', type: :string },
          { name: 'contractName', type: :string },
          { name: 'contractType', type: :string },
          { name: 'startDate', type: :date },
          { name: 'endDate', type: :date },
          { name: 'amount', type: :integer },
          { name: 'currency', type: :string }
        ]
      }
    },

    credit: {
      fields: ->() {
        [
          { name: 'creditId', type: :string },
          { name: 'usageType', type: :string },
          { name: 'amount', type: :integer },
          { name: 'date', type: :date }
        ]
      }
    },

    usage: {
      fields: ->() {
        [
          { name: 'usageType', type: :string },
          { name: 'amount', type: :integer },
          { name: 'currency', type: :string },
          { name: 'date', type: :date }
        ]
      }
    },

    cost: {
      fields: ->() {
        [
          { name: 'callType', type: :string },
          { name: 'cost', type: :integer },
          { name: 'currency', type: :string }
        ]
      }
    },

    limit: {
      fields: ->() {
        [
          { name: 'limitType', type: :string },
          { name: 'maxLimit', type: :integer },
          { name: 'remainingLimit', type: :integer },
          { name: 'date', type: :date }
        ]
      }
    },

    lookup_table_structure: {
      fields: ->() {
        [
          { name: 'fields', type: :array, of: :object, properties: [
            { name: 'name', type: :string },
            { name: 'type', type: :string },
            { name: 'description', type: :string }
          ] }
        ]
      }
    },

    lookup_table_data: {
      fields: ->() {
        [
          { name: 'rows', type: :array, of: :object, properties: [
            { name: 'id', type: :string },
            { name: 'value', type: :string }
          ] }
        ]
      }
    }
    
  }
}