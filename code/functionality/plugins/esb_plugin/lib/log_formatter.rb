module LogFormatter
  MAX_LOG_SYZE = ENV.fetch("GELF_MAX_LOG_SIZE").to_i

  class RequestLog
    attr_reader :request, :request_hash, :request_params

    def initialize(request)
      @request = request
      @request_hash = Marshal.load(Marshal.dump(request))
      @request_params = request_hash['params'].first
    end

    def format
      mask_parameters
      truncate_request

      request_hash
    end

    private

    def mask_parameters
      @request_hash = LogCleaner.new.clean_sensitive_data(request)
    end

    def truncate_request
      if request_hash.to_s.bytesize > MAX_LOG_SYZE
        request_hash['params'] = request_params.to_s.truncate(2000, omission: '............. (REQUEST STRING IS TOO BIG)')
      end
    end
  end

  class ResponseLog
    attr_reader :response, :response_hash, :result

    def initialize(response)
      @response = response
      @response_hash = Marshal.load(Marshal.dump(response))
      @result = response_hash['result']
    end

    def format
      if response_hash.to_s.bytesize > MAX_LOG_SYZE
        response_hash['result'] = result.to_s.truncate(2000, omission: '............. (RESPONSE STRING IS TOO BIG)')
      end

      response_hash.to_json
    end
  end
end
