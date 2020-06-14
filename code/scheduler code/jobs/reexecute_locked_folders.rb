class ReexecuteLockedFolders
  attr_reader :folder_id

  def call
    return unless reexecute_needed_locked_folders.present?

    reexecute_needed_locked_folders.each do |folder|
      @folder_id = folder.id
      ReexecuteFolderHandler.new.handle(execute_params)
    end
  end

  private

  def reexecute_needed_locked_folders
    Folder.where("status = ? AND execution_locked = ? AND reexecution_quantity < ?",
      Folder::IN_PROGRESS, true, ENV.fetch('LOCKED_FOLDER_REEXECUTION_QUANTITY', 15)
    )
  end

  def execute_params
    OpenStruct.new(folder_id: folder_id)
  end
end
