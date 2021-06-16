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
      Log.info("При повторном вызове executeTransfer возникла ошибка")
      handle_error(e)
    end

    return folder
  end

  def folder
    @folder ||= Folder.find(folder_id)
  rescue ActiveRecord::RecordNotFound
    raise InternalError.new("Папка документов '#{folder_id}' не найдена")
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
      /невозможно найти вызываемый блок программы/,
      /ESB сервер не доступен/
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
      Log.info("ВНИМАНИЕ! Количество повторного исполнения папки с ID = #{folder.bank_folder_id} превысило указанное значение: #{REEXECUTION_QUANTITY}! Документ НЕ ИСПОЛНЕН! Статус папки в mod_finance: #{folder.status}")
    end
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
