require_relative '../config/boot'

class ModFinance
  def MakeDebitCardOrder(params)
    perform params, :mod_crm, :make_debit_card_order_response do |bsm|
      cmd_params = Finance::MakeDebitCardOrderParams.new(params)
      plugin = initialize_plugin(cmd_params)
      execute Finance::MakeDebitCardOrderCommand.new(cmd_params, plugin, bsm)
    end
  end

  private

  def initialize_plugin(params)
    plugin_creator = Finance::PluginCreator.new
    plugin_creator.create(params)
  end

  def perform(params, request_owner, callback)
    owners_mapper = {
      'API'     => :mod_api,
      'API2'    => :mod_api2,
      'Payment' => :mod_payment,
      'CRM'     => :mod_crm,
      'RM'      => :mod_rm,
    }
    request_owner = owners_mapper.fetch(request_owner, request_owner)

    bsm = ModFinanceBsmWrapper.new(params, request_owner, callback)
    bsm.perform do
      yield(bsm) if block_given?
    end
  end

  def execute(cmd)
    cmd.execute
  end
end
