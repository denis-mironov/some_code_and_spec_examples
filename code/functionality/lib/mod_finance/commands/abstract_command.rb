module Finance
  class AbstractCommand
    def initialize(cmd_params, plugin=nil, bsm=nil)
      @cmd_params = cmd_params
      @plugin = plugin
      @bsm = bsm
    end

    def execute
      raise NotImplementedError, 'Не реализован метод execute'
    end
  end
end
