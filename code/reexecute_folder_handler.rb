class ReexecuteFolderHandler < BaseHandler
  REEXECUTION_QUANTITY = ENV.fetch('LOCKED_FOLDER_REEXECUTION_QUANTITY', 15)
  attr_accessor :folder_id

  def handle(request)
    @folder_id = request.folder_id
    return folder unless folder.status == Folder::IN_PROGRESS

    begin
      status_info = esb.executeTransfer(folder)
      update_executed_folder(status_info)
    rescue => e
      Log.info('An error occurred when calling executeTransfer again')
      handle_error(e)
    end

    return folder
  end

  def folder
    @folder ||= Folder.find(folder_id)
  rescue ActiveRecord::RecordNotFound
    raise InternalError.new("Folder '#{folder_id}' not found")
  end

  def handle_error(error)
    code = error.methods.include?(:error_code) ? error.error_code : nil

    if resource_locked?(error.message, code) || need_retry?(error.message)
      update_locked_folder
    else
      update_failed_folder
      raise
    end
  end

  def resource_locked?(message, code)
    message.include?('LOCK-RESOURCE_BUSY') or
    code == 'folder_is_temporarily_locked'
  end

  def need_retry?(message)
    errors_for_retry = [
      /can not find the called program block/,
      /ESB server is unavailable/
    ]
    errors_for_retry.any? {|reg| reg =~ message}
  end

  def update_executed_folder(status_info)
    folder.status               = status_info.status
    folder.executed_at          = status_info.executed_at if status_info.executed_at
    folder.reexecuted_at        = Time.now
    folder.reexecution_quantity = folder.reexecution_quantity + 1
    folder.execution_locked     = false
    folder.save!
  end

  def update_locked_folder
    folder.update(
      status: Folder::IN_PROGRESS,
      execution_locked: true,
      reexecuted_at: Time.now,
      reexecution_quantity: folder.reexecution_quantity + 1
    )

    if folder.reexecution_quantity.to_s == REEXECUTION_QUANTITY
      folder.update(status: Folder::NOT_EXECUTED)
      Log.info(log_message)
    end
  end

  def log_message
    "Attention! The number of times the folder with ID = #{folder.bank_folder_id} has been re-executed has exceeded the specified value!"
  end

  def update_failed_folder
    folder.update(
      status: Folder::NOT_EXECUTED,
      execution_locked: false,
      reexecuted_at: Time.now,
      reexecution_quantity: folder.reexecution_quantity + 1
    )
  end
end
