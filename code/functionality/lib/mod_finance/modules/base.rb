module Base
  class ResponseBuilder
    def self.build_response(status, body)
      if status == :error
        return self.error(body)
      elsif status == :success
        return self.success(body)
      else
        raise StandardError.new("[ResponseBuilder] Неизвестный статус: '#{status}'")
      end
    end

    def self.success(state)
      params = state.fetch(:params)
      block_given? ? result = yield : result = {}

      result[:success] = true
      result[:mod_sender] = Application.config.module_id
      result[:request_id] = params['request_id']
      result[:request_owner] = params['request_owner']
      return result
    end

    def self.error(error: nil, params:)
      if block_given?
        result = yield
        result[:success] = false
        result[:request_id] = params['request_id']
        result[:mod_sender] = Application.config.module_id
        result[:request_owner] = params['request_owner']
      else
        result = {
            success: false,
            status: error.status,
            code: error.status,
            message: error.message,
            request_id: params['request_id'],
            error: error.to_hash,
            mod_sender: Application.config.module_id,
            request_owner: params['request_owner']
        }
      end

      return result
    end
  end
end
