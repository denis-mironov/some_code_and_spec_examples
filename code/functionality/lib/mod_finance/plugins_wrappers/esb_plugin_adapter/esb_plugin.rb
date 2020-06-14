# Необходим для установления read_timeout для определенного запроса
# Введен для увеличения timeoutа при открытии депозита
module RestClient
  def self.post(url, payload, headers={}, &block)
    standart_timeout     = ENV.fetch('ESB_PLUGIN_TIMEOUT').to_i
    open_deposit_timeout = ENV.fetch('PLUGIN_OPEN_DEPOSIT_TIMEOUT').to_i

    method = JSON.parse(payload)['method']
    read_timeout = method == 'open_deposit' ? open_deposit_timeout : standart_timeout

    Request.execute(
      :method => :post,
      :url => url,
      :payload => payload,
      :headers => headers,
      :read_timeout => read_timeout,
      &block
    )
  end
end

module Plugin
  class EsbAdapter
    PLUGIN_NAME = 'BankPlugin'
    JSON_RPC_APPLICATION_ERROR = -32099

    attr_accessor :plugin, :plugin_url

    def initialize(plugin=nil)
      set_mod_debug_proxy
      @plugin_url = ENV.fetch('PLUGIN_BASE_URL')
      @plugin = plugin || Jimson::Client.new(plugin_url)
    end

    def make_debit_card_order(params)
      remote_procedure_call Plugin::MakeDebitCardOrderResponseHandler.new do
        @plugin.make_debit_card_order(params)
      end
    end

    def remote_procedure_call(response_handler)
      begin
        response = yield
        response_handler.handle_response(response)
      rescue Jimson::Client::Error::ServerError => e
        if e.code == JSON_RPC_APPLICATION_ERROR
          response_handler.handle_error(e)
        else
          raise Plugin::PluginError.new(e.message, e)
        end
      end

      response_handler.response
    end

    def set_mod_debug_proxy
      # Временный костыль для установки прокси между finance <-> esb
      proxy_ip = ENV.fetch('MOD_DEBUG_PROXY_IP', '127.0.0.1')
      proxy_port = ENV.fetch('MOD_DEBUG_PROXY_PORT', '3456')
      if mod_debug_enabled?
        RestClient.proxy = "http://#{proxy_ip}:#{proxy_port}"
      end
    end

    def mod_debug_enabled?
      ENV.fetch('USE_MOD_DEBUG_PROXY', 'false') == 'true'
    end
  end
end
