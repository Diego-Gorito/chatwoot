require_relative 'config/environment'

begin
  account = Account.first
  Current.account = account
  Current.account_user = account.account_users.first
  Current.user = Current.account_user.user

  # Empty board
  board = Current.account.kanban_boards.new(name: "Empty Test", description: "")
  board.save!
  
  puts "EMPTY BOARD SAVED SUCCESS: #{board.id}"
rescue => e
  puts "EMPTY BOARD FAILED: #{e.class}: #{e.message}"
end

begin
  # Board with templates (array of hashes)
  params = ActionController::Parameters.new({
    steps_attributes: [
      { name: "Step 1", cancelled: false },
      { name: "Step 2", cancelled: false }
    ]
  })
  
  permitted = params.permit(steps_attributes: [:name, :cancelled])
  steps_attrs = permitted[:steps_attributes]
  
  if steps_attrs.present?
    steps_attrs = steps_attrs.map { |s| s.except(:cancelled) }
  end
  puts "ARRAY PERMITTED MAPPING SUCCESS"
rescue => e
  puts "ARRAY PERMITTED MAPPING FAILED: #{e.class}: #{e.message}"
end

begin
  # Board with templates (hash of hashes, e.g. from FormData or certain JSON parsers)
  params2 = ActionController::Parameters.new({
    steps_attributes: {
      "0" => { name: "Step 1", cancelled: false },
      "1" => { name: "Step 2", cancelled: false }
    }
  })
  
  permitted2 = params2.permit(steps_attributes: [:name, :cancelled])
  steps_attrs2 = permitted2[:steps_attributes]
  
  if steps_attrs2.present?
    steps_attrs2 = steps_attrs2.map { |s| s.except(:cancelled) }
  end
  puts "HASH PERMITTED MAPPING SUCCESS"
rescue => e
  puts "HASH PERMITTED MAPPING FAILED: #{e.class}: #{e.message}"
end
